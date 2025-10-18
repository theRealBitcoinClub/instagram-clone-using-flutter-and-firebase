// import 'package:bitcoin_base/bitcoin_base.dart';
// import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
//
// void main() async {
//   //TODO if user profile id is provided, then trigger the SLP send to their original memo addres
//   //TODO SLP SEND SERVERSIDE on every action	mnemonicZXCXZCASD
//
//   MemoBitcoinBase base = await MemoBitcoinBase.create();
//   ECPrivate bip44Sender = MemoBitcoinBase.createBip44PrivateKey("mnemonicKDSFJE", MemoBitcoinBase.derivationPathCashtoken);
//   P2pkhAddress senderP2PKHWT = base.createAddressP2PKHWT(bip44Sender);
//   ECPrivate bip44Receiver = MemoBitcoinBase.createBip44PrivateKey("mnemonicZXCXZCASD", MemoBitcoinBase.derivationPathCashtoken);
//   P2pkhAddress receiverP2PKHWT = base.createAddressP2PKHWT(bip44Receiver);
//   //TODO burn token or send token depends on if receiver mnemonic is provided
//   // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress("bitcoincash:qp97cpfavlgudx8jzk553n0rfe66lk73k59k2ayp36").baseAddress;
//   // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress(MemoBitcoinBase.burnCashtokenAddress).baseAddress;
//
//   BitcoinCashAddress senderBCHp2pkhwt = BitcoinCashAddress.fromBaseAddress(senderP2PKHWT);
//
//   List<ElectrumUtxo> electrumUTXOs = await base.requestElectrumUtxos(senderBCHp2pkhwt, includeCashtokens: true);
//
//   if (electrumUTXOs.length == 0) {
//     print("Zero UTXOs found");
//     return;
//   }
//
//   List<UtxoWithAddress> utxos = base.getSpecificTokenAndGeneralUtxos(electrumUTXOs, senderBCHp2pkhwt, bip44Sender, MemoBitcoinBase.tokenId);
//
//   BigInt totalAmountInSatoshisAvailable = utxos.sumOfUtxosValue();
//   if (totalAmountInSatoshisAvailable == BigInt.zero) {
//     print("Zero UTXOs with that tokenId found");
//     return;
//   }
//
//   CashToken token = base.findTokenById(electrumUTXOs, MemoBitcoinBase.tokenId);
//   BigInt totalAmountOfTokenAvailable = base.calculateTotalAmountOfThatToken(utxos, MemoBitcoinBase.tokenId);
//
//   ForkedTransactionBuilder bchTransaction = base.buildTxToTransferTokens(
//     1,
//     senderBCHp2pkhwt,
//     totalAmountInSatoshisAvailable,
//     utxos,
//     receiverP2PKHWT,
//     token,
//     totalAmountOfTokenAvailable,
//   );
//
//   BtcTransaction signedTx = bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
//     return bip44Sender.signECDSA(trDigest, sighash: sighash);
//   });
//
//   //TODO handle dust exceptions, prepare utxo set with tiny BCH to cause exception
//   base.broadcastTransaction(signedTx);
//   print("success");
// }
