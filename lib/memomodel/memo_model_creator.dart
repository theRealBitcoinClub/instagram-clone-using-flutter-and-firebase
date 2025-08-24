import 'package:instagram_clone1/memomodel/memo_model_post.dart';

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

  //TODO SOME PROFILEIMAGES ARE LOADED WITH WRONG ID
  String profileImage() {
    return "https://memo.cash/img/profilepics/${id}-128x128.jpg";
  }

  static MemoModelCreator createDummy() {
    MemoModelCreator creator = MemoModelCreator(
      created: "",
      id: "",
      followerCount: 0,
      actions: 0,
      name: "",
      profileText: "",
    );

    return creator;
  }

  //TODO IMPLEMENT EQUALS METHOD, CHECK ID
}
