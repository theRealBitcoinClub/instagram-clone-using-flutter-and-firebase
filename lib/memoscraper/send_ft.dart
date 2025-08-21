import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memoscraper/memo_bitcoin_base.dart';
import 'package:instagram_clone1/memoscraper/socket/electrum_websocket_service.dart';

void main() async {
  ElectrumWebSocketService service = await ElectrumWebSocketService.connect(
      "wss://bch.imaginary.cash:50004");

  String tokenId = "d44bf7822552d522802e7076dc9405f5e43151f0ac12b9f6553bda1ce8560002";
  BitcoinCashNetwork network = BitcoinCashNetwork.mainnet;

  //TODO if user profile id is provided, then trigger the SLP send to their original memo address
  //TODO SLP SEND SERVERSIDE on every action	mnemonicZXCXZCASD

  ElectrumProvider provider = ElectrumProvider(service);

  MemoBitcoinBase base = MemoBitcoinBase();
  ECPrivate bip44Sender = base.createBip44PrivateKey(
      "mnemonicKDSFJE", "m/44'/145'/0'/0/0");
  P2pkhAddress senderP2PKHWT = base.createAddressP2PKHWT(bip44Sender);
  ECPrivate bip44Receiver = base.createBip44PrivateKey(
      "mnemonicZXCXZCASD", "m/44'/145'/0'/0/0");
  ECPrivate legacyPK = base.createBip44PrivateKey(
      "mnemonicZXCXZCASD", "m/44'/0'/0'/0/0");
  ECPrivate slpPK = base.createBip44PrivateKey(
      "mnemonicZXCXZCASD", "m/44'/245'/0'/0/0");
  P2pkhAddress receiverP2PKHWT = base.createAddressP2PKHWT(bip44Receiver);
  //TODO burn token or send token depends on if receiver mnemonic is provided
  // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress("bitcoincash:qp97cpfavlgudx8jzk553n0rfe66lk73k59k2ayp36").baseAddress;
  // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress("bitcoincash:r0lxr93av56s6ja253zmg6tjgwclfryeardw6v427e74uv6nfkrlc2s5qtune").baseAddress;

  //TODO use m/44/ for publishing to memo and m/145/ to send and burn tokens
  //TODO user can use BCH to send the reply tip or cashtokens but paying with BCH should be more expensive
  //TODO users can use BCH or cashtokens to burn on likes but BCH be double price
  //TODO like BCH goes to address that will then buy and burn
  // await MemoPublisher().doMemoAction("ok", MemoCode.profileMessage, wif: legacyPK.toWif());

  //TODO create an address to receive TOKENS and BCH that are unclaimed, keep track of profile IDs and how much they would earn if they would claim with their seed phrase
  //TODO buy and burn all unclaimed BCH & tokens every 3rd january

  //TODO to start let users earn tokens by posting and burn tokens by liking, both actions they have to pay BCH from their 145 dev path memo seed

  //TODO let users start by importing the memo seed and generate the BCH for QR code from that seed

  //TODO show them their 145 token balance & their 145 BCH balance instead of actions & followers

  BitcoinCashAddress senderBCHp2pkhwt = BitcoinCashAddress.fromBaseAddress(senderP2PKHWT);
  
  List<ElectrumUtxo> electrumUTXOs = await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: senderP2PKHWT.pubKeyHash(),
    includeTokens: true,
  ));

  if (electrumUTXOs.length == 0) {
    print("Zero UTXOs found");
    return;
  }

  List<UtxoWithAddress> utxos = base.transformUtxosFilterForTokenId(electrumUTXOs, senderBCHp2pkhwt, bip44Sender, tokenId);

  BigInt totalAmountInSatoshisAvailable = utxos.sumOfUtxosValue();
  if (totalAmountInSatoshisAvailable == BigInt.zero) {
    print("Zero UTXOs with that tokenId found");
    return;
  }

  CashToken token = base.findTokenById(electrumUTXOs, tokenId);
  BigInt totalAmountOfTokenAvailable = base.calculateTotalAmountOfThatToken(utxos, tokenId);

  ForkedTransactionBuilder bchTransaction = base.buildTxToTransferTokens(
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
