import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memoscraper/socket/electrum_websocket_service.dart';

/// please make sure read this before create transaction on mainnet
//// https://github.com/cashtokens/cashtokens
void main() async {
  /// connect to electrum service with websocket
  /// please see `services_examples` folder for how to create electrum websocket service
  final service = await ElectrumWebSocketService.connect(
      "wss://bch.imaginary.cash:50004");

  /// create provider with service
  final provider = ElectrumProvider(service);
  final List<int> senderSeed = Bip39SeedGenerator(Mnemonic.fromString(
      "xxx"))
      .generate();

  final List<int> receiverSeed = Bip39SeedGenerator(Mnemonic.fromString(
      "xxx"))
      .generate();

  final tokenId = "d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002";
  /// network
  const network = BitcoinCashNetwork.mainnet;

  final bip44Sender = Bip44.fromSeed(senderSeed, Bip44Coins.bitcoinCash);
  final bip44Receiver = Bip44.fromSeed(receiverSeed, Bip44Coins.bitcoinCash);
  // final spSender = bip44Sender.derivePath("m/44'/145'/0'/0/0");
  // final spReceiver = bip32Receiver.derivePath("m/44'/145'/0'/0/0");

  // access to private key `ECPrivate`
  // final private1 = ECPrivate.fromBytes(sp1.privateKey.raw);

  /// initialize private key
  final privateKeySender = ECPrivate.fromBytes(bip44Sender.privateKey.raw);

  /// public key
  final publicKeySender = privateKeySender.getPublic();


  /// initialize private key
  final privateKeyReceiver = ECPrivate.fromBytes(bip44Receiver.privateKey.raw);

  /// public key
  final publicKeyReceiver = privateKeyReceiver.getPublic();

  /// Derives a P2PKH address from the given public key and converts it to a Bitcoin Cash address
  /// for enhanced accessibility within the network.
  // final BitcoinCashAddress senderBCHp2pkhwt = BitcoinCashAddress.fromBaseAddress(
  //     publicKeySender.toP2pkInP2sh(useBCHP2sh32: true));

  /// p2pkh with token address ()
  final P2pkhAddress senderP2PKHWT = P2pkhAddress.fromHash160(
      addrHash: publicKeyReceiver.toAddress().addressProgram,
      type: P2pkhAddressType.p2pkhwt);

  final BitcoinCashAddress senderBCHp2pkhwt = BitcoinCashAddress.fromBaseAddress(senderP2PKHWT);

  /// p2pkh with token address ()
  final P2pkhAddress receiver = P2pkhAddress.fromHash160(
      addrHash: publicKeyReceiver.toAddress().addressProgram,
      type: P2pkhAddressType.p2pkhwt);

  /// Reads all UTXOs (Unspent Transaction Outputs) associated with the account.
  /// We does not need tokens utxo and we set to false.
  final elctrumUtxos =
  await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: senderP2PKHWT.pubKeyHash(),
    includeTokens: true,
  ));
  // return;

  if (elctrumUtxos.length == 0) {
    print("object");
  }

  /// Converts all UTXOs to a list of UtxoWithAddress, containing UTXO information along with address details.
  final List<UtxoWithAddress> utxos = elctrumUtxos
      .map((e) => UtxoWithAddress(
      utxo: e.toUtxo(senderBCHp2pkhwt.type),
      ownerDetails: UtxoAddressDetails(
          publicKey: publicKeySender.toHex(), address: senderBCHp2pkhwt.baseAddress)))
      .toList()

  /// we only filter the utxos for this token or none token utxos
      .where((element) {
    return element.utxo.token?.category ==
        tokenId ||
        element.utxo.token == null;
  })
      .toList();

  /// som of utxos in satoshi
  final sumOfUtxo = utxos.sumOfUtxosValue();
  if (sumOfUtxo == BigInt.zero) {
    return;
  }

  /// CashToken{bitfield: 16, commitment: null, amount: 2000, category: d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002}
  final CashToken token = elctrumUtxos
      .firstWhere((e) =>
  e.token?.category ==
      tokenId)
      .token!;

  /// sum of ft token amounts with category "d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002"
  final sumofTokenUtxos = utxos
      .where((element) =>
  element.utxo.token?.category ==
      tokenId)
      .fold(
      BigInt.zero,
          (previousValue, element) =>
      previousValue + element.utxo.token!.amount);

  final bchTransaction = ForkedTransactionBuilder(
    outPuts: [
      /// change address for bch values (sum of bch amout - (outputs amount + fee))
      BitcoinOutput(
        address: senderBCHp2pkhwt.baseAddress,
        value: sumOfUtxo -
            (BtcUtils.toSatoshi("0.00002") + BtcUtils.toSatoshi("0.00003")),
      ),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: receiver,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),

          /// clone the token with new token amount for output1 (15 amount of category)
          token: token.copyWith(amount: BigInt.from(15))),

      /// another change token value to change account like bch
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: senderBCHp2pkhwt.baseAddress,

          /// for a token-bearing output (600-700) satoshi
          /// hard-coded value which is expected to be enough to allow
          /// all conceivable token-bearing UTXOs (1000 satoshi)
          value: BtcUtils.toSatoshi("0.00001"),

          /// clone the token with new token amount for output1 (15 amount of category)
          token: token.copyWith(amount: sumofTokenUtxos - BigInt.from(15))),
    ],
    fee: BtcUtils.toSatoshi("0.00003"),
    network: network,

    /// Bitcoin Cash Metadata Registries
    /// pleas see https://cashtokens.org/docs/bcmr/chip/ for how to create cash metadata
    /// we does not create metadata for this token
    memo: null,
    utxos: utxos,
  );
  final transaaction =
  bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return privateKeySender.signECDSA(trDigest, sighash: sighash);
  });

  /// transaction ID
  transaaction.txId();

  /// for calculation fee
  transaaction.getSize();

  /// raw of encoded transaction in hex
  final transactionRaw = transaaction.toHex();

  /// send transaction to network
  await provider.request(
      ElectrumRequestBroadCastTransaction(transactionRaw: transactionRaw));

  /// done! check the transaction in block explorer
  ///  https://chipnet.imaginary.cash/tx/97030c1236a024de7cad7ceadf8571833029c508e016bcc8173146317e367ae6
}
