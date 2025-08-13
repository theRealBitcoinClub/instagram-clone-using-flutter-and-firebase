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
        creator: MemoModelCreator(
          created: "12.12.1912 12:12",
          id: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
          followerCount: 123,
          actions: 4324,
          followingCount: 22,
          name: "Feliz-TRBC",
          profileText: "Inshalla \n Porke No \n BLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLA"));
  }
}