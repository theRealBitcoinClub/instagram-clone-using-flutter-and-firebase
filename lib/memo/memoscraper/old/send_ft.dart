import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:mahakka/memo/memobase/memo_bitcoin_base.dart';

void main() async {
  //TODO if user profile id is provided, then trigger the SLP send to their original memo address
  //TODO SLP SEND SERVERSIDE on every action	mnemonicZXCXZCASD

  MemoBitcoinBase base = await MemoBitcoinBase.create();
  ECPrivate bip44Sender = MemoBitcoinBase.createBip44PrivateKey(
    "mnemonicKDSFJE",
    MemoBitcoinBase.derivationPathCashtoken,
  );
  P2pkhAddress senderP2PKHWT = base.createAddressP2PKHWT(bip44Sender);
  ECPrivate bip44Receiver = MemoBitcoinBase.createBip44PrivateKey(
    "mnemonicZXCXZCASD",
    MemoBitcoinBase.derivationPathCashtoken,
  );
  P2pkhAddress receiverP2PKHWT = base.createAddressP2PKHWT(bip44Receiver);
  //TODO burn token or send token depends on if receiver mnemonic is provided
  // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress("bitcoincash:qp97cpfavlgudx8jzk553n0rfe66lk73k59k2ayp36").baseAddress;
  // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress(MemoBitcoinBase.burnCashtokenAddress).baseAddress;

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

  List<ElectrumUtxo> electrumUTXOs = await base.requestElectrumUtxos(senderBCHp2pkhwt, includeCashtokens: true);

  if (electrumUTXOs.length == 0) {
    print("Zero UTXOs found");
    return;
  }

  List<UtxoWithAddress> utxos = base.transformUtxosFilterForTokenId(
    electrumUTXOs,
    senderBCHp2pkhwt,
    bip44Sender,
    MemoBitcoinBase.tokenId,
  );

  //TODO CHECK WHAT VALUE THE TOKEN UTXOS HAVE, DO THEY INFLUENCE TOTAL BALANCE?
  BigInt totalAmountInSatoshisAvailable = utxos.sumOfUtxosValue();
  if (totalAmountInSatoshisAvailable == BigInt.zero) {
    print("Zero UTXOs with that tokenId found");
    return;
  }

  CashToken token = base.findTokenById(electrumUTXOs, MemoBitcoinBase.tokenId);
  BigInt totalAmountOfTokenAvailable = base.calculateTotalAmountOfThatToken(utxos, MemoBitcoinBase.tokenId);

  ForkedTransactionBuilder bchTransaction = base.buildTxToTransferTokens(
    1,
    senderBCHp2pkhwt,
    totalAmountInSatoshisAvailable,
    utxos,
    receiverP2PKHWT,
    token,
    totalAmountOfTokenAvailable,
  );

  BtcTransaction signedTx = bchTransaction.buildTransaction((trDigest, utxo, publicKey, sighash) {
    return bip44Sender.signECDSA(trDigest, sighash: sighash);
  });

  //TODO handle dust exceptions, prepare utxo set with tiny BCH to cause exception
  base.broadcastTransaction(signedTx);
  print("success");
}
