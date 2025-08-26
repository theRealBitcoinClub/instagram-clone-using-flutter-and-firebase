import 'package:mahakka/check_404.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

class MemoModelCreator {
  static const String sizeAvatar = "128x128";
  static const String sizeDetail = "640x640";
  static const List<String> imageTypes = ["jpg", "png"];
  static const String imageBaseUrl = "https://memo.cash/img/profilepics/";

  String id;
  String name;
  String profileText;
  int followerCount;
  int actions;
  String created;
  String lastActionDate;

  List<MemoModelPost> posts = [];
  String? _profileImageAvatar;
  String? _profileImageDetail;
  int hasCheckedImgAvatar = 0;
  int hasCheckedImgDetail = 0;
  static int maxCheckImage = 1;

  MemoModelCreator._create(
    this.id,
    this.name,
    this.profileText,
    this.followerCount,
    this.actions,
    this.created,
    this.lastActionDate,
  );

  static MemoModelCreator create({
    required String id,
    required String name,
    String profileText = "",
    int followerCount = 0,
    int actions = 0,
    String created = "",
    String lastActionDate = "",
  }) {
    MemoModelCreator creator = MemoModelCreator._create(
      id,
      name,
      profileText,
      followerCount,
      actions,
      created,
      lastActionDate,
    );
    // creator._checkProfileImageAvatar();
    // creator._checkProfileImageDetail();
    return creator;
  }

  //TODO call on creation of postcard & creation of detail dialog in profile screen

  void refreshAvatar() {
    _checkProfileImageAvatar();
  }

  //TODO call on launch of profile screen

  Future<bool> refreshDetail() async {
    return _checkProfileImageDetail();
  }

  String profileImageAvatar() {
    // if (_profileImageAvatar == null) _checkProfileImageAvatar();
    return _profileImageAvatar ?? "";
  }

  // Future<void> _checkProfileImage(int counter, String size, String? img) async {
  //   if (counter > maxCheckImage) return;
  //
  //   for (String t in imageTypes) {
  //     if (img != null) return;
  //
  //     String avatarUrl = _profileImageUrl(size, t);
  //     if (!await checkUrlReturns404(avatarUrl)) img = avatarUrl;
  //   }
  //
  //   counter++;
  // }
  //
  // Future<void> _checkProfileImageAvatar() async {
  //   _checkProfileImage(hasCheckedImgAvatar, sizeAvatar, _profileImageAvatar);
  // }
  //
  // //TODO LAZY LOAD DETAIL IMAGE
  //
  // String profileImageDetail() {
  //   if (_profileImageDetail == null) _checkProfileImageDetail();
  //   return _profileImageDetail ?? "";
  // }
  //
  // Future<void> _checkProfileImageDetail() async {
  //   _checkProfileImage(hasCheckedImgDetail, sizeDetail, _profileImageDetail);
  // }

  Future<void> _checkProfileImageAvatar() async {
    if (hasCheckedImgAvatar > maxCheckImage) return;

    for (String t in imageTypes) {
      if (_profileImageAvatar != null) return;

      String avatarUrl = _profileImageUrl(sizeAvatar, t);
      if (!await checkUrlReturns404(avatarUrl)) _profileImageAvatar = avatarUrl;
    }

    hasCheckedImgAvatar++;
  }

  //TODO LAZY LOAD DETAIL IMAGE

  String profileImageDetail() {
    // if (_profileImageDetail == null) _checkProfileImageDetail();
    return _profileImageDetail ?? "";
  }

  Future<bool> _checkProfileImageDetail() async {
    if (hasCheckedImgDetail > maxCheckImage) return false;

    for (String t in imageTypes) {
      if (_profileImageDetail != null) return true;

      String url = _profileImageUrl(sizeDetail, t);
      if (!await checkUrlReturns404(url)) {
        _profileImageDetail = url;
        return true;
      }
    }

    hasCheckedImgDetail++;
    return false;
  }

  //add millis to get fresh image

  String _profileImageUrl(String size, String type) {
    return "$imageBaseUrl$id-$size.$type?${DateTime.now().millisecondsSinceEpoch}";
  }

  //TODO IMPLEMENT EQUALS METHOD, CHECK ID
}
