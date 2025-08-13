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
}