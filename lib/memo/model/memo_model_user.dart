import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/electrum_provider.dart';

import '../firebase/user_service.dart';

part 'memo_model_user.g.dart'; // Add this line

@JsonEnum()
enum TipReceiver { app, creator, both }

@JsonEnum()
enum TipAmount {
  @JsonValue(0)
  zero(0),
  @JsonValue(1)
  maintenance(1111),
  @JsonValue(2)
  growth(22222),
  @JsonValue(3)
  moon(333333);

  const TipAmount(this.value);
  final int value;
}

@JsonSerializable() // Add this annotation
class MemoModelUser {
  String id;
  @JsonKey(name: 'bchAddressCashTokenAware')
  String bchAddressCashtokenAware;
  @JsonKey(name: 'legacyAddressMemoBch')
  String legacyAddressMemoBch;
  @JsonKey(name: 'legacyAddressMemoBchAsCashaddress')
  String legacyAddressMemoBchAsCashaddress;

  // Fields to be serialized
  TipReceiver _tipReceiver;
  TipAmount _tipAmount;

  @JsonKey(ignore: true)
  final UserService _userService = UserService();
  // Ignored fields
  @JsonKey(ignore: true)
  late ECPrivate pkBchCashtoken;
  @JsonKey(ignore: true)
  late ECPrivate pkLegacy;
  @JsonKey(ignore: true)
  late MemoModelCreator creator;
  @JsonKey(ignore: true)
  late String mnemonic;
  @JsonKey(ignore: true)
  late String wifBchCashtoken;
  @JsonKey(ignore: true)
  late String wifLegacy;
  @JsonKey(ignore: true)
  String balanceCashtokensDevPath145 = "?";
  @JsonKey(ignore: true)
  String balanceBchDevPath145 = "?";
  @JsonKey(ignore: true)
  String balanceBchDevPath0Memo = "?";
  @JsonKey(ignore: true)
  bool hasInit = false;

  MemoModelUser({
    required this.id,
    required this.bchAddressCashtokenAware,
    required this.legacyAddressMemoBch,
    required this.legacyAddressMemoBchAsCashaddress,
    required TipReceiver tipReceiver,
    required TipAmount tipAmount,
  }) : _tipReceiver = tipReceiver,
       _tipAmount = tipAmount;

  factory MemoModelUser.fromMnemonic({required String mnemonic}) {
    // 1. Verify the mnemonic
    if (MemoVerifier(mnemonic).verifyMnemonic() != "success") {
      throw ArgumentError('Invalid mnemonic.');
    }

    // 2. Derive private keys
    final pkLegacy = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    final pkBchCashtoken = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);

    // 3. Derive addresses and ID
    final p2pkhWt = P2pkhAddress.fromHash160(addrHash: pkBchCashtoken.getPublic().toHash160Hex(), type: P2pkhAddressType.p2pkhwt);
    final bchCashtokenAware = p2pkhWt.toAddress(BitcoinCashNetwork.mainnet);
    final legacyAddress = pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    final legacyAddressAsCash = pkLegacy.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    final userId = legacyAddress;

    // ECPublic pubKey = pkLegacy.getPublic();
    // P2pkhAddress legacy = P2pkhAddress.fromAddress(address: pubKey.toAddress().toString(), network: BitcoinNetwork.mainnet);
    // String addr = legacyToBchAddress(addressProgram: legacy.addressProgram, network: network, type: P2pkhAddressType.p2pkh);
    // BitcoinCashAddress bchAdd = BitcoinCashAddress.fromBaseAddress(legacy);

    // 4. Return a new instance using the main constructor
    final user = MemoModelUser(
      id: userId,
      bchAddressCashtokenAware: bchCashtokenAware,
      legacyAddressMemoBch: legacyAddress,
      legacyAddressMemoBchAsCashaddress: legacyAddressAsCash,
      tipReceiver: TipReceiver.both, // Default value
      tipAmount: TipAmount.zero, // Default value
    );

