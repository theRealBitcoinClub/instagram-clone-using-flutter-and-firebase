import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memo_model_tag.g.dart'; // This file will be generated

// Consider adding @immutable if instances of this class should not change
// after creation, which seems to be the case given all fields are final.
// @immutable
@JsonSerializable()
class MemoModelTag {
  // This static list is for application runtime state and not directly part
  // of the JSON serialization of individual MemoModelTag instances.
  // static List<MemoModelTag> tags = [];
  @JsonKey(includeFromJson: false, includeToJson: false)
  DocumentSnapshot? docSnapshot;

  // --- Factory to include DocumentSnapshot and ID ---
  factory MemoModelTag.fromSnapshot(DocumentSnapshot snap) {
    if (!snap.exists || snap.data() == null) {
      throw Exception("Document ${snap.id} does not exist or has no data.");
    }
    final data = snap.data() as Map<String, dynamic>;
    // The fromJson method correctly handles the JSON map.
    // The id and docSnapshot are then manually assigned.
    return MemoModelTag.fromJson(data)
      ..id = snap.id
      ..docSnapshot = snap;
  }

  MemoModelTag({
    required this.id,
    this.postCount,
    this.lastPost, // Consider if this should be a DateTime for easier sorting/filtering
  });

  String id;
  final int? postCount;
  final String? lastPost; // Again, DateTime might be better for 'lastPost'

  /// Factory constructor for creating a new MemoModelTag instance from a map.
  factory MemoModelTag.fromJson(Map<String, dynamic> json) => _$MemoModelTagFromJson(json);

  /// Converts this MemoModelTag instance into a map.
  Map<String, dynamic> toJson() => _$MemoModelTagToJson(this);

  /// Getter for the name, simply returns the id.
  /// Not part of JSON serialization by default.
  String get name {
    return id;
  }

  // Implementation of equals (==) and hashCode
  // This is crucial if you intend to store these objects in Sets,
  // use them as keys in Maps, or compare them by value.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // Same instance
    if (other is! MemoModelTag) return false; // Different type
    return runtimeType == other.runtimeType && id == other.id;
  }

  @override
  int get hashCode => id.hashCode; // Base hashCode on the 'id' field

  @override
  String toString() {
    // Optional: A helpful toString for debugging
    return 'MemoModelTag(id: $id, postCount: $postCount, lastPost: $lastPost)';
  }

  // Example static method if needed (not related to JSON directly)
  static MemoModelTag createExample() {
    return MemoModelTag(id: "flutter_development", postCount: 150, lastPost: "2023-10-25");
  }
}
