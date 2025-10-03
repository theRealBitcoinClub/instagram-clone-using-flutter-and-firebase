// [1]
// The user has this file open:
// /home/pachamama/github/mahakka/lib/memo/model/memo_model_creator.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/firebase/user_service.dart';
import 'package:mahakka/memo_data_checker.dart';

import '../../provider/electrum_provider.dart';
import '../../repositories/creator_repository.dart';

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
  String? profileImgurUrl;
  bool hasRegisteredAsUserFixed = false;
  DateTime? lastRegisteredCheck;
  String? profileImageAvatarSerialized;
  String? profileImageDetailSerialized;

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

  String get profileIdShort => id.substring(1, 5);

  String get nameMaxLengthAware {
    return name.isNotEmpty
        ? name.substring(0, name.length < MemoVerifier.maxProfileNameLength ? name.length : MemoVerifier.maxProfileNameLength)
        : id;
  }

  MemoModelCreator({
    this.id = "",
    this.name = "",
    this.profileText = "",
    this.followerCount = 0,
    this.actions = 0,
    this.created = "",
    this.lastActionDate = "",
    this.profileImgurUrl,
    this.bchAddressCashtokenAware = "",
    this.hasRegisteredAsUserFixed = false,
    this.lastRegisteredCheck,
    this.profileImageAvatarSerialized,
    this.profileImageDetailSerialized,
  });

  // Constants are not part of JSON serialization
  static const String sizeAvatar = "128x128";
  static const String sizeDetail = "640x640";
  static const List<String> imageTypes = ["jpg", "png"];
  static const String imageBaseUrl = "https://memo.cash/img/profilepics/";
  static int maxCheckImage = 1; // static fields are not serialized by default

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

  String profileImageAvatar() {
    return profileImgurUrl ?? profileImageAvatarSerialized ?? "";
  }

  Future<bool> _checkProfileImageAvatar({bool forceRefreshAfterProfileUpdate = false, String? forcedImageType}) async {
    if (forceRefreshAfterProfileUpdate) {
      profileImageAvatarSerialized = null;
      _isCheckingAvatar = false;
      _hasCheckedUrlAvatarCount = 0;
    }

    if (profileImageAvatarSerialized != null || _isCheckingAvatar) return true;
    if (_hasCheckedUrlAvatarCount >= maxCheckImage) return false; // Use >= for safety
    _isCheckingAvatar = true;

    for (String t in imageTypes) {
      if (forcedImageType != null && forcedImageType.toLowerCase() != t) continue;
      if (profileImgurUrl != null && profileImgurUrl!.split(".").last != t) continue;

      String avatarUrl = _profileImageUrl(sizeAvatar, t);
      // Assuming checkUrlReturns404 is available and works as intended
      //we have to make this check to find out if image is jpg or png
      if (!await MemoDataChecker().checkUrlReturns404(avatarUrl)) {
        profileImageAvatarSerialized = avatarUrl;
        //TODO you mixing things here must separate concerns better
        // _creatorService.saveCreator(this);
        _hasCheckedUrlAvatarCount = 0;
        _isCheckingAvatar = false;
        return true;
      }
    }
    _hasCheckedUrlAvatarCount++;
    _isCheckingAvatar = false;
    return false;
  }

  String profileImageDetail() {
    return profileImgurUrl ?? profileImageDetailSerialized ?? "";
  }

  Future<bool> _checkProfileImageDetail() async {
    if (profileImageDetailSerialized != null || _isCheckingDetail) {
      return true;
    }

    _isCheckingDetail = true;

    if (_hasCheckedUrlDetailCount >= maxCheckImage) return false;

    for (String t in imageTypes) {
      String url = _profileImageUrl(sizeDetail, t);
      if (!await MemoDataChecker().checkUrlReturns404(url)) {
        profileImageDetailSerialized = url;
        // ref.read(creatorServiceProvider).saveCreator(this);
        _hasCheckedUrlDetailCount = 0;
        _isCheckingDetail = false;
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

  Future<MemoModelCreator> refreshUserHasRegistered(Ref ref, CreatorRepository repository) async {
    // Early return if already registered
    if (hasRegisteredAsUserFixed) {
      print('Creator $id is already registered');
      return this;
    }

    try {
      final userData = await UserService().getUserOnce(id);
      final isNowRegistered = userData != null;

      if (isNowRegistered) {
        // Update the creator with registration info
        hasRegisteredAsUserFixed = true;
        bchAddressCashtokenAware = userData.bchAddressCashtokenAware;

        // Use the passed repository instead of reading from ref
        await repository.saveToCache(this, saveToFirebase: true);
        await refreshBalances(ref, repository);

        print('Creator $id is now registered');
      } else {
        print('Creator $id is not registered yet');
      }

      return this;
    } catch (e) {
      print('Error checking registration status for $id: $e');
      return this;
    }
  }

  Future<void> refreshBalances(Ref ref, CreatorRepository repository) async {
    if (hasRegisteredAsUserFixed) {
      await refreshBalanceMahakka(ref);
      await refreshBalanceMemo(ref);
    } else {
      await refreshBalanceMemo(ref);
    }
  }

  //TODO why is debouncer not working as expected
  Future<void> refreshBalanceMahakka(Ref ref) async {
    final MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    // DebouncedBalanceService debouncedBalanceService = DebouncedBalanceService(balanceService: base);
    Balance balances = await base.getBalances(bchAddressCashtokenAware);
    balanceBch = balances.bch;
    balanceToken = balances.token;
    ref.read(creatorRepositoryProvider).saveToCache(this, saveToFirebase: false);
  }

  Future<void> refreshBalanceMemo(Ref ref) async {
    final MemoBitcoinBase base = await ref.read(electrumServiceProvider.future);
    // DebouncedBalanceService debouncedBalanceService = DebouncedBalanceService(balanceService: base);
    balanceMemo = await base.getBalances(id).then((value) => value.bch);
    ref.read(creatorRepositoryProvider).saveToCache(this, saveToFirebase: false);
  }

  MemoModelCreator copyWith({
    String? id,
    String? name,
    String? profileText,
    int? followerCount,
    int? actions,
    String? created,
    String? lastActionDate,
    String? bchAddressCashtokenAware,
    String? profileImgurUrl,
    bool? hasRegisteredAsUserFixed,
    DateTime? lastRegisteredCheck,
    String? profileImageAvatarSerialized,
    String? profileImageDetailSerialized,
    int? balanceBch,
    int? balanceMemo,
    int? balanceToken,
    bool? isCheckingAvatar,
    bool? isCheckingDetail,
    int? hasCheckedUrlAvatarCount,
    int? hasCheckedUrlDetailCount,
  }) {
    return MemoModelCreator(
        id: id ?? this.id,
        name: name ?? this.name,
        profileText: profileText ?? this.profileText,
        followerCount: followerCount ?? this.followerCount,
        actions: actions ?? this.actions,
        created: created ?? this.created,
        bchAddressCashtokenAware: bchAddressCashtokenAware ?? this.bchAddressCashtokenAware,
        lastActionDate: lastActionDate ?? this.lastActionDate,
        profileImgurUrl: profileImgurUrl ?? this.profileImgurUrl,
        hasRegisteredAsUserFixed: hasRegisteredAsUserFixed ?? this.hasRegisteredAsUserFixed,
        lastRegisteredCheck: lastRegisteredCheck ?? this.lastRegisteredCheck,
        profileImageAvatarSerialized: profileImageAvatarSerialized ?? this.profileImageAvatarSerialized,
        profileImageDetailSerialized: profileImageDetailSerialized ?? this.profileImageDetailSerialized,
      )
      ..balanceBch = balanceBch ?? this.balanceBch
      ..balanceMemo = balanceMemo ?? this.balanceMemo
      ..balanceToken = balanceToken ?? this.balanceToken
      .._isCheckingAvatar = isCheckingAvatar ?? _isCheckingAvatar
      .._isCheckingDetail = isCheckingDetail ?? _isCheckingDetail
      .._hasCheckedUrlAvatarCount = hasCheckedUrlAvatarCount ?? _hasCheckedUrlAvatarCount
      .._hasCheckedUrlDetailCount = hasCheckedUrlDetailCount ?? _hasCheckedUrlDetailCount;
  }
}
