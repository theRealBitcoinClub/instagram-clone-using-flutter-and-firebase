import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'socket/electrum_websocket_service.dart';

class Balance {
  final BigInt _bch;
  final BigInt _token;

  const Balance({required BigInt bch, required BigInt token}) : _bch = bch, _token = token;

  /// Public getter to retrieve the BCH balance as an int.
  /// This may result in an overflow if the value is too large.
  int get bch => _bch.toInt();

  /// Public getter to retrieve the token balance as an int.
  /// This may result in an overflow if the value is too large.
  int get token => _token.toInt();

  @override
  String toString() {
    return 'Balance(BCH: $_bch, Token: $_token)';
  }
}

class MemoBitcoinBase {
  static const String cashonizeUrl = "https://cashonize.com/";
  static const String explorerUrl = "https://explorer.salemkode.com/address/";
  //TODO MAKE SURE THIS URL IS OPENED IN OWN WEBVIEW TO APPRECIATE LOGIN STATUS
  static const String memoExplorerUrlPrefix = "https://memo.cash/explore/address/";
  static const String memoExplorerUrlSuffix = "?p=utxos";
  static const String cauldronSwapTokenUrl = "https://app.cauldron.quest/swap/d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002";
  static const String tokenTicker = "PEPE";
  static const String tokenId = "d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002";

  static const mainnetServers = [
    "cashnode.bch.ninja", // Kallisti / Selene Official
    "fulcrum.jettscythe.xyz", // Jett
    "bch.imaginary.cash", // im_uname
    "bitcoincash.network", // Dagur
    "electroncash.dk", // Georg
    "blackie.c3-soft.com", // Calin
    "bch.loping.net",
    "bch.soul-dev.com",
    "bitcoincash.stackwallet.com", // Rehrar / Stack Wallet official
    "node.minisatoshi.cash", // minisatoshi
  ];
  // A static list to keep track of servers that have failed to connect.
  static final Set<String> _badServers = {};

  static const derivationPathMemoBch = "m/44'/0'/0'/0/0";
  static const derivationPathMemoSlp = "m/44'/245'/0'/0/0";
  static const derivationPathCashtoken = "m/44'/145'/0'/0/0";
  //TODO create an address that is managed in a multi_sig wallet to buy and burn tokens every week
  //TODO show the balance of that managed wallet on the top app_bar and make it increase on every action inside mahakka
  static const bchBurnerAddress = "bitcoincash:zzsyjtd4fxrxzvmqwudzsasfg6lfrse49qaemzmtj6";
  // static const bchBurnerAddress = "bitcoincash:qzsyjtd4fxrxzvmqwudzsasfg6lfrse49q6ngu4ddf";
  static const tokenBurnerDotCashAddress = "bitcoincash:r0lxr93av56s6ja253zmg6tjgwclfryeardw6v427e74uv6nfkrlc2s5qtune";

  ElectrumWebSocketService? service;
  BitcoinCashNetwork? network;
  ElectrumProvider? provider;

  MemoBitcoinBase._create() {
    network = BitcoinCashNetwork.mainnet;
  }

  static Future<MemoBitcoinBase> create() async {
    MemoBitcoinBase instance = MemoBitcoinBase._create();

    // Create a list of servers to try, excluding any from the bad servers list.
    final serversToTry = mainnetServers.where((server) => !_badServers.contains(server)).toList();

    for (final server in serversToTry) {
      try {
        final ElectrumWebSocketService service = await ElectrumWebSocketService.connect(
          "wss://$server:50004",
        ).timeout(const Duration(seconds: 3));

        instance.service = service;
        instance.provider = ElectrumProvider(service);
        print("Connected to Electrum server: $server");
        return instance;
      } catch (e) {
        print("Failed to connect to Electrum server $server. Error: $e");
        // Add the failed server to the bad servers set.
        _badServers.add(server);
      }
    }

    clearBadServers();
    // If no servers are left to try or none connected.
    throw Exception("Failed to connect to any available Electrum servers.");
  }

  // Optional: A method to clear the bad servers list, useful for a retry mechanism.
  static void clearBadServers() {
    _badServers.clear();
  }

