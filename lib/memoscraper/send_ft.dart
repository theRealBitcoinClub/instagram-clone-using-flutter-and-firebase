import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memoscraper/socket/electrum_websocket_service.dart';

void main() async {
  ElectrumWebSocketService service = await ElectrumWebSocketService.connect(
      "wss://bch.imaginary.cash:50004");

  //TODO if user profile id is provided, then trigger the SLP send to their original memo address
  //TODO SLP SEND SERVERSIDE on every action	nerve jazz toward mother fury attack library piano shell neck math shoe

  String tokenId = "d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002";
  BitcoinCashNetwork network = BitcoinCashNetwork.mainnet;

  ElectrumProvider provider = ElectrumProvider(service);
  ECPrivate bip44Sender = createBip44PrivateKey(
      "xxxx");
  P2pkhAddress senderP2PKHWT = createAddressP2PKHWT(bip44Sender);
  ECPrivate bip44Receiver = createBip44PrivateKey(
      "xxxx");
  // P2pkhAddress receiverP2PKHWT = createAddressP2PKHWT(bip44Receiver);
  //TODO burn token or send token depends on if receiver mnemonic is provided
  BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress("bitcoincash:r0lxr93av56s6ja253zmg6tjgwclfryeardw6v427e74uv6nfkrlc2s5qtune").baseAddress;

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
      1,
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
