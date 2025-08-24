import 'package:instagram_clone1/memomodel/memo_model_post.dart';

class MemoModelTag {
  static List<MemoModelTag> tags = [];

  MemoModelTag({this.name, this.postCount, this.lastPost});

  final String? name;
  final int? postCount;
  final String? lastPost;
  final List<MemoModelPost> posts = [];

  //TODO IMPLEMENT EQUALS METHOD, CHECK ID
}