  Future<Balance> getBalances(String address) async {
    const tokenId = MemoBitcoinBase.tokenId;
    final isLegacy = !address.startsWith('bitcoincash:');
    final hasToken = address.startsWith('bitcoincash:z');

    try {
      BitcoinCashAddress typedAddress;
      if (isLegacy) {
        typedAddress = BitcoinCashAddress.fromBaseAddress(
          P2pkhAddress.fromAddress(address: address, network: BitcoinNetwork.mainnet, type: P2pkhAddressType.p2pkh),
        );
      } else {
        typedAddress = BitcoinCashAddress(address);
      }

      final electrumUtxos = await requestElectrumUtxos(typedAddress, includeCashtokens: hasToken);

      print('Found ${electrumUtxos.length} UTXOs for the address.');

      BigInt bchBalance = BigInt.zero;
      BigInt tokenBalance = BigInt.zero;

      for (final utxo in electrumUtxos) {
        if (utxo.token != null && utxo.token!.category == tokenId) {
          // This UTXO holds our specific token
          tokenBalance += utxo.token!.amount;
        } else {
          // This UTXO holds only BCH
          bchBalance += utxo.value;
        }
      }

      return Balance(bch: bchBalance, token: tokenBalance);
    } catch (e) {
      print('An error occurred while checking balances: $e');
      return Balance(bch: BigInt.zero, token: BigInt.zero);
    }
  }

  ForkedTransactionBuilder buildTxToTransferTokens(
    int tokenAmountToSend,
    BitcoinCashAddress senderBCHp2pkhwt,
    BigInt availableSats,
    List<UtxoWithAddress> utxos,
    BitcoinBaseAddress receiverP2PKHWT,
    CashToken token,
    BigInt totalTokensAvailable,
  ) {
    var amount = BigInt.from(tokenAmountToSend);
    BigInt fee = calculateFee(3, utxos.length, withOpReturn: false, overheads: "0.000001");
    BigInt tokenFee = BtcUtils.toSatoshi("0.00000666");
    var outPuts = [
      BitcoinOutput(address: senderBCHp2pkhwt.baseAddress, value: availableSats - (tokenFee + tokenFee + fee)),
      BitcoinTokenOutput(
        utxoHash: utxos.first.utxo.txHash,
        address: receiverP2PKHWT,
        value: tokenFee,
        token: token.copyWith(amount: amount),
      ),
      BitcoinTokenOutput(
        utxoHash: utxos.first.utxo.txHash,
        address: senderBCHp2pkhwt.baseAddress,
        value: tokenFee,
        token: token.copyWith(amount: totalTokensAvailable - amount),
      ),
    ];
    return ForkedTransactionBuilder(outPuts: outPuts, fee: fee, network: network!, memo: null, utxos: utxos);
  }

  CashToken findTokenById(List<ElectrumUtxo> electrumUTXOs, String tokenId) {
    return electrumUTXOs.firstWhere((e) => e.token?.category == tokenId).token!;
  }

  BigInt calculateTotalAmountOfThatToken(List<UtxoWithAddress> utxos, String tokenId) {
    return utxos
        .where((element) => element.utxo.token?.category == tokenId)
        .fold(BigInt.zero, (previousValue, element) => previousValue + element.utxo.token!.amount);
  }

  List<UtxoWithAddress> getSpecificTokenAndGeneralUtxos(
    List<ElectrumUtxo> electrumUTXOs,
    BitcoinCashAddress senderBCHp2pkhwt,
    ECPrivate bip44Sender,
    String tokenId,
  ) {
    return transformUtxosAddAddressDetails(electrumUTXOs, senderBCHp2pkhwt, bip44Sender).where((element) {
      return element.utxo.token?.category == tokenId || element.utxo.token == null;
    }).toList();
  }

  List<UtxoWithAddress> transformUtxosAddAddressDetails(List<ElectrumUtxo> utxos, BitcoinCashAddress addr, ECPrivate pk) {
    return utxos
        .map(
          (e) => UtxoWithAddress(
            utxo: e.toUtxo(addr.type),
            ownerDetails: UtxoAddressDetails(publicKey: pk.getPublic().toHex(), address: addr.baseAddress),
          ),
        )
        .toList();
  }

  Future<List<ElectrumUtxo>> requestElectrumUtxos(BitcoinCashAddress p2pkhAddress, {bool includeCashtokens = false}) async {
    final utxos = await provider!.request(
      ElectrumRequestScriptHashListUnspent(scriptHash: p2pkhAddress.baseAddress.pubKeyHash(), includeTokens: includeCashtokens),
    );
    return utxos;
  }

  P2pkhAddress createAddressP2PKHWT(ECPrivate pk) {
    ECPublic pubKey = pk.getPublic();

    return P2pkhAddress.fromHash160(addrHash: pubKey.toAddress().addressProgram, type: P2pkhAddressType.p2pkhwt);
  }

  P2pkhAddress createAddressLegacy(ECPrivate pk) {
    ECPublic pubKey = pk.getPublic();

    return P2pkhAddress.fromHash160(addrHash: pubKey.toAddress().addressProgram, type: P2pkhAddressType.p2pkh);
  }

