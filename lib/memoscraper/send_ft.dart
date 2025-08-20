import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'socket/electrum_websocket_service.dart';

void main() async {
  ElectrumWebSocketService service = await ElectrumWebSocketService.connect(
      "wss://bch.imaginary.cash:50004");

  String tokenId = "your-FT-token-id";
  BitcoinCashNetwork network = BitcoinCashNetwork.mainnet;

  ElectrumProvider provider = ElectrumProvider(service);
  ECPrivate bip44Sender = createBip44PrivateKey(
      "12-word-mnemonic that you can obtain on cashonize.com");
  P2pkhAddress senderP2PKHWT = createAddressP2PKHWT(bip44Sender);
  ECPrivate bip44Receiver = createBip44PrivateKey(
      "12-word-mnemonic that you can obtain on cashonize.com");
  P2pkhAddress receiverP2PKHWT = createAddressP2PKHWT(bip44Receiver);
  
  BitcoinCashAddress senderBCHp2pkhwt = BitcoinCashAddress.fromBaseAddress(senderP2PKHWT);
  
  List<ElectrumUtxo> electrumUTXOs = await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: senderP2PKHWT.pubKeyHash(),
    includeTokens: true,
  ));

  if (electrumUTXOs.length == 0) {
    print("Zero UTXOs found");
    return;
  }

  List<UtxoWithAddress> utxos = transformUtxosFilterForTokenId(electrumUTXOs, senderBCHp2pkhwt, bip44Sender, tokenId);

  BigInt totalAmountInSatoshisAvailable = utxos.sumOfUtxosValue();
  if (totalAmountInSatoshisAvailable == BigInt.zero) {
    print("Zero UTXOs with that tokenId found");
    return;
  }

  CashToken token = findTokenById(electrumUTXOs, tokenId);
  BigInt totalAmountOfTokenAvailable = calculateTotalAmountOfThatToken(utxos, tokenId);

  ForkedTransactionBuilder bchTransaction = buildTxToTransferTokens(
      15,
      senderBCHp2pkhwt,
      totalAmountInSatoshisAvailable,
      utxos,
      receiverP2PKHWT,
      token,
      totalAmountOfTokenAvailable,
      network);

  BtcTransaction signedTx = bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return bip44Sender.signECDSA(trDigest, sighash: sighash);
  });

  await provider.request(
      ElectrumRequestBroadCastTransaction(transactionRaw: signedTx.toHex()));
  print("success");
}

ForkedTransactionBuilder buildTxToTransferTokens(int tokenAmountToSend, BitcoinCashAddress senderBCHp2pkhwt, BigInt totalAmountInSatoshisAvailable, List<UtxoWithAddress> utxos, P2pkhAddress receiverP2PKHWT, CashToken token, BigInt totalAmountOfTokenAvailable, BitcoinCashNetwork network) {
  var amount = BigInt.from(tokenAmountToSend);
  BigInt fee = BtcUtils.toSatoshi("0.00003");
  return ForkedTransactionBuilder(
    outPuts: [
      /// change address for bch values (sum of bch amout - (outputs amount + fee))
      BitcoinOutput(
        address: senderBCHp2pkhwt.baseAddress,
        value: totalAmountInSatoshisAvailable -
            (BtcUtils.toSatoshi("0.00002") + fee),
      ),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: receiverP2PKHWT,
          value: BtcUtils.toSatoshi("0.00001"),
          token: token.copyWith(amount: amount)),
      BitcoinTokenOutput(
          utxoHash: utxos.first.utxo.txHash,
          address: senderBCHp2pkhwt.baseAddress,
          value: BtcUtils.toSatoshi("0.00001"),
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

P2pkhAddress createAddressP2PKHWT(ECPrivate pk) {
  ECPublic pubKey = pk.getPublic();
  
  return P2pkhAddress.fromHash160(
      addrHash: pubKey.toAddress().addressProgram,
      type: P2pkhAddressType.p2pkhwt);
}

ECPrivate createBip44PrivateKey(String mnemonic) {
  List<int> seed = Bip39SeedGenerator(Mnemonic.fromString(
      mnemonic))
      .generate();
  
  Bip32Slip10Secp256k1 bip32 = Bip32Slip10Secp256k1.fromSeed(seed);
  Bip32Base bip44 = bip32.derivePath("m/44'/145'/0'/0/0");
  return ECPrivate.fromBytes(bip44.privateKey.raw);
}
