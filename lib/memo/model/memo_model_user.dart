import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

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
  late ECPrivate _pkBchCashtoken;
  @JsonKey(ignore: true)
  late ECPrivate _pkLegacy;
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
    user._pkLegacy = pkLegacy;
    user._pkBchCashtoken = pkBchCashtoken;
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

    _pkLegacy = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    _pkBchCashtoken = MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);

    final p2pkhWt = P2pkhAddress.fromHash160(addrHash: _pkBchCashtoken.getPublic().toHash160Hex(), type: P2pkhAddressType.p2pkhwt);
    bchAddressCashtokenAware = p2pkhWt.toAddress(BitcoinCashNetwork.mainnet);

    legacyAddressMemoBch = _pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    id = legacyAddressMemoBch;
    creator = MemoModelCreator(id: id);
    legacyAddressMemoBchAsCashaddress = _pkLegacy.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);

    wifLegacy = _pkLegacy.toWif();
    wifBchCashtoken = _pkBchCashtoken.toWif();
    hasInit = true;
    return true;
  }

  Future<void> saveToFirebase() async {
    await _userService.save(this, id);
  }

  Future<String> refreshBalanceDevPath0() async {
    MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressLegacy(_pkLegacy);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress);
    if (utxos.isEmpty) {
      balanceBchDevPath0Memo = "0";
      return "noutxos";
    }
    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, _pkLegacy);
    BigInt totalAmountInSatoshisAvailable = utxosWA.sumOfUtxosValue();
    if (totalAmountInSatoshisAvailable == BigInt.zero) {
      balanceBchDevPath0Memo = "0";
      return "nofunds";
    }
    balanceBchDevPath0Memo = totalAmountInSatoshisAvailable.toString();
    return "success";
  }

  Future<String> refreshBalanceDevPath145() async {
    MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressP2PKHWT(_pkBchCashtoken);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress);
    if (utxos.isEmpty) {
      balanceBchDevPath145 = "0";
      return "noutxos";
    }
    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, _pkBchCashtoken);
    BigInt totalAmountInSatoshisAvailable = utxosWA.sumOfUtxosValue();
    if (totalAmountInSatoshisAvailable == BigInt.zero) {
      balanceBchDevPath145 = "0";
      return "nofunds";
    }
    balanceBchDevPath145 = totalAmountInSatoshisAvailable.toString();
    return "success";
  }

  Future<String> refreshBalanceTokens() async {
    MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressP2PKHWT(_pkBchCashtoken);
    p2pkhwt.toAddress(BitcoinCashNetwork.mainnet);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress, includeCashtokens: true);
    if (utxos.isEmpty) {
      balanceCashtokensDevPath145 = "0";
      return "noutxos";
    }
    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, _pkBchCashtoken);
    BigInt totalAmountOfTokenAvailable = base.calculateTotalAmountOfThatToken(utxosWA, MemoBitcoinBase.tokenId);
    balanceCashtokensDevPath145 = totalAmountOfTokenAvailable.toString();
    return "success";
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

  Future<dynamic> profileSetName(String name) async {
    MemoVerificationResponse response = MemoVerifier(name).verifyUserName();
    if (response != MemoVerificationResponse.valid) return response;
    return await MemoAccountant(this).profileSetName(name);
  }

  Future<dynamic> profileSetText(String text) async {
    MemoVerificationResponse response = MemoVerifier(text).verifyProfileText();
    if (response != MemoVerificationResponse.valid) return response;
    return await MemoAccountant(this).profileSetText(text);
  }

  Future<dynamic> profileSetAvatar(String imgur) async {
    MemoVerificationResponse response = MemoVerifier(imgur).verifyImgur();
    if (response != MemoVerificationResponse.valid) return response;
    return await MemoAccountant(this).profileSetAvatar(imgur);
  }
}
