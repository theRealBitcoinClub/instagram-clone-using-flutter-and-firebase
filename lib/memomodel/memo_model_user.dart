import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:mahakka/memobase/memo_accountant.dart';
import 'package:mahakka/memobase/memo_verifier.dart';
import 'package:mahakka/memomodel/memo_model_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memobase/memo_bitcoin_base.dart';

//TODO tips go partially to app and creator on default, if user has registered on the app,
// otherwise it all goes to the app to pay for marketing to get users on the app
enum TipReceiver { app, creator, both }

//TODO User can choose four levels of support, that is displayed and can be filtered for by other users
enum TipAmount { zero, maintenance, growth, moon }

class MemoModelUser {
  static MemoModelUser? _user;
  TipReceiver _tipReceiver = TipReceiver.both;
  TipAmount _tipAmount = TipAmount.zero;
  String mnemonic;
  String _bchAddressCashtokenAware = "";
  String _legacyAddressMemoBch = "";
  String _legacyAddressMemoBchAsCashaddress = "";
  String _legacyAddressMemoSlp = "";
  ECPrivate? _privateKeyBchCashtoken;
  ECPrivate? _privateKeyLegacy;
  ECPrivate? _privateKeyLegacySlp;
  String? _wifBchCashtoken;
  String? _wifLegacy;
  MemoModelCreator? creator;
  String balanceCashtokensDevPath145 = "?";
  String balanceBchDevPath145 = "?";
  String balanceBchDevPath0Memo = "?";

  MemoModelUser({required this.mnemonic, this.creator});

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

  String get profileIdMemoSlp {
    return legacyAddressMemoSlp;
  }

  String get wifLegacy {
    _wifLegacy = _wifLegacy ?? _pkLegacy.toWif();
    return _wifLegacy!;
  }

  String get wifBchCashtoken {
    _wifBchCashtoken = _wifBchCashtoken ?? _pkBchCashtoken.toWif();
    return _wifBchCashtoken!;
  }

  String get legacyAddressMemoSlp {
    if (_legacyAddressMemoSlp.isEmpty) {
      _legacyAddressMemoSlp = _pkLegacySlp.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    //TODO save it in regards of mnemonic, add mnemonic hash to key
    return _legacyAddressMemoSlp;
  }

  String get legacyAddressMemoBchAsCashaddress {
    if (_legacyAddressMemoBchAsCashaddress.isEmpty) {
      _legacyAddressMemoBchAsCashaddress = _pkLegacy.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddressMemoBchAsCashaddress;
  }

  String get legacyAddressMemoBch {
    if (_legacyAddressMemoBch.isEmpty) {
      _legacyAddressMemoBch = _pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddressMemoBch;
  }

  ECPrivate get _pkLegacySlp {
    _privateKeyLegacySlp =
        _privateKeyLegacySlp ?? MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoSlp);
    return _privateKeyLegacySlp!;
  }

  ECPrivate get _pkLegacy {
    _privateKeyLegacy =
        _privateKeyLegacy ?? MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    return _privateKeyLegacy!;
  }

  ECPrivate get _pkBchCashtoken {
    _privateKeyBchCashtoken =
        _privateKeyBchCashtoken ??
        MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);
    return _privateKeyBchCashtoken!;
  }

  // String get bchAddressCashtokenAware {
  //   if (_bchAddressCashtokenAware.isEmpty) {
  //     _bchAddressCashtokenAware = _pkBchCashtoken.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
  //   }
  //   //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
  //   return _bchAddressCashtokenAware;
  // }

  String get bchAddressCashtokenAwareCtFormat {
    if (_bchAddressCashtokenAware.isEmpty) {
      final p2pkhWt = P2pkhAddress.fromHash160(
        addrHash: _pkBchCashtoken.getPublic().toHash160Hex(),
        type: P2pkhAddressType.p2pkhwt,
      );
      _bchAddressCashtokenAware = p2pkhWt.toAddress(BitcoinCashNetwork.mainnet);
    }

    return _bchAddressCashtokenAware;

    /// Output
    /// bitcoincash:zrpl3edslpz452czc2wyfz992qncyzdkdyvc8vzuev
  }

  static Future<MemoModelUser> getUser({MemoModelCreator? creator}) async {
    if (_user == null) {
      String? mne = await SharedPreferencesAsync().getString("mnemonic");
      _user = MemoModelUser(mnemonic: mne ?? "", creator: creator);
    } else {
      _user!.creator = creator;
    }
    return _user!;
  }

  String profileImage() {
    return "https://memo.cash/img/profilepics/${legacyAddressMemoBch}-128x128.jpg";
  }

  int get tipAmount {
    //TODO SAVE AND LOAD FROM SHAREDPREFS
    switch (_tipAmount) {
      case TipAmount.zero:
        return 0;
      case TipAmount.maintenance:
        return 1111;
      case TipAmount.growth:
        return 22222;
      case TipAmount.moon:
        return 333333;
    }
  }

  TipReceiver get tipReceiver {
    //TODO SAVE AND LOAD FROM SHAREDPREFS
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
