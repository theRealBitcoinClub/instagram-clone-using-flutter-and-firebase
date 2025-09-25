import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp and DocumentSnapshot
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  final String? created;

  // @JsonKey(includeFromJson: false, includeToJson: false)
  // String? _ageCache;

  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String> urls = [];

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
    this.created,
    this.docSnapshot,
    this.showOnFeed,
    this.hideOnFeed,
    this.urls = const [],
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
    List<String>? urls,
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
      created: created ?? this.created,
      urls: urls ?? this.urls,
      docSnapshot: docSnapshot ?? this.docSnapshot,
    );
  }

  bool get hasImageMedia {
    return (imageUrl != null && imageUrl!.isNotEmpty) || (imgurUrl != null && imgurUrl!.isNotEmpty);
  }

  bool get hasMedia {
    return (imageUrl != null && imageUrl!.isNotEmpty) ||
        (imgurUrl != null && imgurUrl!.isNotEmpty) ||
        (videoUrl != null && videoUrl!.isNotEmpty) ||
        (ipfsCid != null && ipfsCid!.isNotEmpty) ||
        (youtubeId != null && youtubeId!.isNotEmpty);
  }

  String get mediaUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    if (imgurUrl != null && imgurUrl!.isNotEmpty) return imgurUrl!;
    if (videoUrl != null && videoUrl!.isNotEmpty) return videoUrl!;
    if (ipfsCid != null && ipfsCid!.isNotEmpty) return IpfsConfig.preferredNode + ipfsCid!;
    if (youtubeId != null && youtubeId!.isNotEmpty) return "https://youtu.be/$youtubeId";
    return "";
  }

  static String restoreMediaUrlsCase(MemoModelPost post, String textToBeRestored) {
    String result = textToBeRestored;

    // Check each media URL property and restore its case in the text
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      result = restoreWordCase(result, post.imageUrl!);
    }

    if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) {
      result = restoreWordCase(result, post.imgurUrl!);
    }

    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) {
      result = restoreWordCase(result, post.videoUrl!);
    }

    if (post.ipfsCid != null && post.ipfsCid!.isNotEmpty) {
      result = restoreWordCase(result, post.ipfsCid!);
    }

    if (post.youtubeId != null && post.youtubeId!.isNotEmpty) {
      result = restoreWordCase(result, post.youtubeId!);
    }

    return result;
  }

  static String restoreTagsAndTopicCase(String malformedText, String originalText) {
    String result = malformedText;

    MemoRegExp.extractTopics(originalText).forEach((topic) {
      result = restoreWordCase(result, topic);
    });

    MemoRegExp.extractHashtags(originalText).forEach((tag) {
      result = restoreWordCase(result, tag);
    });

    return result;
  }

  static String restoreWordCase(String originalWithMessedUpCase, String originalWord) {
    String lowercaseWord = originalWord.toLowerCase();
    int index = originalWithMessedUpCase.toLowerCase().indexOf(lowercaseWord);

    if (index == -1) {
      return originalWithMessedUpCase; // Word not found, return original text
    }

    // Split the text into parts: before, the word itself, and after
    String before = originalWithMessedUpCase.substring(0, index);
    String after = originalWithMessedUpCase.substring(index + lowercaseWord.length);

    // Reconstruct with the original word case
    return before + originalWord + after;
  }

  String? get mediaPreviewUrl {
    return imgurUrl ?? imageUrl ?? videoUrl ?? ipfsCid ?? (youtubeId != null ? YoutubePlayer.getThumbnail(videoId: youtubeId!) : null);
  }

  // Add method to check if post has URLs but no media
  bool get hasUrlsInText {
    return MemoRegExp.extractUrls(text).isNotEmpty;
  }

  String parseUrlsClearText() {
    final urlsExtracted = MemoRegExp.extractUrls(text);
    String result = text ?? "";

    for (final url in urlsExtracted) {
      result = result.replaceAll(url, '');
    }
    urls = urlsExtracted;
    text = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
  }

  String parseTagsClearText() {
    final tags = MemoRegExp.extractHashtags(text);
    String result = text ?? "";

    for (final t in tags) {
      result = result.replaceAll(t, '');
    }
    tagIds = tags;
    text = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
  }

  String parseTopicClearText() {
    var topics = MemoRegExp.extractTopics(text);
    var topic = "";
    if (topics.isNotEmpty) topic = topics.first;

    String result = text ?? "";

    result = result.replaceAll(topic, '');

    topicId = topic;
    text = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
  }

  String parseUrlsTagsTopicClearText() {
    var result = parseUrlsClearText();
    result = parseTagsClearText();
    result = parseTopicClearText();

    return result;
  }

  void appendUrlsToText() {
    if (text != null)
      for (final url in urls) {
        text = text! + " \n\n$url";
      }
  }

  void appendTagsToText() {
    if (text != null)
      for (final t in tagIds) {
        text = text! + " $t";
      }
  }

  void appendTopicToText() {
    // if (!topicId.startsWith("@"))
    //   topicId = "@" + topicId;

    if (text != null) text = topicId! + " " + text!;
  }

  void appendTagsTopicToText() {
    appendTagsToText();
    appendTopicToText();
  }

  void appendUrlsTagsTopicToText() {
    appendTagsToText();
    appendUrlsToText();
    appendTopicToText();
  }
}
