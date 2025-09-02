// memo/model/memo_model_post_db.dart

import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

part 'memo_model_post_db.g.dart';

@Collection()
class MemoModelPostDb {
  // Use the post ID hash as the primary key instead of auto-increment
  // This ensures data integrity and prevents duplicates
  Id get isarId => id.hashCode;

  @Index(unique: true)
  late String id; // The original Firestore document ID

  late String? text;
  late String? imgurUrl;
  late String? youtubeId;

  @Index()
  late DateTime? createdDateTime;

  late int? popularityScore;
  late int? likeCounter;
  late int? replyCounter;

  @Index(composite: [CompositeIndex('createdDateTime')])
  late String creatorId;

  @Index(composite: [CompositeIndex('createdDateTime')])
  late String topicId;

  @Index() // Add index for tagIds if you need to query by tags
  late List<String> tagIds;

  // Store the original created string for compatibility
  late String? createdString;

  // Cache timestamp (though objects are immutable, useful for cache management)
  @enumerated // Store as int64 for better performance
  @Index()
  late DateTime cachedAt;

  MemoModelPostDb();

  // Convert from app model to DB model
  factory MemoModelPostDb.fromAppModel(MemoModelPost post) {
    if (post.id == null || post.id!.isEmpty) {
      throw ArgumentError('Post must have a valid ID for caching');
    }

    return MemoModelPostDb()
      ..id = post.id!
      ..text = post.text
      ..imgurUrl = post.imgurUrl
      ..youtubeId = post.youtubeId
      ..createdDateTime = post.createdDateTime
      ..popularityScore = post.popularityScore
      ..likeCounter = post.likeCounter
      ..replyCounter = post.replyCounter
      ..creatorId = post.creatorId
      ..topicId = post.topicId
      ..tagIds =
          List<String>.from(post.tagIds) // Create a copy
      ..createdString = post.created
      ..cachedAt = DateTime.now().toUtc(); // Use UTC for consistency
  }

  // Convert back to app model
  MemoModelPost toAppModel() {
    return MemoModelPost(
      id: id,
      text: text,
      imgurUrl: imgurUrl,
      youtubeId: youtubeId,
      createdDateTime: createdDateTime,
      popularityScore: popularityScore,
      likeCounter: likeCounter,
      replyCounter: replyCounter,
      creatorId: creatorId,
      topicId: topicId,
      tagIds: List<String>.from(tagIds), // Create a copy
      created: createdString,
    );
  }

  // Since objects are immutable, we don't need staleness check
  // But we can keep this for cache management if needed
  bool get isExpired {
    // Even though posts are immutable, we might want to refresh after a long time
    const maxCacheDuration = Duration(days: 30); // 30 days cache
    return DateTime.now().toUtc().difference(cachedAt) > maxCacheDuration;
  }
}
