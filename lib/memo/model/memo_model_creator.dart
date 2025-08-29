// [1]
// The user has this file open:
// /home/pachamama/github/mahakka/lib/memo/model/memo_model_creator.dart.
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/check_404.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/firebase/user_service.dart'; // Assuming this is your utility function

part 'memo_model_creator.g.dart'; // This will be generated

@JsonSerializable(explicitToJson: true)
class MemoModelCreator {
  String id; // Mark as late if initialized by fromJson
  String name;
  String profileText = ""; // Provide default values
  int followerCount = 0;
  int actions = 0;
  String created = "";
  String lastActionDate = "";
  final CreatorService _creatorService = CreatorService();

  @JsonKey(ignore: true)
  bool isCheckingAvatar = false;
  @JsonKey(ignore: true)
  bool isCheckingDetail = false;

  String get profileIdShort => id.substring(1, 5);

  MemoModelCreator({
    this.id = "",
    this.name = "",
    this.profileText = "",
    this.followerCount = 0,
    this.actions = 0,
    this.created = "",
    this.lastActionDate = "",
  });

  // Constants are not part of JSON serialization
  static const String sizeAvatar = "128x128";
  static const String sizeDetail = "640x640";
  static const List<String> imageTypes = ["jpg", "png"];
  static const String imageBaseUrl = "https://memo.cash/img/profilepics/";
  static int maxCheckImage = 1; // static fields are not serialized by default

  // These fields are runtime state and should likely not be part of the JSON
  // If they were to be stored, they should probably be part of a different caching mechanism
  // or a user session, not the core creator model persisted in the DB.
  // @JsonKey(includeFromJson: false, includeToJson: false)
  String? _profileImageAvatar;

  // @JsonKey(includeFromJson: false, includeToJson: false)
  String? _profileImageDetail;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int hasCheckedImgAvatar = 0;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int hasCheckedImgDetail = 0;

  // Factory constructor for json_serializable to use for creating instances from JSON
  factory MemoModelCreator.fromJson(Map<String, dynamic> json) => _$MemoModelCreatorFromJson(json);

  // Method for json_serializable to use for converting instances to JSON
  Map<String, dynamic> toJson() => _$MemoModelCreatorToJson(this);

  // --- Your existing methods ---

  Future<bool> refreshAvatar() async {
    return await _checkProfileImageAvatar();
  }

  Future<bool> refreshImageDetail() async {
    return await _checkProfileImageDetail();
  }

  /// Fetches the creator using the id and updates the local `creator` field.
  /// Returns true if the creator was successfully fetched and updated, false otherwise.
  Future<MemoModelCreator> refreshCreatorFirebase() async {
    if (id.isEmpty) {
      print("MemoModelPost (ID: $id): id is empty, cannot refresh creator.");
      // Optionally set this.creator to null if it wasn't already
      // if (this.creator != null) {
      //   this.creator = null;
      // }
      return this; // Or throw an error, depending on desired behavior
    }

    try {
      print("MemoModelPost (ID: $id): Refreshing creator for ID: $id...");
      final fetchedCreator = await _creatorService.getCreatorOnce(id);
      if (fetchedCreator != null) {
        print("MemoModelPost (ID: $id): Creator ${name} (ID: ${id}) refreshed successfully.");
        return fetchedCreator;
      } else {
        print("MemoModelPost (ID: $id): Failed to refresh creator for ID: $id. Creator not found or error during fetch.");
        // Decide if you want to set this.creator to null if the fetch fails
        // this.creator = null;
        return this;
      }
    } catch (e, s) {
      print("MemoModelPost (ID: $id): Error during refreshCreator for ID $id: $e");
      print(s);
      // Decide if you want to set this.creator to null on error
      // this.creator = null;
      return this;
    }
  }

  // These methods below expose the runtime state.
  // The underlying fields (_profileImageAvatar, _profileImageDetail) are not serialized.
  // If you need to persist profile image URLs that are *known* (not dynamically checked),
  // add separate String fields to the class for that purpose and include them in serialization.
  String profileImageAvatar() {
    return _profileImageAvatar ?? "";
  }

  Future<bool> _checkProfileImageAvatar() async {
    if (_profileImageAvatar != null || isCheckingAvatar) return true;
    if (hasCheckedImgAvatar >= maxCheckImage) return false; // Use >= for safety
    isCheckingAvatar = true;

    for (String t in imageTypes) {
      String avatarUrl = _profileImageUrl(sizeAvatar, t);
      // Assuming checkUrlReturns404 is available and works as intended
      if (!await checkUrlReturns404(avatarUrl)) {
        _profileImageAvatar = avatarUrl;
        _creatorService.saveCreator(this);
        hasCheckedImgAvatar = 0;
        return true;
      }
    }
    hasCheckedImgAvatar++;
    isCheckingAvatar = false;
    return false;
  }

  String profileImageDetail() {
    return _profileImageDetail ?? "";
  }

  Future<bool> _checkProfileImageDetail() async {
    if (_profileImageDetail != null || isCheckingDetail) {
      return true;
    }

    isCheckingDetail = true;

    if (hasCheckedImgDetail >= maxCheckImage) return false;

    for (String t in imageTypes) {
      String url = _profileImageUrl(sizeDetail, t);
      if (!await checkUrlReturns404(url)) {
        _profileImageDetail = url;
        _creatorService.saveCreator(this);
        hasCheckedImgDetail = 0;
        return true;
      }
    }

    hasCheckedImgDetail++;
    isCheckingDetail = false;
    return false;
  }

  String _profileImageUrl(String size, String type) {
    return "$imageBaseUrl$id-$size.$type?v=${DateTime.now().millisecondsSinceEpoch}"; // Added 'v=' for cache busting, more standard
  }

  // Consider implementing equals and hashCode if you store these in Sets or use them as Map keys.
  @override
  bool operator ==(Object other) => identical(this, other) || other is MemoModelCreator && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Future<bool> hasRegisteredAsUser() async {
    return await UserService().getUserOnce(id) != null;
  }
}
