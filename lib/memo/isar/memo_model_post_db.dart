// memo/model/memo_model_post_db.dart

import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

part 'memo_model_post_db.g.dart';

@Collection()
class MemoModelPostDb {
  Id id = Isar.autoIncrement; // Fast FIFO with primary key sort

  @Index(unique: true) // Fast lookups by postId
  late String postId; // The original Firestore document ID

  late String? text;
  late String? imgurUrl;
  late String? youtubeId;
  late String? imageUrl;
  late String? videoUrl;
  late String? ipfsCid;
  late bool? showOnFeed;
  late bool? hideOnFeed;

  @Index()
  late DateTime? createdDateTime;

  late int popularityScore;
  late int? likeCounter;
  late int? replyCounter;

  @Index(composite: [CompositeIndex('createdDateTime')])
  late String creatorId;

  @Index(composite: [CompositeIndex('createdDateTime')])
  late String topicId;

  @Index()
  late List<String> tagIds;

  // Store the original created string for compatibility
  late String? created;

  // Cache timestamp (for optional housekeeping, not expiration)
  @enumerated
  late DateTime cachedAt;

  // Store URLs extracted from text for faster access
  late List<String> urls;

  MemoModelPostDb();

  // Convert from app model to DB model
  factory MemoModelPostDb.fromAppModel(MemoModelPost post) {
    if (post.id == null || post.id!.isEmpty) {
      throw ArgumentError('Post must have a valid ID for caching');
    }

    return MemoModelPostDb()
      ..postId = post.id!
      ..text = post.text
      ..imgurUrl = post.imgurUrl
      ..youtubeId = post.youtubeId
      ..imageUrl = post.imageUrl
      ..videoUrl = post.videoUrl
      ..ipfsCid = post.ipfsCid
      ..showOnFeed = post.showOnFeed
      ..hideOnFeed = post.hideOnFeed
      ..createdDateTime = post.createdDateTime
      ..popularityScore = post.popularityScore
      ..likeCounter = post.likeCounter
      ..replyCounter = post.replyCounter
      ..creatorId = post.creatorId
      ..topicId = post.topicId
      ..tagIds = List<String>.from(post.tagIds)
      ..created = post.created
      ..urls = List<String>.from(post.urls)
      ..cachedAt = DateTime.now().toUtc();
  }

  // Convert back to app model
  MemoModelPost toAppModel() {
    return MemoModelPost(
      id: postId, // Use the stored postId
      text: text,
      imgurUrl: imgurUrl,
      youtubeId: youtubeId,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      ipfsCid: ipfsCid,
      showOnFeed: showOnFeed,
      hideOnFeed: hideOnFeed,
      createdDateTime: createdDateTime,
      popularityScore: popularityScore,
      likeCounter: likeCounter,
      replyCounter: replyCounter,
      creatorId: creatorId,
      topicId: topicId,
      tagIds: List<String>.from(tagIds),
      created: created,
      urls: List<String>.from(urls),
    );
  }

  @override
  String toString() {
    return 'MemoModelPostDb(id: $id, postId: $postId, text: $text)';
  }
}
