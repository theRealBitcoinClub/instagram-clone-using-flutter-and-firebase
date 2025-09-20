import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

part 'memo_model_user.g.dart';

@JsonEnum()
enum TipReceiver {
  creator('100% to Creator', 0.0, 1.0),
  burn20Creator80('20% Burned, 80% Creator', 0.2, 0.8),
  burn40Creator60('40% Burned, 60% Creator', 0.4, 0.6),
  both('50% Burned, 50% Creator', 0.5, 0.5),
  burn60Creator40('60% Burned, 40% Creator', 0.6, 0.4),
  burn80Creator20('80% Burned, 20% Creator', 0.8, 0.2),
  app('100% Burned', 1.0, 0.0);

  final String displayName;
  final double burnPercentage;
  final double creatorPercentage;

  const TipReceiver(this.displayName, this.burnPercentage, this.creatorPercentage);

  (int burnAmount, int creatorAmount) calculateAmounts(int totalAmount) {
    return ((totalAmount * burnPercentage).round(), (totalAmount * creatorPercentage).round());
  }

  bool get isValidPercentages {
    return (burnPercentage + creatorPercentage - 1.0).abs() < 0.0001;
  }

  String get percentagesString {
    return '${(burnPercentage * 100).round()}% Burned, ${(creatorPercentage * 100).round()}% Creator';
  }
}

@JsonEnum()
enum TipAmount {
  @JsonValue(4567)
  survival(4567),
  @JsonValue(7777)
  nice(7777),
  @JsonValue(9999)
  fren(9999),
  @JsonValue(12345)
  wagmi(12345),
  @JsonValue(21212)
  moon(21212),
  @JsonValue(42069)
  sohigh(42069);

  const TipAmount(this.value);
  final int value;
}

