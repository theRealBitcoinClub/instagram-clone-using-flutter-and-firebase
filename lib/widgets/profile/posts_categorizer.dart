// lib/widgets/profile/posts_categorizer.dart

import '../../memo/model/memo_model_post.dart';

class PostsCategorizer {
  final List<MemoModelPost> imagePosts;
  final List<MemoModelPost> videoPosts;
  final List<MemoModelPost> taggedPosts;
  final List<MemoModelPost> topicPosts;

  PostsCategorizer({required this.imagePosts, required this.videoPosts, required this.taggedPosts, required this.topicPosts});

  // Empty constructor
  factory PostsCategorizer.empty() {
    return PostsCategorizer(imagePosts: [], videoPosts: [], taggedPosts: [], topicPosts: []);
  }

  factory PostsCategorizer.fromPosts(List<MemoModelPost> allPosts) {
    final imagePosts = <MemoModelPost>[];
    final videoPosts = <MemoModelPost>[];
    final taggedPosts = <MemoModelPost>[];
    final topicPosts = <MemoModelPost>[];

    for (var post in allPosts) {
      // Check for image content (imgurUrl OR imageUrl OR ipfsCid)
      final hasImageContent =
          (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) ||
          (post.imageUrl != null && post.imageUrl!.isNotEmpty) ||
          (post.ipfsCid != null && post.ipfsCid!.isNotEmpty);

      // Check for video content (youtubeId OR videoUrl)
      final hasVideoContent = (post.youtubeId != null && post.youtubeId!.isNotEmpty) || (post.videoUrl != null && post.videoUrl!.isNotEmpty);

      // Add to image category if it has image content
      if (hasImageContent) imagePosts.add(post);

      // Add to video category if it has video content
      if (hasVideoContent) videoPosts.add(post);

      // Add to tagged category if it has tags (independent of media)
      if (post.tagIds.isNotEmpty) taggedPosts.add(post);

      // Add to topic category if it has a topic (independent of media)
      if (post.topicId.isNotEmpty) topicPosts.add(post);
    }

    return PostsCategorizer(imagePosts: imagePosts, videoPosts: videoPosts, taggedPosts: taggedPosts, topicPosts: topicPosts);
  }

  bool get isEmpty => imagePosts.isEmpty && videoPosts.isEmpty && taggedPosts.isEmpty && topicPosts.isEmpty;

  bool hasChanged(PostsCategorizer other) {
    return !_listEquals(imagePosts, other.imagePosts) ||
        !_listEquals(videoPosts, other.videoPosts) ||
        !_listEquals(taggedPosts, other.taggedPosts) ||
        !_listEquals(topicPosts, other.topicPosts);
  }

  int totalPosts() {
    final allPosts = [...imagePosts, ...videoPosts, ...taggedPosts, ...topicPosts];

    final uniquePostIds = <String>{};
    for (final post in allPosts) {
      if (post.id != null) uniquePostIds.add(post.id!);
    }

    return uniquePostIds.length;
  }

  bool _listEquals(List<MemoModelPost> list1, List<MemoModelPost> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }
}
