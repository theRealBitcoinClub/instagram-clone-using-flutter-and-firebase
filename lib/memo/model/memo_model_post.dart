// [1]
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart'; // For Timestamp
import 'package:json_annotation/json_annotation.dart';
// Your other imports
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
// Or if you directly use cloud_firestore package:
// import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';

part 'memo_model_post.g.dart'; // This file will be generated

// Helper functions for DateTime <-> Timestamp conversion
// These need to be top-level or static methods in a class for json_serializable
DateTime? _dateTimeFromJson(Timestamp? timestamp) => timestamp?.toDate();
Timestamp? _dateTimeToJson(DateTime? dateTime) => dateTime == null ? null : Timestamp.fromDate(dateTime);

@JsonSerializable(explicitToJson: true)
class MemoModelPost {
  // PrimaryKey for Firestore document
  // This 'id' should be set to the Firestore document ID when fetching.
  // When creating a new post, Firestore can auto-generate this.
  String id;

  MemoModelPost({
    this.id = '', // ID is now required
    this.text,
    this.uniqueContentId,
    this.imgurUrl,
    this.youtubeId,
    this.creator, // Will not be serialized directly
    this.popularityScore,
    this.likeCounter,
    this.replyCounter,
    this.created, // Original string 'created', will not be serialized
    this.age, // Will not be serialized
    this.topic, // Will not be serialized directly
    this.creatorId = '',
    this.topicId = '',
    this.tagIds = const [],
    this.createdDateTime,
  }) {
    // urls and hashtags are instance variables, initialized empty.
    // They are not part of the constructor parameters if they are always empty initially
    // and populated later.
  }

  // Fields to be serialized
  final int? popularityScore;
  String? text;
  String? uniqueContentId;
  final String? imgurUrl;
  String? youtubeId;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? createdDateTime; // Serialized as Timestamp

  final int? likeCounter;
  final int? replyCounter;

  @JsonKey(ignore: true) // Will not be included in JSON
  final List<String> urls = [];

  @JsonKey(ignore: true) // Will not be included in JSON
  final List<String> hashtags = [];

  @JsonKey(ignore: true) // Will not be included in JSON (only creatorId is serialized)
  MemoModelCreator? creator;

  @JsonKey(ignore: true) // Will not be included in JSON (only topicId is serialized)
  MemoModelTopic? topic;

  @JsonKey(ignore: true) // Will not be included in JSON
  final String? age;

  @JsonKey(ignore: true) // Original string version, will not be included in JSON
  final String? created;

  // IDs for relationships - these will be serialized.
  String creatorId;
  String topicId;
  @JsonKey(defaultValue: [])
  List<String> tagIds;

  /// Factory constructor for creating a new MemoModelPost instance from a map.
  factory MemoModelPost.fromJson(Map<String, dynamic> json) => _$MemoModelPostFromJson(json);

  /// Converts this MemoModelPost instance into a map.
  Map<String, dynamic> toJson() => _$MemoModelPostToJson(this);

  // --- Static lists and methods (Not part of JSON serialization) ---
  // static final List<MemoModelPost> allPosts = [];
  // static final List<MemoModelPost> ytPosts = [];
  // static final List<MemoModelPost> imgurPosts = [];
  // static final List<MemoModelPost> hashTagPosts = [];
  // static final List<MemoModelPost> topicPosts = [];

  static Future<MemoModelPost> createDummy(MemoModelCreator memoModelCreator) async {
    MemoModelTopic topic = MemoModelTopic.createDummy();
    String newPostId = "dummyPost_${DateTime.now().millisecondsSinceEpoch}"; // Example ID generation

    MemoModelPost memoModelPost = MemoModelPost(
      id: newPostId,
      age: "11d", // Not serialized, kept for original logic if any
      created: "11.11.1911 11:11", // Not serialized
      createdDateTime: DateTime.now().subtract(const Duration(days: 5)), // Example DateTime
      creator: memoModelCreator, // Not serialized
      creatorId: memoModelCreator.id, // Serialized
      imgurUrl: "https://i.imgur.com/YbduTBp.png",
      likeCounter: 33,
      replyCounter: 2,
      text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
      popularityScore: 123456,
      uniqueContentId: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
      topic: topic, // Not serialized
      topicId: topic.id, // Serialized
      tagIds: ["dummyTag1", "dummyTag2"],
    );
    // Manually populate urls/hashtags if needed for the dummy AFTER construction
    // for runtime use, as they won't be part of JSON.
    // memoModelPost.urls.add("http://example.com");
    // memoModelPost.hashtags.add("#dummy");
    return memoModelPost;
  }

  // static void addToGlobalPostList(List<MemoModelPost> p) {
  //   MemoModelPost.allPosts.addAll(p);
  //   for (var element in p) {
  //     if (element.imgurUrl != null && element.imgurUrl!.isNotEmpty) {
  //       imgurPosts.add(element);
  //     } else if (element.youtubeId != null && element.youtubeId!.isNotEmpty) {
  //       ytPosts.add(element);
  //     } else if (element.hashtags.isNotEmpty) {
  //       hashTagPosts.add(element);
  //     } else if (element.topic != null) {
  //       topicPosts.add(element);
  //     }
  //   }
  // }

  // --- Publish methods (Remain the same) ---
  Future<dynamic> publishReplyTopic(String replyText) async {
    MemoVerificationResponse verifier = MemoVerifier(replyText).checkIsValidText();
    if (verifier == MemoVerificationResponse.valid) {
      var user = await MemoModelUser.getUser();
      return MemoAccountant(user).publishReplyTopic(this, replyText);
    } else {
      return verifier;
    }
  }

  Future<dynamic> publishReplyHashtags(String text) async {
    MemoVerificationResponse verifier = MemoVerifier(text).checkIsValidText();
    if (verifier != MemoVerificationResponse.valid) return verifier;
    var user = await MemoModelUser.getUser();
    return MemoAccountant(user).publishReplyHashtags(this, text);
  }

  static Future<dynamic> publishImageOrVideo(String text, String? topic) async {
    MemoVerificationResponse res = MemoVerifier(text).checkIsValidText();
    if (res != MemoVerificationResponse.valid) return res;
    var user = await MemoModelUser.getUser();
    return MemoAccountant(user).publishImgurOrYoutube(topic, text);
  }

  // --- Equals and HashCode ---
  // Now using 'id' (Firestore Document ID) as the primary basis for equality.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoModelPost && runtimeType == other.runtimeType && id == other.id; // Primary check using the document ID
  }

  @override
  int get hashCode => id.hashCode; // Base on document ID

  @override
  String toString() {
    return 'MemoModelPost(id: $id, uniqueContentId: $uniqueContentId, text: $text, creatorId: $creatorId)';
  }
}