  static ECPrivate createBip44PrivateKey(String mnemonic, String derivationPath) {
    //TODO check that derivationPath is one of specified Enums

    List<int> seed = Bip39SeedGenerator(Mnemonic.fromString(mnemonic)).generate();

    Bip32Slip10Secp256k1 bip32 = Bip32Slip10Secp256k1.fromSeed(seed);
    Bip32Base bip44 = bip32.derivePath(derivationPath);
    return ECPrivate.fromBytes(bip44.privateKey.raw);
  }

  Future<String> broadcastTransaction(BtcTransaction tx) async {
    //TODO handle dust xceptions
    print(
      "ANALYZE DUST: " +
          await provider!.request(ElectrumRequestBroadCastTransaction(transactionRaw: tx.toHex()), timeout: const Duration(seconds: 20)),
    );
    return "success";
  }

  static String reOrderTxHash(String hexString) {
    // Step 1: Split the string into pairs
    List<String> pairs = [];
    for (int i = 0; i < hexString.length; i += 2) {
      pairs.add(hexString.substring(i, i + 2));
    }

    // Step 2: Reverse the order of the pairs
    pairs = pairs.reversed.toList();

    // Step 3: Combine them back into a single string
    String reversedHexString = pairs.join('');

    return reversedHexString;
  }

  Future<String> sendIpfs(List<Map<String, dynamic>> outputs, String mnemonic) async {
    try {
      if (outputs.isEmpty) {
        throw Exception('No outputs provided for transaction');
      }
      final privateKey = createBip44PrivateKey(mnemonic, derivationPathMemoBch);
      final senderAddress = createAddressP2PKHWT(privateKey);
      final cashAddress = BitcoinCashAddress.fromBaseAddress(senderAddress);
      final electrumUtxos = await requestElectrumUtxos(cashAddress);
      final utxosWithAddress = transformUtxosAddAddressDetails(electrumUtxos, cashAddress, privateKey);
      final totalBalance = utxosWithAddress.fold(BigInt.zero, (previousValue, element) => previousValue + element.utxo.value);
      final bitcoinOutputs = <BitcoinOutput>[];
      BigInt totalOutputAmount = BigInt.zero;

      for (final output in outputs) {
        final address = output['address'];
        final amountSat = output['amountSat'];

        bitcoinOutputs.add(BitcoinOutput(address: BitcoinCashAddress(address).baseAddress, value: amountSat));

        totalOutputAmount += amountSat;
      }

      BigInt fee = calculateFee(bitcoinOutputs.length, utxosWithAddress.length);

      if (totalBalance < totalOutputAmount + fee) {
        throw Exception('Insufficient balance. Available: $totalBalance, Required: ${totalOutputAmount + fee}');
      }

      final changeAmount = totalBalance - totalOutputAmount - fee;
      if (changeAmount > BigInt.zero) {
        bitcoinOutputs.add(BitcoinOutput(address: senderAddress, value: changeAmount));
      }

      final builder = ForkedTransactionBuilder(outPuts: bitcoinOutputs, fee: fee, network: network!, utxos: utxosWithAddress);

      final transaction = await builder.buildTransactionAsync((digest, utxo, publicKey, sighash) async {
        return privateKey.signECDSA(digest, sighash: BitcoinOpCodeConst.sighashAll | BitcoinOpCodeConst.sighashForked);
      });

      String result = await broadcastTransaction(transaction);

      if (result == "success") {
        //TODO SUCCESS CALLBACK CONFETTI
      }
      return transaction.txId();
    } catch (error) {
      print('Error in send method: $error');
      rethrow;
    }
  }

  BigInt calculateFee(int outputUtxoCount, int inputUtxoCount, {bool withOpReturn = true, String overheads = "0.00000020"}) {
    BigInt eachInput = BtcUtils.toSatoshi("0.00000148");
    BigInt eachOutput = BtcUtils.toSatoshi("0.00000034");
    BigInt overhead = BtcUtils.toSatoshi(overheads);
    BigInt fee = eachOutput * BigInt.from(outputUtxoCount); //OWN FUNDS
    if (withOpReturn) fee += BtcUtils.toSatoshi("0.00000250"); //OP_RETURN w max text
    fee += eachInput * BigInt.from(inputUtxoCount); //CONSOLIDATE ALL UTXOS
    fee += overhead;
    return fee;
  }

  BigInt toSatoshi(double bchAmount) {
    return BigInt.from((bchAmount * 100000000).round());
  }
}
