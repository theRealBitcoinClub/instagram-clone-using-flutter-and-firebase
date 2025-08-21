import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memoscraper/socket/electrum_websocket_service.dart';

class MemoBitcoinBase {
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

  ECPrivate createBip44PrivateKey(String mnemonic, String derivationPath) {
    List<int> seed = Bip39SeedGenerator(Mnemonic.fromString(
        mnemonic))
        .generate();

    Bip32Slip10Secp256k1 bip32 = Bip32Slip10Secp256k1.fromSeed(seed);
    Bip32Base bip44 = bip32.derivePath(derivationPath);
    return ECPrivate.fromBytes(bip44.privateKey.raw);
  }
}