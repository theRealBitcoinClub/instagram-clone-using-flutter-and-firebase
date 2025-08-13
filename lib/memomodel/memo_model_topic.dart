import 'memo_model_post.dart';

class MemoModelTopic {
  MemoModelTopic({
    this.header,
    this.url,
    this.postCount,
    this.followerCount,
    this.lastPost,
    this.posts
  });

  List<MemoModelPost>? posts;
  final String? header;
  final String? url;
  final int? postCount;
  final int? followerCount;
  final String? lastPost;

  static MemoModelTopic createDummy() {
    return MemoModelTopic(
        followerCount: 12,
        postCount: 33,
        lastPost: "13.09.2001 23:22",
        header: "Super Topic",
        url: "https://memo.cash/topic/Bitcoin+Map");
  }
}