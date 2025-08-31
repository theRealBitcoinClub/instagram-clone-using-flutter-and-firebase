import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/model/memo_tip.dart';

import '../../provider/electrum_provider.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

const int hash160DigestLength = QuickCrypto.hash160DigestSize;
const network = BitcoinCashNetwork.mainnet;

class MemoPublisher {
  // Add a final Ref field to store the Riverpod ref.
  final Ref ref;
  BigInt fee = BtcUtils.toSatoshi("0.000007");
  late String memoMessage;
  late MemoCode memoAction;
  ECPrivate? pk;
  String? wif;
  late BitcoinCashAddress p2pkhAddress;
  late ECPublic publicKey;
  late ECPrivate privateKey;

  // Add the Ref to the constructor.
  MemoPublisher._create(this.ref, this.memoMessage, this.memoAction, {this.pk, this.wif}) {
    privateKey = pk ?? (ECPrivate.fromWif(wif ?? "xxx", netVersion: network.wifNetVer));
    publicKey = privateKey.getPublic();
    p2pkhAddress = BitcoinCashAddress.fromBaseAddress(publicKey.toAddress());
  }

  // The create method must now accept a Ref and pass it to the private constructor.
  static Future<MemoPublisher> create(Ref ref, String msg, MemoCode code, {ECPrivate? pk, String? wif}) async {
    MemoPublisher publisher = MemoPublisher._create(ref, msg, code, pk: pk, wif: wif);
    // Remove the redundant _initAsync call. The provider is ready to use.
    return publisher;
  }

  // This method no longer needs to be async.
  // _initAsync() async {
  //   base = await MemoBitcoinBase.create();
  // }

  Future<MemoAccountantResponse> doPublish({String topic = "", MemoTip? tip}) async {
    // Get the shared instance from the provider using the stored ref.
    final MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);

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
    try {
      await base.broadcastTransaction(tx);
    } catch (e) {
      return MemoAccountantResponse.dust;
    }
    return MemoAccountantResponse.yes;
  }

  // Rest of your methods remain the same.
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
