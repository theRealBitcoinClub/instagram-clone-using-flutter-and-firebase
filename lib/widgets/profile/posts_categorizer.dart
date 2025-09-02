import '../../memo/model/memo_model_post.dart';

class PostsCategorizer {
  final List<MemoModelPost> imagePosts;
  final List<MemoModelPost> videoPosts;
  final List<MemoModelPost> taggedPosts;
  final List<MemoModelPost> topicPosts;

  PostsCategorizer({required this.imagePosts, required this.videoPosts, required this.taggedPosts, required this.topicPosts});

  factory PostsCategorizer.fromPosts(List<MemoModelPost> allPosts) {
    final imagePosts = <MemoModelPost>[];
    final videoPosts = <MemoModelPost>[];
    final taggedPosts = <MemoModelPost>[];
    final topicPosts = <MemoModelPost>[];

    for (var post in allPosts) {
      if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) imagePosts.add(post);
      if (post.youtubeId != null && post.youtubeId!.isNotEmpty) videoPosts.add(post);
      if (post.tagIds.isNotEmpty) taggedPosts.add(post);
      if (post.topicId.isNotEmpty) topicPosts.add(post);
    }

    return PostsCategorizer(imagePosts: imagePosts, videoPosts: videoPosts, taggedPosts: taggedPosts, topicPosts: topicPosts);
  }

  bool hasChanged(PostsCategorizer other) {
    return !_listEquals(imagePosts, other.imagePosts) ||
        !_listEquals(videoPosts, other.videoPosts) ||
        !_listEquals(taggedPosts, other.taggedPosts) ||
        !_listEquals(topicPosts, other.topicPosts);
  }

  bool _listEquals(List<MemoModelPost> list1, List<MemoModelPost> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }
}
