import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp and DocumentSnapshot
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

part 'memo_model_post.g.dart';

DateTime? _dateTimeFromJson(Timestamp? timestamp) => timestamp?.toDate();

Timestamp? _dateTimeToJson(DateTime? dateTime) => dateTime == null ? null : Timestamp.fromDate(dateTime);

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class MemoModelPost {
  // Use a nullable late variable. It will be initialized by the factory, not from JSON.
  String? id;

  String? text;
  //this is historically used because memo.cash treats imgur differently all imgur images are visible on memo too
  String? imgurUrl;
  //all youtube videos are visible on memo.cash too
  String? youtubeId;
  //this could be any image from any whitelisted domain, e.g. IPFS, not necessarily visible on memo.cash
  String? imageUrl;
  //this could be an odysee url or github if someone uploaded a video to github not necessarily visible on memo.cash
  String? videoUrl;
  //TODO SPECIAL FLAG FOR POSTS THAT SHALL BE SHOWNONFEED ALWAYS REGARDLESS OF CREATOR TOKEN BALANCE OR POPULARITY SCORE
  bool? showOnFeed = false;
  bool? hideOnFeed = false;
  //Interplanetary File System Content ID
  String? ipfsCid;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime? createdDateTime;

  int popularityScore = 0;
  int? likeCounter;
  int? replyCounter;

  String creatorId;
  String topicId;
  List<String> tagIds;

  // --- Transient (Client-Side) Fields ---
  @JsonKey(includeFromJson: false, includeToJson: false)
  MemoModelCreator? creator;

  @JsonKey(includeFromJson: false, includeToJson: false)
  MemoModelTopic? topic;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? created;

  // @JsonKey(includeFromJson: false, includeToJson: false)
  // String? _ageCache;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<String> urls = [];

  @JsonKey(includeFromJson: false, includeToJson: false)
  DocumentSnapshot? docSnapshot;

  // --- Private Constructor for json_serializable ---
  // This is the constructor that json_serializable will call.
  // It should NOT have the 'id' field as a required parameter.
  MemoModelPost._({
    this.text,
    this.imgurUrl,
    this.youtubeId,
    this.createdDateTime,
    this.popularityScore = 0,
    this.likeCounter,
    this.replyCounter,
    this.creatorId = '',
    this.topicId = '',
    this.tagIds = const [],
    this.created,
  }) {
    if (this.createdDateTime == null && this.created != null && this.created!.isNotEmpty) {
      try {
        this.createdDateTime = DateTime.parse(this.created!);
      } catch (e) {
        print("Error parsing 'created' string to DateTime: $e");
      }
    }
  }

  // --- Public Constructor for manual creation ---
  // You can keep a public constructor for creating new posts before saving.
  MemoModelPost({
    required this.id,
    this.text,
    this.imgurUrl,
    this.youtubeId,
    this.videoUrl,
    this.imageUrl,
    this.ipfsCid,
    this.createdDateTime,
    this.popularityScore = 0,
    this.likeCounter,
    this.replyCounter,
    this.creatorId = '',
    this.topicId = '',
    this.tagIds = const [],
    this.creator,
    this.topic,
    this.created,
    this.docSnapshot,
    this.showOnFeed,
    this.hideOnFeed,
  }) {
    // Initialization logic for public constructor if needed
  }

  // --- JSON Serialization ---
  // The fromJson factory now calls the private constructor.
  factory MemoModelPost.fromJson(Map<String, dynamic> json) => _$MemoModelPostFromJson(json);

  Map<String, dynamic> toJson() => _$MemoModelPostToJson(this);

  // --- Factory to include DocumentSnapshot and ID ---
  factory MemoModelPost.fromSnapshot(DocumentSnapshot snap) {
    if (!snap.exists || snap.data() == null) {
      throw Exception("Document ${snap.id} does not exist or has no data.");
    }
    final data = snap.data() as Map<String, dynamic>;
    // The fromJson method now correctly handles the JSON map.
    // The id is then manually assigned.
    return MemoModelPost.fromJson(data)
      ..id = snap.id
      ..docSnapshot = snap;
  }

  // Rest of your class methods...

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get age {
    return _calculateAgeString();
    // _ageCache = _calculateAgeString();
    // return _ageCache!;
  }

  String _calculateAgeString() {
    if (createdDateTime == null) return "";

    // Convert both DateTime objects to UTC for a correct comparison.
    final DateTime nowUtc = DateTime.now().toUtc();
    final DateTime createdUtc = createdDateTime!.subtract(Duration(hours: 4));

    // Calculate the difference between the two UTC times.
    final Duration difference = nowUtc.difference(createdUtc);

    if (difference.inSeconds < 60) return "${difference.inSeconds}s";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m";
    if (difference.inHours < 24) return "${difference.inHours}h";
    if (difference.inDays < 7) return "${difference.inDays}d";
    if (difference.inDays < 30) return "${(difference.inDays / 7).floor()}w";
    if (difference.inDays < 365) return "${(difference.inDays / 30).floor()}mo";
    return "${(difference.inDays / 365).floor()}y";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoModelPost && runtimeType == other.runtimeType && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MemoModelPost(id: $id, text: $text, creatorId: $creatorId)';
  }

  String dateTimeFormattedSafe() {
    if (createdDateTime == null) return "N/A";
    try {
      final localDateTime = createdDateTime!.toLocal();
      String date = "${localDateTime.year}-${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')}";
      String time = "${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}";
      return date;
    } catch (e) {
      print("Error parsing DateTime: $createdDateTime, Error: $e");
      return "Invalid Date";
    }
  }

  MemoModelPost copyWith({
    String? id,
    String? text,
    String? imgurUrl,
    String? youtubeId,
    String? imageUrl,
    String? videoUrl,
    bool? showOnFeed,
    bool? hideOnFeed,
    String? ipfsCid,
    DateTime? createdDateTime,
    int? popularityScore,
    int? likeCounter,
    int? replyCounter,
    String? creatorId,
    String? topicId,
    List<String>? tagIds,
    MemoModelCreator? creator,
    MemoModelTopic? topic,
    String? created,
    DocumentSnapshot? docSnapshot,
  }) {
    return MemoModelPost(
      id: id ?? this.id,
      text: text ?? this.text,
      imgurUrl: imgurUrl ?? this.imgurUrl,
      youtubeId: youtubeId ?? this.youtubeId,
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      ipfsCid: ipfsCid ?? this.ipfsCid,
      showOnFeed: showOnFeed ?? this.showOnFeed,
      hideOnFeed: hideOnFeed ?? this.hideOnFeed,
      createdDateTime: createdDateTime ?? this.createdDateTime,
      popularityScore: popularityScore ?? this.popularityScore,
      likeCounter: likeCounter ?? this.likeCounter,
      replyCounter: replyCounter ?? this.replyCounter,
      creatorId: creatorId ?? this.creatorId,
      topicId: topicId ?? this.topicId,
      tagIds: tagIds ?? this.tagIds,
      creator: creator ?? this.creator,
      topic: topic ?? this.topic,
      created: created ?? this.created,
      docSnapshot: docSnapshot ?? this.docSnapshot,
    );
  }
}
