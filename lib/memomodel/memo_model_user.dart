import 'package:instagram_clone1/memomodel/memo_model_creator.dart';

class MemoModelUser {
  MemoModelUser({
    required this.mnemonic,
    this.creator
  });

  String mnemonic;
  String bchAddress = "bitcoincash:janifewuf3298rf293hf9hf98dshj9fs";
  MemoModelCreator? creator;

  //TODO generate BCH address from mnemonic
  //TODO generate creator profile id from mnemonic

  static MemoModelUser createDummy() {
    return MemoModelUser(mnemonic: "mnemonic",
        creator: MemoModelCreator.createDummy());
  }
}