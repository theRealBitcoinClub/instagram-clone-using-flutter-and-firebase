import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';

import '../memoscraper/memo_bitcoin_base.dart';

class MemoModelUser {
  MemoModelUser({
    required this.mnemonic,
    this.creator
  }) {
    MemoBitcoinBase base = MemoBitcoinBase();
    ECPrivate bip44Receiver = base.createBip44PrivateKey(mnemonic, "m/44'/145'/0'/0/0");
    ECPrivate legacyPK = base.createBip44PrivateKey(mnemonic, "m/44'/0'/0'/0/0");
    ECPrivate slpPK = base.createBip44PrivateKey(mnemonic, "m/44'/245'/0'/0/0");
    
    bchAddress145tokenAware = bip44Receiver.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    legacyAddress44Memo1BCH = legacyPK.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    legacyAddress245Memo2SLP = slpPK.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
  }

  String mnemonic;
  late String bchAddress145tokenAware;
  late String legacyAddress44Memo1BCH;
  late String legacyAddress245Memo2SLP;
  MemoModelCreator? creator;

  //TODO generate BCH address from mnemonic
  //TODO generate creator profile id from mnemonic

  static MemoModelUser createDummy() {
    return MemoModelUser(mnemonic: "MMMMNE",
        creator: MemoModelCreator.createDummy());
  }
}