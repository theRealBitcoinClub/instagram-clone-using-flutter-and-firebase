// [1]
// The user has this file open:
// /home/pachamama/github/mahakka/lib/memo/model/memo_model_creator.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/firebase/user_service.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo_data_checker.dart';
import 'package:mahakka/providers/creator_cache_provider.dart';

import '../../provider/electrum_provider.dart';

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
  String bchAddressCashtokenAware = "";

  @JsonKey(includeFromJson: false, includeToJson: false)
  int balanceBch = -1;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int balanceMemo = -1;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int balanceToken = -1;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool _isCheckingAvatar = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool _isCheckingDetail = false;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool hasRegisteredAsUser = false;

  String get profileIdShort => id.substring(1, 5);

  String? profileImgurUrl;

  MemoModelCreator({
    this.id = "",
    this.name = "",
    this.profileText = "",
    this.followerCount = 0,
    this.actions = 0,
    this.created = "",
    this.lastActionDate = "",
    this.profileImgurUrl,
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
  int _hasCheckedUrlAvatarCount = 0;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int _hasCheckedUrlDetailCount = 0;

  // Factory constructor for json_serializable to use for creating instances from JSON
  factory MemoModelCreator.fromJson(Map<String, dynamic> json) => _$MemoModelCreatorFromJson(json);

  // Method for json_serializable to use for converting instances to JSON
  Map<String, dynamic> toJson() => _$MemoModelCreatorToJson(this);

  // --- Your existing methods ---

  Future<bool> refreshAvatar({bool forceRefreshAfterProfileUpdate = false, String? forceImageType}) async {
    return await _checkProfileImageAvatar(forceRefreshAfterProfileUpdate: forceRefreshAfterProfileUpdate, forcedImageType: forceImageType);
  }

  Future<bool> refreshImageDetail() async {
    return await _checkProfileImageDetail();
  }

  /// Fetches the creator using the id and updates the local `creator` field.
  /// Returns true if the creator was successfully fetched and updated, false otherwise.
  Future<MemoModelCreator> refreshCreatorFirebase(Ref ref) async {
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
      final fetchedCreator = await ref.read(creatorServiceProvider).getCreatorOnce(id);
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

  Future<bool> _checkProfileImageAvatar({bool forceRefreshAfterProfileUpdate = false, String? forcedImageType}) async {
    if (forceRefreshAfterProfileUpdate) {
      _profileImageAvatar == null;
      _isCheckingAvatar = false;
      _hasCheckedUrlAvatarCount = 0;
    }

    if (_profileImageAvatar != null || _isCheckingAvatar) return true;
    if (_hasCheckedUrlAvatarCount >= maxCheckImage) return false; // Use >= for safety
    _isCheckingAvatar = true;

    for (String t in imageTypes) {
      if (forcedImageType != null && forcedImageType.toLowerCase() != t) continue;
      if (profileImgurUrl != null && profileImgurUrl!.split(".").last != t) continue;

      String avatarUrl = _profileImageUrl(sizeAvatar, t);
      // Assuming checkUrlReturns404 is available and works as intended
      //we have to make this check to find out if image is jpg or png
      if (!await MemoDataChecker().checkUrlReturns404(avatarUrl)) {
        _profileImageAvatar = avatarUrl;
        //TODO you mixing things here must separate concerns better
        // _creatorService.saveCreator(this);
        _hasCheckedUrlAvatarCount = 0;
        return true;
      }
    }
    _hasCheckedUrlAvatarCount++;
    _isCheckingAvatar = false;
    return false;
  }

  String profileImageDetail() {
    return _profileImageDetail ?? "";
  }

  Future<bool> _checkProfileImageDetail() async {
    if (_profileImageDetail != null || _isCheckingDetail) {
      return true;
    }

    _isCheckingDetail = true;

    if (_hasCheckedUrlDetailCount >= maxCheckImage) return false;

    for (String t in imageTypes) {
      String url = _profileImageUrl(sizeDetail, t);
      if (!await MemoDataChecker().checkUrlReturns404(url)) {
        _profileImageDetail = url;
        // ref.read(creatorServiceProvider).saveCreator(this);
        _hasCheckedUrlDetailCount = 0;
        return true;
      }
    }

    _hasCheckedUrlDetailCount++;
    _isCheckingDetail = false;
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

  Future<void> refreshUserHasRegistered(Ref ref) async {
    MemoModelUser? userData = null;
    if (bchAddressCashtokenAware.isEmpty) {
      userData = await UserService().getUserOnce(id);
      hasRegisteredAsUser = userData != null;
      if (hasRegisteredAsUser) bchAddressCashtokenAware = userData!.bchAddressCashtokenAware;
    } else {
      hasRegisteredAsUser = true;
      // return true; //TODO store the userdata in local cache same as creator to avoid repeating requests for each post
    }
    //TODO check if data changed before save
    ref.read(creatorCacheRepositoryProvider).saveCreator(this);

    refreshBalances(ref);
  }

  Future<void> refreshBalances(Ref ref) async {
    if (hasRegisteredAsUser) {
      await _refreshBalanceMahakka(ref);
      await _refreshBalanceMemo(ref);
    } else {
      await _refreshBalanceMemo(ref);
    }
    //TODO check if balance changed before save
    ref.read(creatorCacheRepositoryProvider).saveCreator(this);
  }

  Future<void> _refreshBalanceMahakka(Ref ref) async {
    final MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    Balance balances = await base.getBalances(bchAddressCashtokenAware);
    balanceBch = balances.bch;
    balanceToken = balances.token;
  }

  Future<void> _refreshBalanceMemo(Ref ref) async {
    final MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    balanceMemo = await base.getBalances(id).then((value) => value.bch);
  }

  MemoModelCreator copyWith({
    String? id,
    String? name,
    String? profileText,
    String? profileImgurUrl,
    int? followerCount,
    int? actions,
    String? created,
    String? lastActionDate,
  }) {
    return MemoModelCreator(
      id: id ?? this.id,
      name: name ?? this.name,
      profileText: profileText ?? this.profileText,
      profileImgurUrl: profileImgurUrl ?? this.profileImgurUrl,
      followerCount: followerCount ?? this.followerCount,
      actions: actions ?? this.actions,
      created: created ?? this.created,
      lastActionDate: lastActionDate ?? this.lastActionDate,
    );
  }
}
