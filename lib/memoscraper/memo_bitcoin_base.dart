import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memoscraper/socket/electrum_websocket_service.dart';

class MemoBitcoinBase {

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

  static const derivationPathMemoBch = "m/44'/0'/0'/0/0";
  static const derivationPathMemoSlp = "m/44'/245'/0'/0/0";
  static const derivationPathCashtoken = "m/44'/145'/0'/0/0";
  static const tokenBurnerDotCashAddress = "bitcoincash:r0lxr93av56s6ja253zmg6tjgwclfryeardw6v427e74uv6nfkrlc2s5qtune";

  ForkedTransactionBuilder buildTxToTransferTokens(int tokenAmountToSend, BitcoinCashAddress senderBCHp2pkhwt, BigInt totalAmountInSatoshisAvailable, List<UtxoWithAddress> utxos, BitcoinBaseAddress receiverP2PKHWT, CashToken token, BigInt totalAmountOfTokenAvailable, BitcoinCashNetwork network) {
    var amount = BigInt.from(tokenAmountToSend);
    //TODO AUTO CONSOLIDATE TO SAVE ON FEES
    BigInt fee = BtcUtils.toSatoshi("0.000007");
    BigInt tokenFee = BtcUtils.toSatoshi("0.000007");
    return ForkedTransactionBuilder(
      outPuts: [
        /// change address for bch values (sum of bch amout - (outputs amount + fee))
        BitcoinOutput(
          address: senderBCHp2pkhwt.baseAddress,
          value: totalAmountInSatoshisAvailable -
              (tokenFee + tokenFee + fee),
        ),
        BitcoinTokenOutput(
            utxoHash: utxos.first.utxo.txHash,
            address: receiverP2PKHWT,
            value: tokenFee,
            token: token.copyWith(amount: amount)),
        BitcoinTokenOutput(
            utxoHash: utxos.first.utxo.txHash,
            address: senderBCHp2pkhwt.baseAddress,
            value: tokenFee,
            token: token.copyWith(amount: totalAmountOfTokenAvailable - amount)),
      ],
      fee: fee,
      network: network,
      memo: null,
      utxos: utxos,
    );
  }

  CashToken findTokenById(List<ElectrumUtxo> electrumUTXOs, String tokenId) {
    return electrumUTXOs
        .firstWhere((e) =>
    e.token?.category ==
        tokenId)
        .token!;
  }

  BigInt calculateTotalAmountOfThatToken(List<UtxoWithAddress> utxos, String tokenId) {
    return utxos
        .where((element) =>
    element.utxo.token?.category ==
        tokenId)
        .fold(
        BigInt.zero,
            (previousValue, element) =>
        previousValue + element.utxo.token!.amount);
  }

  List<UtxoWithAddress> transformUtxosFilterForTokenId(List<ElectrumUtxo> electrumUTXOs, BitcoinCashAddress senderBCHp2pkhwt, ECPrivate bip44Sender, String tokenId) {
    return electrumUTXOs
        .map((e) => UtxoWithAddress(
        utxo: e.toUtxo(senderBCHp2pkhwt.type),
        ownerDetails: UtxoAddressDetails(
            publicKey: bip44Sender.getPublic().toHex(), address: senderBCHp2pkhwt.baseAddress)))
        .toList()
        .where((element) {
      return element.utxo.token?.category ==
          tokenId ||
          element.utxo.token == null;
    }).toList();
  }

  Future<List<ElectrumUtxo>> requestElectrumUtxos(
      ElectrumProvider provider, BitcoinCashAddress p2pkhAddress, {bool includeCashtokens = false}) async {
    final utxos = await provider.request(ElectrumRequestScriptHashListUnspent(
      scriptHash: p2pkhAddress.baseAddress.pubKeyHash(),
      includeTokens: includeCashtokens,
    ));
    return utxos;
  }

  P2pkhAddress createAddressP2PKHWT(ECPrivate pk) {
    ECPublic pubKey = pk.getPublic();

    return P2pkhAddress.fromHash160(
        addrHash: pubKey.toAddress().addressProgram,
        type: P2pkhAddressType.p2pkhwt);
  }

  ECPrivate createBip44PrivateKey(String mnemonic, String derivationPath) {
    //TODO check that derivationPath is one of specified Enums

    List<int> seed = Bip39SeedGenerator(Mnemonic.fromString(
        mnemonic))
        .generate();

    Bip32Slip10Secp256k1 bip32 = Bip32Slip10Secp256k1.fromSeed(seed);
    Bip32Base bip44 = bip32.derivePath(derivationPath);
    return ECPrivate.fromBytes(bip44.privateKey.raw);
  }

  Future<String> broadcastTransaction(ElectrumProvider provider,
      BtcTransaction tx) async {
    //TODO handle dust xceptions
    await provider.request(
        ElectrumRequestBroadCastTransaction(transactionRaw: tx.toHex()),
        timeout: const Duration(seconds: 30));
    return "success";
  }
}