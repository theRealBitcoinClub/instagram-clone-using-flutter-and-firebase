import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memoscraper/memo_bitcoin_base.dart';

class MemoModelUser {
  MemoModelUser({
    required this.mnemonic,
    this.creator
  }) {
    // MemoBitcoinBase base = MemoBitcoinBase();
    // ECPrivate bip44Receiver = base.createBip44PrivateKey(mnemonic, "m/44'/145'/0'/0/0");
    // ECPrivate legacyPK = base.createBip44PrivateKey(mnemonic, "m/44'/0'/0'/0/0");
    // ECPrivate slpPK = base.createBip44PrivateKey(mnemonic, "m/44'/245'/0'/0/0");
    //
    // bchAddress145tokenAware = bip44Receiver.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    // legacyAddress44Memo1BCH = legacyPK.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    // legacyAddress245Memo2SLP = slpPK.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);

    // bchAddress145tokenAware = "";
    legacyAddress44Memo1BCH = "";
    legacyAddress245Memo2SLP = "";
  }

  String get bchAddress145tokenAware {
    if (_bchAddress145tokenAware.isEmpty) {
      _bchAddress145tokenAware = MemoBitcoinBase().createBip44PrivateKey(mnemonic, "m/44'/145'/0'/0/0")
          .getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _bchAddress145tokenAware;
  }

  String mnemonic;
  String _bchAddress145tokenAware = "";
  late String legacyAddress44Memo1BCH;
  late String legacyAddress245Memo2SLP;
  MemoModelCreator? creator;

  //TODO generate BCH address from mnemonic
  //TODO generate creator profile id from mnemonic

  static Future<MemoModelUser> createDummy(MemoModelCreator creator) async {
    String? mne = await SharedPreferencesAsync().getString("mnemonic");
    return MemoModelUser(mnemonic: mne ?? "", creator: creator);
  }
}