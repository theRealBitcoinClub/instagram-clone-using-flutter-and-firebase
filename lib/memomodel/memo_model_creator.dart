import 'package:instagram_clone1/memomodel/memo_model_post.dart';

class MemoModelCreator {
  MemoModelCreator({
    this.name,
    this.created = "2011.11.11 11:11",
    this.id,
    this.followerCount = 43,
    this.actions = 4435,
    this.profileText = "profileText",
    this.lastActionDate = "2022.12.12 12:12:12"
    // this.img128px
  });

  String? name;
  final String? created;
  final String? lastActionDate;
  final String? id;
  String? profileText;
  final int? followerCount;
  final int? actions;
  List<MemoModelPost> posts = [];

  //TODO SOME PROFILEIMAGES ARE LOADED WITH WRONG ID
  String profileImage() {
    return "https://memo.cash/img/profilepics/${id}-128x128.jpg";
  }

  static MemoModelCreator createDummy() {
    MemoModelCreator creator =  MemoModelCreator(
        created: "12.12.1912 12:12",
        id: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
        followerCount: 123,
        actions: 4324,
        name: "Feliz-TRBC",
        profileText: "TRBC: http://therealbitcoin.club"
            "\n\nBITCOINMAP: http://bmap.app"
            "\n\nTELEGRAM: http://t.me/F_E_L_I_Z"
            "\n\nGITHUB: http://github.com/therealbitcoinclub"
            "\n\nTWITTER: http://x.com/realbitcoinclub");

    return creator;
  }

  //TODO IMPLEMENT EQUALS METHOD, CHECK ID
}