    // 5. Initialize the rest of the instance fields
    user.mnemonic = mnemonic;
    user.pkLegacy = pkLegacy;
    user.pkBchCashtoken = pkBchCashtoken;
    user.wifLegacy = pkLegacy.toWif();
    user.wifBchCashtoken = pkBchCashtoken.toWif();
    user.hasInit = true;
    user.creator = MemoModelCreator(id: userId);

    return user;
  }

  factory MemoModelUser.fromJson(Map<String, dynamic> json) => _$MemoModelUserFromJson(json);

  Map<String, dynamic> toJson() => _$MemoModelUserToJson(this);

  bool init({required String mnemonic}) {
    if (hasInit) return true;
    this.mnemonic = mnemonic;
    if (MemoVerifier(mnemonic).verifyMnemonic() != "success") return false;

    pkLegacy = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    pkBchCashtoken = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);

    final p2pkhWt = P2pkhAddress.fromHash160(addrHash: pkBchCashtoken.getPublic().toHash160Hex(), type: P2pkhAddressType.p2pkhwt);
    bchAddressCashtokenAware = p2pkhWt.toAddress(BitcoinCashNetwork.mainnet);

    legacyAddressMemoBch = pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    id = legacyAddressMemoBch;
    creator = MemoModelCreator(id: id);
    legacyAddressMemoBchAsCashaddress = pkLegacy.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);

    wifLegacy = pkLegacy.toWif();
    wifBchCashtoken = pkBchCashtoken.toWif();
    hasInit = true;
    return true;
  }

  Future<void> saveToFirebase() async {
    await _userService.saveUser(this);
  }

  Future<String> refreshBalanceDevPath0(Ref ref) async {
    MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    // MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressLegacy(pkLegacy);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);

    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress);
    if (utxos.isEmpty) {
      balanceBchDevPath0Memo = "noutxo";
      // return "noutxos";
    }
    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, pkLegacy);
    BigInt totalAmountInSatoshisAvailable = utxosWA.sumOfUtxosValue();
    if (totalAmountInSatoshisAvailable == BigInt.zero) {
      balanceBchDevPath0Memo = "noMemo";
      // return "nofunds";
    }
    balanceBchDevPath0Memo = totalAmountInSatoshisAvailable.toString();
    // return "success";
    return balanceBchDevPath0Memo;
  }

  Future<String> refreshBalanceDevPath145(Ref ref) async {
    MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    P2pkhAddress p2pkhwt = base.createAddressP2PKHWT(pkBchCashtoken);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress);
    if (utxos.isEmpty) {
      balanceBchDevPath145 = "noutxo";
      // return "noutxos";
    }
    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, pkBchCashtoken);
    BigInt totalAmountInSatoshisAvailable = utxosWA.sumOfUtxosValue();
    if (totalAmountInSatoshisAvailable == BigInt.zero) {
      balanceBchDevPath145 = "noBch";
      // return "nofunds";
    }
    balanceBchDevPath145 = totalAmountInSatoshisAvailable.toString();
    return balanceBchDevPath145;
  }

  Future<String> refreshBalanceTokens(Ref ref) async {
    MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    P2pkhAddress p2pkhwt = base.createAddressP2PKHWT(pkBchCashtoken);
    p2pkhwt.toAddress(BitcoinCashNetwork.mainnet);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress, includeCashtokens: true);
    if (utxos.isEmpty) {
      balanceCashtokensDevPath145 = "notokens";
      // return "noutxos";
    }
    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, pkBchCashtoken);
    BigInt totalAmountOfTokenAvailable = base.calculateTotalAmountOfThatToken(utxosWA, MemoBitcoinBase.tokenId);
    balanceCashtokensDevPath145 = totalAmountOfTokenAvailable.toString();
    return balanceCashtokensDevPath145;
  }

  String get profileIdMemoBch {
    return legacyAddressMemoBch;
  }

  int get tipAmount {
    return _tipAmount.value;
  }

  TipReceiver get tipReceiver {
    return _tipReceiver;
  }

  //THESE ARE IN USER REPOSITORY NOW
  // Future<dynamic> profileSetName(String name) async {
  //   MemoVerificationResponse response = MemoVerifier(name).verifyUserName();
  //   if (response != MemoVerificationResponse.valid) return response;
  //   return await MemoAccountant(this).profileSetName(name);
  // }
  //
  // Future<dynamic> profileSetText(String text) async {
  //   MemoVerificationResponse response = MemoVerifier(text).verifyProfileText();
  //   if (response != MemoVerificationResponse.valid) return response;
  //   return await MemoAccountant(this).profileSetText(text);
  // }
  //
  // Future<dynamic> profileSetAvatar(String imgur) async {
  //   MemoVerificationResponse response = MemoVerifier(imgur).verifyImgur();
  //   if (response != MemoVerificationResponse.valid) return response;
  //   return await MemoAccountant(this).profileSetAvatar(imgur);
  // }

  MemoModelUser._({
    required this.mnemonic,
    required this.id,
    required this.bchAddressCashtokenAware,
    required this.legacyAddressMemoBch,
    required this.legacyAddressMemoBchAsCashaddress,
    TipReceiver tipReceiver = TipReceiver.both,
    TipAmount tipAmount = TipAmount.zero,
    // Add all ignored fields here as optional parameters
    this.balanceCashtokensDevPath145 = "?",
    this.balanceBchDevPath145 = "?",
    this.balanceBchDevPath0Memo = "?",
    required this.pkBchCashtoken,
    required this.pkLegacy,
    required this.creator,
    required this.wifBchCashtoken,
    required this.wifLegacy,
    required this.hasInit,
  }) : _tipReceiver = tipReceiver,
       _tipAmount = tipAmount;

  // The copyWith method
  MemoModelUser copyWith({
    String? id,
    String? bchAddressCashtokenAware,
    String? legacyAddressMemoBch,
    String? legacyAddressMemoBchAsCashaddress,
    TipReceiver? tipReceiver,
    TipAmount? tipAmount,
    String? balanceCashtokensDevPath145,
    String? balanceBchDevPath145,
    String? balanceBchDevPath0Memo,
    ECPrivate? pkBchCashtoken,
    ECPrivate? pkLegacy,
    MemoModelCreator? creator,
    String? mnemonic,
    String? wifBchCashtoken,
    String? wifLegacy,
    bool? hasInit,
  }) {
    return MemoModelUser._(
      id: id ?? this.id,
      bchAddressCashtokenAware: bchAddressCashtokenAware ?? this.bchAddressCashtokenAware,
      legacyAddressMemoBch: legacyAddressMemoBch ?? this.legacyAddressMemoBch,
      legacyAddressMemoBchAsCashaddress: legacyAddressMemoBchAsCashaddress ?? this.legacyAddressMemoBchAsCashaddress,
      tipReceiver: tipReceiver ?? this._tipReceiver,
      tipAmount: tipAmount ?? this._tipAmount,
      balanceCashtokensDevPath145: balanceCashtokensDevPath145 ?? this.balanceCashtokensDevPath145,
      balanceBchDevPath145: balanceBchDevPath145 ?? this.balanceBchDevPath145,
      balanceBchDevPath0Memo: balanceBchDevPath0Memo ?? this.balanceBchDevPath0Memo,
      pkBchCashtoken: pkBchCashtoken ?? this.pkBchCashtoken,
      pkLegacy: pkLegacy ?? this.pkLegacy,
      creator: creator ?? this.creator,
      mnemonic: mnemonic ?? this.mnemonic,
      wifBchCashtoken: wifBchCashtoken ?? this.wifBchCashtoken,
      wifLegacy: wifLegacy ?? this.wifLegacy,
      hasInit: hasInit ?? this.hasInit,
    );
  }
}
