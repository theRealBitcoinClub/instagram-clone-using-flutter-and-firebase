import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp and DocumentSnapshot
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/firebase/topic_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';

part 'memo_model_post.g.dart';

DateTime? _dateTimeFromJson(Timestamp? timestamp) => timestamp?.toDate();

Timestamp? _dateTimeToJson(DateTime? dateTime) => dateTime == null ? null : Timestamp.fromDate(dateTime);

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class MemoModelPost {
  // Use a nullable late variable. It will be initialized by the factory, not from JSON.
  String? id;

  String? text;
  String? imgurUrl;
  String? youtubeId;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  DateTime? createdDateTime;

  int? popularityScore;
  int? likeCounter;
  int? replyCounter;

  String creatorId;
  String topicId;
  List<String> tagIds;

  // --- Transient (Client-Side) Fields ---
  @JsonKey(ignore: true)
  MemoModelCreator? creator;

  @JsonKey(ignore: true)
  MemoModelTopic? topic;

  @JsonKey(ignore: true)
  final String? created;

  @JsonKey(ignore: true)
  String? _ageCache;

  @JsonKey(ignore: true)
  final List<String> urls = [];

  @JsonKey(ignore: true)
  DocumentSnapshot? docSnapshot;

  // --- Private Constructor for json_serializable ---
  // This is the constructor that json_serializable will call.
  // It should NOT have the 'id' field as a required parameter.
  MemoModelPost._({
    this.text,
    this.imgurUrl,
    this.youtubeId,
    this.createdDateTime,
    this.popularityScore,
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
    this.createdDateTime,
    this.popularityScore,
    this.likeCounter,
    this.replyCounter,
    this.creatorId = '',
    this.topicId = '',
    this.tagIds = const [],
    this.creator,
    this.topic,
    this.created,
    this.docSnapshot,
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

  @JsonKey(ignore: true)
  String get age {
    _ageCache = _calculateAgeString();
    return _ageCache!;
  }

  String _calculateAgeString() {
    if (createdDateTime == null) return "";
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdDateTime!);

    if (difference.inSeconds < 60) return "${difference.inSeconds}s";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m";
    if (difference.inHours < 24) return "${difference.inHours}h";
    if (difference.inDays < 7) return "${difference.inDays}d";
    if (difference.inDays < 30) return "${(difference.inDays / 7).floor()}w";
    if (difference.inDays < 365) return "${(difference.inDays / 30).floor()}mo";
    return "${(difference.inDays / 365).floor()}y";
  }

  static Future<MemoModelPost> createDummy(MemoModelCreator memoModelCreator) async {
    MemoModelTopic topic = MemoModelTopic.createDummy();
    return MemoModelPost(
      id: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
      created: "11.11.1911 11:11",
      createdDateTime: DateTime.now().subtract(const Duration(days: 5)),
      creator: memoModelCreator,
      creatorId: memoModelCreator.id,
      imgurUrl: "https://i.imgur.com/YbduTBp.png",
      likeCounter: 33,
      replyCounter: 2,
      text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
      popularityScore: 123456,
      topic: topic,
      topicId: topic.id,
      tagIds: ["dummyTag1", "dummyTag2"],
    );
  }

  Future<dynamic> publishReplyTopic(MemoModelUser user, String replyText) async {
    MemoVerificationResponse verifier = MemoVerifier(replyText).checkAllPostValidations();
    if (verifier == MemoVerificationResponse.valid) {
      return MemoAccountant(user).publishReplyTopic(this, replyText);
    } else {
      return verifier;
    }
  }

  Future<dynamic> publishReplyHashtags(MemoModelUser user, String text) async {
    MemoVerificationResponse verifier = MemoVerifier(text).checkAllPostValidations();
    if (verifier != MemoVerificationResponse.valid) return verifier;
    return MemoAccountant(user).publishReplyHashtags(this, text);
  }

  static Future<dynamic> publishImageOrVideo(MemoModelUser user, String text, String? topic) async {
    MemoVerificationResponse res = MemoVerifier(text).checkAllPostValidations();
    if (res != MemoVerificationResponse.valid) return res;
    return MemoAccountant(user).publishImgurOrYoutube(topic, text);
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

  Future<void> loadTopic() async {
    if (topicId.isNotEmpty) {
      topic = await TopicService().getTopicOnce(topicId);
    }
  }
}
