import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memobase/memo_accountant.dart';
import 'package:instagram_clone1/memobase/memo_bitcoin_base.dart';

import '../memomodel/memo_tip.dart';
import 'memo_code.dart';
import 'memo_transaction_builder.dart';

const int hash160DigestLength = QuickCrypto.hash160DigestSize;

class MemoPublisher {
  void testMemoSend() async {
    // print("\n\n" + await doMemoAction("PostMessage", MemoCode.profileMessage,""));
    // print("\n${await doMemoAction("IMG1 https://imgur.com/eIEjcUe", MemoCode.ProfileMessage,"")}");
    // print("\n${await doMemoAction("IMG2 https://i.imgur.com/eIEjcUe.jpeg", MemoCode.ProfileMessage,"")}");
    // print("\n${await doMemoAction("YT1 https://youtu.be/dQw4w9WgXcQ", MemoCode.ProfileMessage,"")}");
    // print("\n${await doMemoAction("OD1 https://odysee.com/@BitcoinMap:9/HijackingBitcoin:73", MemoCode.ProfileMessage,"")}");
    // print("\n${await doMemoAction("OD2 https://odysee.com/%24/embed/%40BitcoinMap%3A9%2FHijackingBitcoin%3A73?r=9n3v5rTk1CsSYkoqD3gER4SHNML8SxwH", MemoCode.ProfileMessage,"")}");
    //
    // print("\n${await doMemoAction("YT2 https://www.youtube.com/watch?v=dQw4w9WgXcQ", MemoCode.ProfileMessage,"")}");
    // sleep(Duration(seconds: 1));
    // var other = await doMemoAction("reply", MemoCode.postReply,
    //     MemoTransformation.reOrderTxHash("ba832cad4e4f45b9158811e2914bc57b89fd100c4d3eb6f871a757d0b14db3f3"));
    //
    // print("\n" + other);
    var other = await doMemoAction(
      MemoBitcoinBase.reOrderTxHash("bad2095d2f5e177ffd4da96fd0220ebcb8de7b9e1cffac9d0c7667b403204072"),
      MemoCode.postLike,
    );
    print("\n" + other.toString());
    // sleep(Duration(seconds: 1));
    // other = await doMemoAction("Keloke", MemoCode.ProfileName,"");
    // print("\n" + other);
    // sleep(Duration(seconds: 1));
    // other = await doMemoAction("Ke paso en Barrio Bitcoin", MemoCode.ProfileText,"");
    // print("\n" + other);
    // sleep(Duration(seconds: 1));
    // other = await doMemoAction("Bitcoin+Map", MemoCode.TopicFollow,"");
    // print("\n" + other);
    // sleep(Duration(seconds: 1));
    // other = await doMemoAction("Escuchame wow increible no me digas ke veina naguara vergacion", MemoCode.TopicMessage, "zxcvsadf");
    // print("\n" + other);
    // sleep(Duration(seconds: 1));
    // other = await doMemoAction("Bitcoin+Map", MemoCode.TopicFollowUndo,"");
    // print("\n" + other);
    // sleep(Duration(seconds: 1));
    // var other = await doMemoAction("17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ", MemoCode.MuteUser,"");
    // print("\n$other");
    // sleep(Duration(seconds: 1));
    // other = await doMemoAction("17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ", MemoCode.MuteUndo,"");
    // print("\n" + other);
  }

  Future<MemoAccountantResponse> doMemoAction(
    String memoMessage,
    MemoCode memoAction, {
    String topic = "",
    ECPrivate? pk,
    String? wif,
    MemoTip? tip,
  }) async {
    print("\n${memoAction.opCode}\n${memoAction.name}");
    var base = await MemoBitcoinBase.create();

    const network = BitcoinCashNetwork.mainnet;

    final privateKey = pk ?? (ECPrivate.fromWif(wif ?? "xxx", netVersion: network.wifNetVer));

    final publicKey = privateKey.getPublic();

    final BitcoinCashAddress p2pkhAddress = BitcoinCashAddress.fromBaseAddress(publicKey.toAddress());

    print("https://bchblockexplorer.com/address/${p2pkhAddress.address}");

    final List<ElectrumUtxo> elctrumUtxos = await base.requestElectrumUtxos(p2pkhAddress);

    if (elctrumUtxos.isEmpty) {
      return MemoAccountantResponse.noUtxo;
    }

    List<UtxoWithAddress> utxos = addUtxoAddressDetailsAsOwnerDetailsToCreateUtxoWithAddressModelList(
      elctrumUtxos,
      p2pkhAddress,
      publicKey,
    );

    utxos = removeSlpUtxos(utxos);

    final BigInt walletBalance = utxos.sumOfUtxosValue();

    if (walletBalance == BigInt.zero) {
      return MemoAccountantResponse.lowBalance;
    }

    final BigInt fee = BtcUtils.toSatoshi("0.000007");
    // final BigInt tip = BigInt.parse(tipAmount);
    final BtcTransaction tx = createTransaction(
      p2pkhAddress,
      walletBalance,
      fee,
      network,
      utxos,
      memoMessage,
      memoAction,
      privateKey,
      memoTopic: topic,
      memoTip: tip,
    );

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
    BitcoinCashAddress p2pkhAddress,
    BigInt walletBalance,
    BigInt fee,
    BitcoinCashNetwork network,
    List<UtxoWithAddress> utxos,
    String memoMessage,
    MemoCode memoAction,
    ECPrivate privateKey, {
    String memoTopic = "",
    MemoTip? memoTip,
  }) {
    final MemoTransactionBuilder txBuilder = createTransactionBuilder(
      p2pkhAddress,
      walletBalance,
      fee,
      network,
      utxos,
      memoMessage,
      memoAction,
      memoTopic,
      memoTip,
    );
    final tx = txBuilder.buildTransaction((trDigest, utxo, publicKey, sighash) {
      return privateKey.signECDSA(trDigest, sighash: sighash);
    });
    return tx;
  }

  MemoTransactionBuilder createTransactionBuilder(
    BitcoinCashAddress p2pkhAddress,
    BigInt walletBalance,
    BigInt fee,
    BitcoinCashNetwork network,
    List<UtxoWithAddress> utxos,
    String memoMessage,
    MemoCode memoAction,
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

  List<UtxoWithAddress> addUtxoAddressDetailsAsOwnerDetailsToCreateUtxoWithAddressModelList(
    List<ElectrumUtxo> elctrumUtxos,
    BitcoinCashAddress p2pkhAddress,
    ECPublic publicKey,
  ) {
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
