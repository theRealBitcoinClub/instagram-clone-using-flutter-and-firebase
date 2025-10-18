import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_tip.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../provider/electrum_provider.dart';
import '../../repositories/creator_repository.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

const int hash160DigestLength = QuickCrypto.hash160DigestSize;
const network = BitcoinCashNetwork.mainnet;

class MemoPublisher {
  // Add a final Ref field to store the Riverpod ref.
  final Ref _ref;
  static BigInt feeMaxEstimation = BtcUtils.toSatoshi("0.00002");
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
  static Future<MemoPublisher> create(Ref ref, String msg, MemoCode code, String? wif) async {
    MemoPublisher publisher = MemoPublisher._create(ref, msg, code, wif: wif);
    return publisher;
  }

  Future<MemoAccountantResponse> doPublish({String topic = "", List<MemoTip> tips = const []}) async {
    if (_ref.read(userProvider)!.mnemonic != null &&
        (_memoAction == MemoCode.profileMessage || _memoAction == MemoCode.topicMessage || _memoAction == MemoCode.postLike)) {
      var userId = _ref.read(userProvider)!.id;
      var creator = await _ref.read(getCreatorProvider(userId).future);
      if (creator != null && creator.balanceToken > 0) {
        bool hasBurned = await triggerBurnTokens();
        if (hasBurned && tips.isNotEmpty) {
          tips.removeWhere(
            (element) => element.receiverAddress == MemoBitcoinBase.bchBurnerAddress,
          ); //remove the burner tip if user has contributed via token
        }
      }
    }

    if (_memoAction == MemoCode.profileMessage || _memoAction == MemoCode.topicMessage) topic = _addSuperTagAndSuperTopic(topic);
    final MemoBitcoinBase base = await _ref.read(electrumServiceProvider.future);

    final List<ElectrumUtxo> eutxos = await base.requestElectrumUtxos(_p2pkhAddress);

    if (eutxos.isEmpty) {
      return MemoAccountantResponse.noUtxo;
    }

    List<UtxoWithAddress> utxos = addUtxoAddressDetails(eutxos);
    if (_ref.read(userProvider)!.mnemonic == null) utxos = removeSlpUtxos(utxos);

    final BigInt walletBalance = utxos.sumOfUtxosValue();
    if (walletBalance == BigInt.zero) {
      return MemoAccountantResponse.lowBalance;
    }
    final BtcTransaction tx = createTransaction(walletBalance, utxos, memoTopic: topic, memoTips: tips);
    try {
      await base.broadcastTransaction(tx);
    } catch (e) {
      print("UNEXPECTED ERROR ${e}");
      //TODO CHECK RPC ERROR CODE AND RETURN LOWBALANCE OR DUST
      return MemoAccountantResponse.lowBalance;
    }
    return MemoAccountantResponse.yes;
  }

  String _addSuperTagAndSuperTopic(String topic) {
    if (!_memoMessage.contains(MemoVerifier.super_tag)) _memoMessage += MemoVerifier.super_tag;

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
    BigInt fee = calculateFee(tips, utxos);

    BigInt outputHome = balance - fee;
    BigInt totalTips = BigInt.zero;

    for (MemoTip tip in tips) {
      totalTips += tip.amountAsBigInt;
    }

    var hasValidTip = totalTips != BigInt.zero;
    if (hasValidTip) {
      outputHome = outputHome - totalTips;
    }

    var outPuts = [BitcoinOutput(address: _p2pkhAddress.baseAddress, value: outputHome)];

    if (hasValidTip) {
      for (MemoTip tip in tips) {
        outPuts.add(BitcoinOutput(address: tip.receiverAsBchAddress.baseAddress, value: tip.amountAsBigInt));
      }
    }

    final txBuilder = MemoTransactionBuilder(
      outPuts: outPuts,
      fee: fee,
      network: network,
      utxos: utxos,
      memo: _memoMessage,
      memoCode: _memoAction,
      memoTopic: topic,
    );

    return txBuilder;
  }

  BigInt calculateFee(List<MemoTip> tips, List<UtxoWithAddress> utxos) {
    BigInt eachInput = BtcUtils.toSatoshi("0.00000148");
    BigInt eachOutput = BtcUtils.toSatoshi("0.00000034");
    BigInt overhead = BtcUtils.toSatoshi("0.00000020");
    BigInt fee = eachOutput * BigInt.from(1); //OWN FUNDS
    fee += BtcUtils.toSatoshi("0.00000250"); //OP_RETURN w max text
    fee += eachOutput * BigInt.from(tips.length); //TIP & BURN
    fee += eachInput * BigInt.from(utxos.length); //CONSOLIDATE ALL UTXOS
    fee += overhead;
    return fee;
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

  static List<UtxoWithAddress> removeSlpUtxos(List<UtxoWithAddress> utxos) {
    for (UtxoWithAddress utxo in utxos.clone()) {
      if (utxo.utxo.value.toSignedInt32 == 546) {
        utxos.remove(utxo);
      }
    }
    return utxos;
  }

  Future<bool> triggerBurnTokens() async {
    try {
      MemoBitcoinBase base = await _ref.read(electrumServiceProvider.future);
      ECPrivate bip44Sender = _ref.read(userProvider)!.pkBchCashtoken;
      P2pkhAddress senderP2PKHWT = base.createAddressP2PKHWT(bip44Sender);
      // BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress(MemoBitcoinBase.tokenBurnerDotCashAddress).baseAddress;
      BitcoinBaseAddress receiverP2PKHWT = BitcoinCashAddress(MemoBitcoinBase.bchBurnerAddress).baseAddress;
      BitcoinCashAddress senderBCHp2pkhwt = BitcoinCashAddress.fromBaseAddress(senderP2PKHWT);
      List<ElectrumUtxo> electrumUTXOs = await base.requestElectrumUtxos(senderBCHp2pkhwt, includeCashtokens: true);

      if (electrumUTXOs.isEmpty) {
        print("Zero UTXOs found");
        return false;
      }

      if (_ref.read(userProvider)!.mnemonic == null) electrumUTXOs = MemoBitcoinBase.removeSlpUtxos(electrumUTXOs);

      List<UtxoWithAddress> utxos = base.getSpecificTokenAndGeneralUtxos(electrumUTXOs, senderBCHp2pkhwt, bip44Sender, MemoBitcoinBase.tokenId);

      //TODO CHECK WHAT VALUE THE TOKEN UTXOS HAVE, DO THEY INFLUENCE TOTAL BALANCE?
      BigInt totalAmountInSatoshisAvailable = utxos.sumOfUtxosValue();
      if (totalAmountInSatoshisAvailable == BigInt.zero) {
        print("Zero UTXOs with that tokenId found");
        return false;
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

      base.broadcastTransaction(signedTx);
      return true;
    } catch (e) {
      Sentry.captureException(e);
      Sentry.logger.error("UNEXPECTED ERROR: BURN TOKEN: $e");
      print("UNEXPECTED ERROR: BURN TOKEN: $e");
      return false;
    }
  }
}
