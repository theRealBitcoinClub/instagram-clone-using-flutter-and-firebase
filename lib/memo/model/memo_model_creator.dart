import 'package:mahakka/memo/model/memo_model_post.dart';

class MemoModelCreator {
  MemoModelCreator({
    this.name = "",
    this.created = "",
    this.id = "",
    this.followerCount = 0,
    this.actions = 0,
    this.profileText = "",
    this.lastActionDate = "",
    // this.img128px
  });

  String name;
  String profileText;
  final String created;
  final String lastActionDate;
  final String id;
  final int followerCount;
  final int actions;
  List<MemoModelPost> posts = [];

  //TODO SOME PROFILEIMAGES ARE LOADED WITH WRONG ID TRY THE SLP VARIANT

  static MemoModelCreator createDummy({String id = ""}) {
    MemoModelCreator creator = MemoModelCreator(
      created: "",
      id: id,
      followerCount: 0,
      actions: 0,
      name: " ",
      profileText: " ",
    );

    return creator;
  }

  String profileImageAvatar() {
    return _profileImage("128x128");
  }

  String profileImageDetail() {
    return _profileImage("640x640");
  }

  String _profileImage(String size) {
    return "https://memo.cash/img/profilepics/$id-$size.jpg";
  }

  //TODO IMPLEMENT EQUALS METHOD, CHECK ID
}