@JsonSerializable()
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
  @JsonKey(includeFromJson: false, includeToJson: false)
  TipAmount? temporaryTipAmount;
  @JsonKey(includeFromJson: false, includeToJson: false)
  TipReceiver? temporaryTipReceiver;

  // Ignored fields
  @JsonKey(includeFromJson: false, includeToJson: false)
  late ECPrivate pkBchCashtoken;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late ECPrivate pkLegacy;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late MemoModelCreator creator;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late String mnemonic;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late String wifBchCashtoken;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late String wifLegacy;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool hasInit = false;

  @JsonKey(defaultValue: [])
  List<String> ipfsCids;

  MemoModelUser({
    required this.id,
    required this.bchAddressCashtokenAware,
    required this.legacyAddressMemoBch,
    required this.legacyAddressMemoBchAsCashaddress,
    required TipReceiver tipReceiver,
    required TipAmount tipAmount,
    List<String>? ipfsCids,
  }) : _tipReceiver = tipReceiver,
       _tipAmount = tipAmount,
       ipfsCids = ipfsCids ?? [];

  factory MemoModelUser.fromMnemonic({required String mnemonic}) {
    if (MemoVerifier(mnemonic).verifyMnemonic() != "success") {
      throw ArgumentError('Invalid mnemonic.');
    }

    final pkLegacy = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    final pkBchCashtoken = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);

    final p2pkhWt = P2pkhAddress.fromHash160(addrHash: pkBchCashtoken.getPublic().toHash160Hex(), type: P2pkhAddressType.p2pkhwt);
    final bchCashtokenAware = p2pkhWt.toAddress(BitcoinCashNetwork.mainnet);
    final legacyAddress = pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    final legacyAddressAsCash = pkLegacy.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    final userId = legacyAddress;

    final user = MemoModelUser(
      id: userId,
      bchAddressCashtokenAware: bchCashtokenAware,
      legacyAddressMemoBch: legacyAddress,
      legacyAddressMemoBchAsCashaddress: legacyAddressAsCash,
      tipReceiver: TipReceiver.both,
      tipAmount: TipAmount.survival,
      ipfsCids: [],
    );

    user.mnemonic = mnemonic;
    user.pkLegacy = pkLegacy;
    user.pkBchCashtoken = pkBchCashtoken;
    user.wifLegacy = pkLegacy.toWif();
    user.wifBchCashtoken = pkBchCashtoken.toWif();
    user.hasInit = true;
    user.creator = MemoModelCreator(id: userId, name: userId, hasRegisteredAsUser: true);

    return user;
  }

  factory MemoModelUser.fromJson(Map<String, dynamic> json) => _$MemoModelUserFromJson(json);

  Map<String, dynamic> toJson() => _$MemoModelUserToJson(this);

  String get profileIdMemoBch {
    return legacyAddressMemoBch;
  }

  int get tipAmount {
    return temporaryTipAmount != null ? temporaryTipAmount!.value : _tipAmount.value;
  }

  TipAmount get tipAmountEnum {
    return temporaryTipAmount ?? _tipAmount;
  }

  TipReceiver get tipReceiver {
    return temporaryTipReceiver != null ? temporaryTipReceiver! : _tipReceiver;
  }

  MemoModelUser._({
    required this.mnemonic,
    required this.id,
    required this.bchAddressCashtokenAware,
    required this.legacyAddressMemoBch,
    required this.legacyAddressMemoBchAsCashaddress,
    TipReceiver tipReceiver = TipReceiver.both,
    TipAmount tipAmount = TipAmount.survival,
    required this.pkBchCashtoken,
    required this.pkLegacy,
    required this.creator,
    required this.wifBchCashtoken,
    required this.wifLegacy,
    required this.hasInit,
    required this.ipfsCids,
  }) : _tipReceiver = tipReceiver,
       _tipAmount = tipAmount;

  MemoModelUser copyWith({
    String? id,
    String? bchAddressCashtokenAware,
    String? legacyAddressMemoBch,
    String? legacyAddressMemoBchAsCashaddress,
    TipReceiver? tipReceiver,
    TipAmount? tipAmount,
    TipAmount? temporaryTipAmount,
    TipReceiver? temporaryTipReceiver,
    ECPrivate? pkBchCashtoken,
    ECPrivate? pkLegacy,
    MemoModelCreator? creator,
    String? mnemonic,
    String? wifBchCashtoken,
    String? wifLegacy,
    bool? hasInit,
    List<String>? ipfsCids,
  }) {
    return MemoModelUser._(
        id: id ?? this.id,
        bchAddressCashtokenAware: bchAddressCashtokenAware ?? this.bchAddressCashtokenAware,
        legacyAddressMemoBch: legacyAddressMemoBch ?? this.legacyAddressMemoBch,
        legacyAddressMemoBchAsCashaddress: legacyAddressMemoBchAsCashaddress ?? this.legacyAddressMemoBchAsCashaddress,
        tipReceiver: tipReceiver ?? this._tipReceiver,
        tipAmount: tipAmount ?? this._tipAmount,
        pkBchCashtoken: pkBchCashtoken ?? this.pkBchCashtoken,
        pkLegacy: pkLegacy ?? this.pkLegacy,
        creator: creator ?? this.creator,
        mnemonic: mnemonic ?? this.mnemonic,
        wifBchCashtoken: wifBchCashtoken ?? this.wifBchCashtoken,
        wifLegacy: wifLegacy ?? this.wifLegacy,
        hasInit: hasInit ?? this.hasInit,
        ipfsCids: ipfsCids ?? this.ipfsCids,
      )
      ..temporaryTipAmount = temporaryTipAmount ?? this.temporaryTipAmount
      ..temporaryTipReceiver = temporaryTipReceiver ?? this.temporaryTipReceiver;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MemoModelUser) return false;

    return id == other.id &&
        bchAddressCashtokenAware == other.bchAddressCashtokenAware &&
        legacyAddressMemoBch == other.legacyAddressMemoBch &&
        legacyAddressMemoBchAsCashaddress == other.legacyAddressMemoBchAsCashaddress &&
        _tipReceiver == other._tipReceiver &&
        _tipAmount == other._tipAmount &&
        temporaryTipAmount == other.temporaryTipAmount &&
        temporaryTipReceiver == other.temporaryTipReceiver &&
        creator == other.creator &&
        hasInit == other.hasInit &&
        ipfsCids.length == other.ipfsCids.length &&
        ipfsCids.every((url) => other.ipfsCids.contains(url));
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bchAddressCashtokenAware,
      legacyAddressMemoBch,
      legacyAddressMemoBchAsCashaddress,
      _tipReceiver,
      _tipAmount,
      temporaryTipAmount,
      temporaryTipReceiver,
      creator,
      hasInit,
      Object.hashAll(ipfsCids),
    );
  }

  void addIpfsUrl(String url) {
    if (!ipfsCids.contains(url)) {
      ipfsCids.add(url);
    }
  }

  void removeIpfsUrl(String url) {
    ipfsCids.remove(url);
  }

  void clearipfsCids() {
    ipfsCids.clear();
  }
}
