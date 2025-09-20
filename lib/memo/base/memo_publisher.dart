import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_tip.dart';

import '../../provider/electrum_provider.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

const int hash160DigestLength = QuickCrypto.hash160DigestSize;
const network = BitcoinCashNetwork.mainnet;

class MemoPublisher {
  // Add a final Ref field to store the Riverpod ref.
  final Ref _ref;
  static BigInt minerFeeDefault = BtcUtils.toSatoshi("0.000007");
  late String _memoMessage;
  late MemoCode _memoAction;
  ECPrivate? _pk;
  String? _wif;
  late BitcoinCashAddress _p2pkhAddress;
  late ECPublic _publicKey;
  late ECPrivate _privateKey;

  // Add the Ref to the constructor.
  MemoPublisher._create(this._ref, this._memoMessage, this._memoAction, {ECPrivate? pk, String? wif}) : _wif = wif, _pk = pk {
    _privateKey = _pk ?? (ECPrivate.fromWif(_wif ?? "xxx", netVersion: network.wifNetVer));
    _publicKey = _privateKey.getPublic();
    _p2pkhAddress = BitcoinCashAddress.fromBaseAddress(_publicKey.toAddress());
  }

  // The create method must now accept a Ref and pass it to the private constructor.
  static Future<MemoPublisher> create(Ref ref, String msg, MemoCode code, {ECPrivate? pk, String? wif}) async {
    MemoPublisher publisher = MemoPublisher._create(ref, msg, code, pk: pk, wif: wif);
    // Remove the redundant _initAsync call. The provider is ready to use.
    return publisher;
  }

  Future<MemoAccountantResponse> doPublish({String topic = "", tips}) async {
    if (_memoAction == MemoCode.profileMessage || _memoAction == MemoCode.topicMessage) topic = _addSuperTagAndSuperTopic(topic);
    final MemoBitcoinBase base = await _ref.read(electrumServiceProvider.future);

    final List<ElectrumUtxo> elctrumUtxos = await base.requestElectrumUtxos(_p2pkhAddress);

    if (elctrumUtxos.isEmpty) {
      return MemoAccountantResponse.noUtxo;
    }

    List<UtxoWithAddress> utxos = addUtxoAddressDetails(elctrumUtxos);
    //TODO the remove dust utxo might be helpful in any case but shouldnt be required for non memo that dont have SLP
    //TODO this removeSlp shouldnt be required in this app as the addresses dont use dev path 245
    utxos = removeSlpUtxos(utxos);

    final BigInt walletBalance = utxos.sumOfUtxosValue();
    if (walletBalance == BigInt.zero) {
      return MemoAccountantResponse.lowBalance;
    }
    final BtcTransaction tx = createTransaction(walletBalance, utxos, memoTopic: topic, memoTips: tips);
    try {
      await base.broadcastTransaction(tx);
    } catch (e) {
      //TODO CHECK RPC ERROR CODE AND RETURN LOWBALANCE OR DUST
      return MemoAccountantResponse.lowBalance;
    }
    return MemoAccountantResponse.yes;
  }

  String _addSuperTagAndSuperTopic(String topic) {
    _memoMessage += MemoVerifier.super_tag;

    if (topic.isEmpty) {
      if (_memoMessage.length + MemoVerifier.super_topic.length < MemoVerifier.maxPostLength) {
        topic = MemoVerifier.super_topic;
        _memoAction = MemoCode.topicMessage;
      }
    }
    return topic;
  }

  // Rest of your methods remain the same.
  BtcTransaction createTransaction(BigInt balance, List<UtxoWithAddress> utxos, {memoTopic = "", required List<MemoTip> memoTips}) {
    final MemoTransactionBuilder txBuilder = createTxBuilder(balance, utxos, memoTopic, memoTips);
    final tx = txBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
      return _privateKey.signECDSA(trDigest, sighash: sighash);
    });
    return tx;
  }

  MemoTransactionBuilder createTxBuilder(BigInt balance, List<UtxoWithAddress> utxos, String topic, List<MemoTip> tips) {
    BigInt outputHome = balance - minerFeeDefault;
    BigInt totalTips = BigInt.zero;

    for (MemoTip tip in tips) {
      totalTips += tip.amountAsBigInt;
    }

    var hasValidTip = totalTips != BigInt.zero;
    if (hasValidTip) {
      outputHome = outputHome - totalTips;
    }

    final txBuilder = MemoTransactionBuilder(
      outPuts: [BitcoinOutput(address: _p2pkhAddress.baseAddress, value: outputHome)],
      fee: minerFeeDefault,
      network: network,
      utxos: utxos,
      memo: _memoMessage,
      memoCode: _memoAction,
      memoTopic: topic,
    );

    if (hasValidTip) {
      for (MemoTip tip in tips) {
        txBuilder.outPuts.add(BitcoinOutput(address: tip.receiverAsBchAddress.baseAddress, value: tip.amountAsBigInt));
      }
    }

    return txBuilder;
  }

  List<UtxoWithAddress> addUtxoAddressDetails(List<ElectrumUtxo> elctrumUtxos) {
    List<UtxoWithAddress> utxos = elctrumUtxos
        .map(
          (e) => UtxoWithAddress(
            utxo: e.toUtxo(_p2pkhAddress.type),
            ownerDetails: UtxoAddressDetails(publicKey: _publicKey.toHex(), address: _p2pkhAddress.baseAddress),
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
