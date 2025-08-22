import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memoscraper/memo_bitcoin_base.dart';

class MemoModelUser {
  String mnemonic;
  String _bchAddressCashtokenAware = "";
  String _legacyAddressMemo1Bch = "";
  ECPrivate? _privateKeyBchCashtoken;
  ECPrivate? _privateKeyLegacy;
  String? _wifBchCashtoken;
  String? _wifLegacy;
  MemoModelCreator? creator;

  MemoModelUser({
    required this.mnemonic,
    this.creator
  });
  
  String get wifLegacy {
    _wifLegacy = _wifLegacy ?? _pkLegacy.toWif();
    return _wifLegacy!;
  }

  String get wifBchCashtoken {
    _wifBchCashtoken = _wifBchCashtoken ?? _pkBchCashtoken.toWif();
    return _wifBchCashtoken!;
  }

  String get legacyAddressMemo1Bch {
    if (_legacyAddressMemo1Bch.isEmpty) {
      _legacyAddressMemo1Bch = _pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddressMemo1Bch;
  }

  ECPrivate get _pkLegacy {
    _privateKeyLegacy = _privateKeyLegacy ?? MemoBitcoinBase().createBip44PrivateKey(mnemonic, "m/44'/0'/0'/0/0");
    return _privateKeyLegacy!;
  }

  ECPrivate get _pkBchCashtoken {
    _privateKeyBchCashtoken = _privateKeyBchCashtoken ?? MemoBitcoinBase().createBip44PrivateKey(mnemonic, "m/44'/145'/0'/0/0");
    return _privateKeyBchCashtoken!;
  }

  String get bchAddressCashtokenAware {
    if (_bchAddressCashtokenAware.isEmpty) {
      _bchAddressCashtokenAware = _pkBchCashtoken.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _bchAddressCashtokenAware;
  }

  //TODO generate creator profile id from mnemonic

  static Future<MemoModelUser> createDummy({MemoModelCreator? creator}) async {
    String? mne = await SharedPreferencesAsync().getString("mnemonic");
    return MemoModelUser(mnemonic: mne ?? "", creator: creator);
  }
}