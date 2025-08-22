import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memoscraper/memo_bitcoin_base.dart';

class MemoModelUser {
  static MemoModelUser? dummy;
  String mnemonic;
  String _bchAddressCashtokenAware = "";
  String _legacyAddressMemoBch = "";
  String _legacyAddressMemoSlp = "";
  ECPrivate? _privateKeyBchCashtoken;
  ECPrivate? _privateKeyLegacy;
  ECPrivate? _privateKeyLegacySlp;
  String? _wifBchCashtoken;
  String? _wifLegacy;
  MemoModelCreator? creator;

  MemoModelUser({
    required this.mnemonic,
    this.creator
  });
  
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
      _legacyAddressMemoSlp = _pkLegacySlp
          .getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    //TODO save it in regards of mnemonic, add mnemonic hash to key
    return _legacyAddressMemoSlp;
  }

  String get legacyAddressMemoBch {
    if (_legacyAddressMemoBch.isEmpty) {
      _legacyAddressMemoBch = _pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddressMemoBch;
  }

  ECPrivate get _pkLegacySlp {
    _privateKeyLegacySlp = _privateKeyLegacySlp ?? MemoBitcoinBase().createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoSlp);
    return _privateKeyLegacySlp!;
  }

  ECPrivate get _pkLegacy {
    _privateKeyLegacy = _privateKeyLegacy ?? MemoBitcoinBase().createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    return _privateKeyLegacy!;
  }

  ECPrivate get _pkBchCashtoken {
    _privateKeyBchCashtoken = _privateKeyBchCashtoken ?? MemoBitcoinBase().createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);
    return _privateKeyBchCashtoken!;
  }

  String get bchAddressCashtokenAware {
    if (_bchAddressCashtokenAware.isEmpty) {
      _bchAddressCashtokenAware = _pkBchCashtoken.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _bchAddressCashtokenAware;
  }

  static Future<MemoModelUser> createDummy({MemoModelCreator? creator}) async {
    if (dummy == null) {
      String? mne = await SharedPreferencesAsync().getString("mnemonic");
      dummy = MemoModelUser(mnemonic: mne ?? "", creator: creator);
    }
    return dummy!;
  }
}