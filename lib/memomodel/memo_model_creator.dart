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

  String profileImage() {
    return "https://memo.cash/img/profilepics/17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ-128x128.jpg";
  }
  // final String? img128px; https://memo.cash/img/profilepics/17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ-128x128.jpg?id=6312
}