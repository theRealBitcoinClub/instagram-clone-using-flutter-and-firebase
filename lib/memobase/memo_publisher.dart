import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memobase/memo_accountant.dart';
import 'package:instagram_clone1/memobase/memo_bitcoin_base.dart';

import '../memomodel/memo_tip.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

const int hash160DigestLength = QuickCrypto.hash160DigestSize;
const network = BitcoinCashNetwork.mainnet;

class MemoPublisher {
  late MemoBitcoinBase base;
  BigInt fee = BtcUtils.toSatoshi("0.000007");
  late String memoMessage;
  late MemoCode memoAction;
  ECPrivate? pk;
  String? wif;
  late BitcoinCashAddress p2pkhAddress;
  late ECPublic publicKey;
  late ECPrivate privateKey;

  MemoPublisher._create(this.memoMessage, this.memoAction, {this.pk, this.wif}) {
    privateKey = pk ?? (ECPrivate.fromWif(wif ?? "xxx", netVersion: network.wifNetVer));
    publicKey = privateKey.getPublic();
    p2pkhAddress = BitcoinCashAddress.fromBaseAddress(publicKey.toAddress());
  }

  static Future<MemoPublisher> create(String msg, MemoCode code, {ECPrivate? pk, String? wif}) async {
    MemoPublisher publisher = MemoPublisher._create(msg, code, pk: pk, wif: wif);

    await publisher._initAsync();

    return publisher;
  }

  _initAsync() async {
    base = await MemoBitcoinBase.create();
  }

  Future<MemoAccountantResponse> doMemoAction({String topic = "", MemoTip? tip}) async {
    print("\n${memoAction.opCode}\n${memoAction.name}");

    print("https://bchblockexplorer.com/address/${p2pkhAddress.address}");

    final List<ElectrumUtxo> elctrumUtxos = await base.requestElectrumUtxos(p2pkhAddress);

    if (elctrumUtxos.isEmpty) {
      return MemoAccountantResponse.noUtxo;
    }

    List<UtxoWithAddress> utxos = addUtxoAddressDetails(elctrumUtxos);

    utxos = removeSlpUtxos(utxos);

    final BigInt walletBalance = utxos.sumOfUtxosValue();

    if (walletBalance == BigInt.zero) {
      return MemoAccountantResponse.lowBalance;
    }
    // final BigInt tip = BigInt.parse(tipAmount);
    final BtcTransaction tx = createTransaction(walletBalance, utxos, memoTopic: topic, memoTip: tip);

    print(tx.txId());
    print("http://memo.cash/explore/tx/${tx.txId()}");
    print("https://bchblockexplorer.com/tx/${tx.txId()}");

    //TODO TRY AGAIN ON TIMEOUT
    //TODO TRY AGAIN ON REJECTED NETWORK RULES RAISE FEE
    //TODO TRY AGAIN ON DUST ANALYSE DUST
    // RPCError: got code 1 with message "the transaction was rejected by network rules.
    //
    // dust (code 64)
    //  code: 1, message: the transaction was rejected by network rules.
    //
    // dust (code 64)
    // ".
    //TODO OPTIMIZE FEE COST FOR PAYING CUSTOMERS TRY TINY FIRST
    try {
      await base.broadcastTransaction(tx);
    } catch (e) {
      print("catching");
      return MemoAccountantResponse.dust;
    }
    return MemoAccountantResponse.yes;
  }

  BtcTransaction createTransaction(
    BigInt walletBalance,
    List<UtxoWithAddress> utxos, {
    String memoTopic = "",
    MemoTip? memoTip,
  }) {
    final MemoTransactionBuilder txBuilder = createTransactionBuilder(walletBalance, utxos, memoTopic, memoTip);
    final tx = txBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
      return privateKey.signECDSA(trDigest, sighash: sighash);
    });
    return tx;
  }

  MemoTransactionBuilder createTransactionBuilder(
    BigInt walletBalance,
    List<UtxoWithAddress> utxos,
    String memoTopic,
    MemoTip? memoTip,
  ) {
    BigInt? tipAmount;
    BigInt outputHome = walletBalance - fee;
    BitcoinCashAddress? tipToThisAddress;
    var hasValidTip = memoTip != null && memoTip.amountInSats > MemoTip.dust;
    if (hasValidTip) {
      tipAmount = BigInt.from(memoTip.amountInSats);
      outputHome = outputHome - tipAmount;
      P2pkhAddress legacy = P2pkhAddress.fromAddress(address: memoTip.receiverAddress, network: memoTip.network);
      // String addr = legacyToBchAddress(addressProgram: legacy.addressProgram, network: network, type: P2pkhAddressType.p2pkh);
      tipToThisAddress = BitcoinCashAddress.fromBaseAddress(legacy);
    }

    final txBuilder = MemoTransactionBuilder(
      outPuts: [BitcoinOutput(address: p2pkhAddress.baseAddress, value: outputHome)],
      fee: fee,
      network: network,
      utxos: utxos,
      memo: memoMessage,
      memoCode: memoAction,
      memoTopic: memoTopic,
    );

    if (hasValidTip) txBuilder.outPuts.add(BitcoinOutput(address: tipToThisAddress!.baseAddress, value: tipAmount!));

    return txBuilder;
  }

  List<UtxoWithAddress> addUtxoAddressDetails(List<ElectrumUtxo> elctrumUtxos) {
    List<UtxoWithAddress> utxos = elctrumUtxos
        .map(
          (e) => UtxoWithAddress(
            utxo: e.toUtxo(p2pkhAddress.type),
            ownerDetails: UtxoAddressDetails(publicKey: publicKey.toHex(), address: p2pkhAddress.baseAddress),
          ),
        )
        .toList();
    return utxos;
  }

  List<UtxoWithAddress> removeSlpUtxos(List<UtxoWithAddress> utxos) {
    for (UtxoWithAddress utxo in utxos.clone()) {
      if (utxo.utxo.value.toSignedInt32 == 546) {
        utxos.remove(utxo);
      }
    }
    return utxos;
  }
}
