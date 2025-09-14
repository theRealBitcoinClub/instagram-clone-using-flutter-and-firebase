import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

part 'memo_model_user.g.dart'; // Add this line

// @JsonEnum()
// enum TipReceiver { app, creator, both, burn20Creator80, burn40Creator60, burn60Creator40, burn80Creator20 }

@JsonEnum()
enum TipReceiver {
  app('100% Burned', 1.0, 0.0),
  creator('100% to Creator', 0.0, 1.0),
  both('50% Burned, 50% Creator', 0.5, 0.5),
  burn20Creator80('20% Burned, 80% Creator', 0.2, 0.8),
  burn40Creator60('40% Burned, 60% Creator', 0.4, 0.6),
  burn60Creator40('60% Burned, 40% Creator', 0.6, 0.4),
  burn80Creator20('80% Burned, 20% Creator', 0.8, 0.2);

  //TODO remove displayname and use percentagesString everywhere
  final String displayName;
  final double burnPercentage;
  final double creatorPercentage;

  const TipReceiver(this.displayName, this.burnPercentage, this.creatorPercentage);

  // Helper method to calculate amounts
  (int burnAmount, int creatorAmount) calculateAmounts(int totalAmount) {
    return ((totalAmount * burnPercentage).round(), (totalAmount * creatorPercentage).round());
  }

  // Helper method to verify percentages sum to 1.0
  bool get isValidPercentages {
    return (burnPercentage + creatorPercentage - 1.0).abs() < 0.0001;
  }

  // Get percentages as a formatted string
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
  @JsonKey(includeFromJson: false, includeToJson: false)
  TipAmount? temporaryTipAmount;

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
  // @JsonKey(includeFromJson: false, includeToJson: false)
  // String balanceCashtokensDevPath145 = "?";
  // @JsonKey(includeFromJson: false, includeToJson: false)
  // String balanceBchDevPath145 = "?";
  // @JsonKey(includeFromJson: false, includeToJson: false)
  // String balanceBchDevPath0Memo = "?";
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      tipAmount: TipAmount.survival, // Default value
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

  String get profileIdMemoBch {
    return legacyAddressMemoBch;
  }

  int get tipAmount {
    return _tipAmount.value;
  }

  TipAmount get tipAmountEnum {
    return _tipAmount;
  }

  TipReceiver get tipReceiver {
    return _tipReceiver;
  }

  MemoModelUser._({
    required this.mnemonic,
    required this.id,
    required this.bchAddressCashtokenAware,
    required this.legacyAddressMemoBch,
    required this.legacyAddressMemoBchAsCashaddress,
    TipReceiver tipReceiver = TipReceiver.both,
    TipAmount tipAmount = TipAmount.survival,
    // Add all ignored fields here as optional parameters
    // this.balanceCashtokensDevPath145 = "?",
    // this.balanceBchDevPath145 = "?",
    // this.balanceBchDevPath0Memo = "?",
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
      // balanceCashtokensDevPath145: balanceCashtokensDevPath145 ?? this.balanceCashtokensDevPath145,
      // balanceBchDevPath145: balanceBchDevPath145 ?? this.balanceBchDevPath145,
      // balanceBchDevPath0Memo: balanceBchDevPath0Memo ?? this.balanceBchDevPath0Memo,
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
