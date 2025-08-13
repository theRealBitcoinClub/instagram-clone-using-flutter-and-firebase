import 'package:instagram_clone1/memomodel/memo_model_creator.dart';

class MemoModelUser {
  MemoModelUser({
    this.wif,
    this.creator
  });

  final String? wif;
  final MemoModelCreator? creator;

  static MemoModelUser createDummy() {
    return MemoModelUser(wif: "5HtpWVLipP5iKskfrhZLcxveVV39JZpiMGQseYRepRDUPGp97sU", 
        creator: MemoModelCreator.createDummy());
  }
}