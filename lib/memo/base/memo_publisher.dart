import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/model/memo_tip.dart';

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

  Future<MemoAccountantResponse> doPublish({String topic = "", MemoTip? tip}) async {
    // print("\n${memoAction.opCode}\n${memoAction.name}");
    // print("https://bchblockexplorer.com/address/${p2pkhAddress.address}");
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
    final BtcTransaction tx = createTransaction(walletBalance, utxos, memoTopic: topic, memoTip: tip);
    // print(tx.txId());
    // print("http://memo.cash/explore/tx/${tx.txId()}");
    // print("https://bchblockexplorer.com/tx/${tx.txId()}");
    //TODO TRY AGAIN ON TIMEOUT
    //TODO TRY AGAIN ON REJECTED NETWORK RULES RAISE FEE
    //TODO OPTIMIZE FEE COST FOR PAYING CUSTOMERS TRY TINY FIRST
    try {
      await base.broadcastTransaction(tx);
    } catch (e) {
      //TODO dust can mean that balance is low but also if tip thats lower than dust is being sent
      return MemoAccountantResponse.dust;
    }
    return MemoAccountantResponse.yes;
  }

  BtcTransaction createTransaction(BigInt balance, List<UtxoWithAddress> utxos, {memoTopic = "", MemoTip? memoTip}) {
    final MemoTransactionBuilder txBuilder = createTxBuilder(balance, utxos, memoTopic, memoTip);
    final tx = txBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
      return privateKey.signECDSA(trDigest, sighash: sighash);
    });
    return tx;
  }

  MemoTransactionBuilder createTxBuilder(BigInt balance, List<UtxoWithAddress> utxos, String topic, MemoTip? tip) {
    BigInt outputHome = balance - fee;
    var hasValidTip = tip != null && tip.amountInSats > MemoTip.dust;
    if (hasValidTip) {
      outputHome = outputHome - tip.amountAsBigInt;
    }

    final txBuilder = MemoTransactionBuilder(
      outPuts: [BitcoinOutput(address: p2pkhAddress.baseAddress, value: outputHome)],
      fee: fee,
      network: network,
      utxos: utxos,
      memo: memoMessage,
      memoCode: memoAction,
      memoTopic: topic,
    );

    if (hasValidTip) txBuilder.outPuts.add(BitcoinOutput(address: tip.receiverAsBchAddress.baseAddress, value: tip.amountAsBigInt));

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
