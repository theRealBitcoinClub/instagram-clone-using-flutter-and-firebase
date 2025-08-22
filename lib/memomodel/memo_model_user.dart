import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memoscraper/memo_bitcoin_base.dart';

class MemoModelUser {
  String mnemonic;
  String _bchAddress145tokenAware = "";
  String _legacyAddress44Memo1BCH = "";
  MemoModelCreator? creator;

  MemoModelUser({
    required this.mnemonic,
    this.creator
  });

  String get legacyAddress44Memo1BCH {
    if (_legacyAddress44Memo1BCH.isEmpty) {
      _legacyAddress44Memo1BCH = MemoBitcoinBase().createBip44PrivateKey(mnemonic, "m/44'/0'/0'/0/0")
          .getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddress44Memo1BCH;
  }


  String get bchAddress145tokenAware {
    if (_bchAddress145tokenAware.isEmpty) {
      _bchAddress145tokenAware = MemoBitcoinBase().createBip44PrivateKey(mnemonic, "m/44'/145'/0'/0/0")
          .getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _bchAddress145tokenAware;
  }

  //TODO generate creator profile id from mnemonic

  static Future<MemoModelUser> createDummy(MemoModelCreator creator) async {
    String? mne = await SharedPreferencesAsync().getString("mnemonic");
    return MemoModelUser(mnemonic: mne ?? "", creator: creator);
  }
}