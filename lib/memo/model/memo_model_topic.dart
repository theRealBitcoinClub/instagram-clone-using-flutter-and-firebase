// [1]
import 'package:json_annotation/json_annotation.dart';

part 'memo_model_topic.g.dart'; // This file will be generated

@JsonSerializable()
class MemoModelTopic {
  // This static list is part of your application's runtime state,
  // not typically part of the JSON serialization of individual topic instances.
  // If you need to save/load this list itself, you'd handle that separately.
  static List<MemoModelTopic> topics = [];

  // The logic to replace spaces in 'id' should ideally happen *before*
  // creating the MemoModelTopic instance if the raw ID (with spaces)
  // is also important, or consistently applied when the ID is set.
  // For JSON serialization, the 'id' field will be serialized as is.
  // If you want the JSON 'id' to always be the one with underscores,
  // ensure it's in that state before toJson() is called.
  MemoModelTopic({
    required String id, // Changed to 'String id' to allow modification below
    this.url,
    this.postCount,
    this.followerCount,
    this.lastPost,
  }) : this.id = id.replaceAll(" ", "_"); // Ensure 'id' is processed

  String id;
  final String? url;
  final int? postCount;
  final int? followerCount;
  final String? lastPost; // Consider if this should be a DateTime for easier sorting/filtering

  /// Factory constructor for creating a new MemoModelTopic instance from a map.
  /// This map (json) usually comes from Firestore or other JSON sources.
  factory MemoModelTopic.fromJson(Map<String, dynamic> json) => _$MemoModelTopicFromJson(json);

  /// Converts this MemoModelTopic instance into a map.
  /// The returned map can be
  /// Linter-friendly too.
  Map<String, dynamic> toJson() => _$MemoModelTopicToJson(this);

  // Your existing static dummy data method
  static MemoModelTopic createDummy() {
    return MemoModelTopic(
      followerCount: 12,
      postCount: 0,
      lastPost: "13.09.2001 23:22", // Consider DateTime for this
      id: "Super Topic", // This will become "Super_Topic" due to the constructor
      url: "https://memo.cash/topic/Bitcoin+Map",
    );
  }

  // Getters are not part of JSON serialization by default
  String get header {
    return id; // This will return the ID with underscores
  }

  // It's good practice to implement equals and hashCode if you plan to store
  // these objects in Sets or use them as keys in Maps, especially if 'id' is unique.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MemoModelTopic && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
