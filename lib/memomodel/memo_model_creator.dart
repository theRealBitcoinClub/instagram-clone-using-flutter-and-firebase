import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memomodel/memo_model_topic.dart';

class MemoModelCreator {
  MemoModelCreator({
    this.name,
    this.created,
    this.id,
    this.followerCount,
    this.followingCount,
    this.actions,
    this.profileText
    // this.img128px
  });

  final String? name;
  final String? created;
  final String? id;
  final String? profileText;
  final int? followerCount;
  final int? followingCount;
  final int? actions;
  List<MemoModelPost> posts = [];
  List<MemoModelTopic> topics = [];

  String profileImage() {
    return "https://memo.cash/img/profilepics/17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ-128x128.jpg";
  }

  static MemoModelCreator createDummy() {
    MemoModelCreator creator =  MemoModelCreator(
        created: "12.12.1912 12:12",
        id: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
        followerCount: 123,
        actions: 4324,
        followingCount: 22,
        name: "Feliz-TRBC",
        profileText: "TRBC: http://therealbitcoin.club"
            "\n\nBITCOINMAP: http://bmap.app"
            "\n\nTELEGRAM: http://t.me/F_E_L_I_Z"
            "\n\nGITHUB: http://github.com/therealbitcoinclub"
            "\n\nTWITTER: http://x.com/realbitcoinclub");

    return creator;
  }
  // final String? img128px; https://memo.cash/img/profilepics/17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ-128x128.jpg?id=6312
}