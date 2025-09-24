// lib/repositories/creator_repository.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/isar/memo_model_creator_db.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/scraper/memo_creator_scraper.dart';
import 'package:mahakka/provider/isar_provider.dart';

class CreatorRepository {
  final Ref ref;
  final Map<String, MemoModelCreator> _inMemoryCache = {};
  final Map<String, StreamController<MemoModelCreator?>> _creatorStreamControllers = {};

  CreatorRepository(this.ref);

  Future<Isar> get _isar async => await ref.read(isarProvider.future);

  // --- STREAM SUPPORT ---

  /// Get a stream that emits whenever a creator is updated
  Stream<MemoModelCreator?> watchCreator(String creatorId) {
    if (!_creatorStreamControllers.containsKey(creatorId)) {
      _creatorStreamControllers[creatorId] = StreamController<MemoModelCreator?>.broadcast(
        onCancel: () {
          // Auto-close when no listeners remain
          if (_creatorStreamControllers[creatorId]?.hasListener == false) {
            _creatorStreamControllers[creatorId]?.close();
            _creatorStreamControllers.remove(creatorId);
            print("INFO: Disposed stream controller for creator $creatorId");
          }
        },
      );
    }
    return _creatorStreamControllers[creatorId]!.stream;
  }

  /// Notify listeners that a creator has been updated
  void _notifyCreatorUpdated(String creatorId, MemoModelCreator? creator) {
    final controller = _creatorStreamControllers[creatorId];
    if (controller != null && !controller.isClosed) {
      // Check if there are active listeners before sending
      if (controller.hasListener) {
        controller.add(creator);
        print("INFO: Notified stream listeners for creator $creatorId");
      } else {
        // No listeners, clean up the controller
        controller.close();
        _creatorStreamControllers.remove(creatorId);
        print("INFO: Cleaned up unused stream controller for creator $creatorId");
      }
    }
  }

  // --- CACHE MANAGEMENT ---

  /// Gets a creator from cache (memory -> Isar)
  Future<MemoModelCreator?> _getFromCache(String creatorId) async {
    // Layer 1: Check in-memory cache
    if (_inMemoryCache.containsKey(creatorId)) {
      print("INFO: Fetched creator $creatorId from in-memory cache.");
      return _inMemoryCache[creatorId];
    }

    // Layer 2: Check Isar cache
    final isar = await _isar;
    final cachedCreator = await isar.memoModelCreatorDbs.where().creatorIdEqualTo(creatorId).findFirst();

    if (cachedCreator != null) {
      print("INFO: Fetched creator $creatorId from Isar cache.");
      final creator = cachedCreator.toAppModel();
      _inMemoryCache[creatorId] = creator; // Populate memory cache
      return creator;
    }

    return null;
  }

  Future<void> saveToCache(MemoModelCreator creator, {bool saveToFirebase = false}) async {
    // Save to Firebase if requested but if so do it first because the single source of truth is firebase
    if (saveToFirebase) {
      await ref.read(creatorServiceProvider).saveCreator(creator);
      print("INFO: Saved creator ${creator.id} to Firebase.");
    }

    final isar = await _isar;

    // Save to Isar
    await isar.writeTxn(() async {
      await isar.memoModelCreatorDbs.put(MemoModelCreatorDb.fromAppModel(creator));
    });
    print("INFO: Saved creator ${creator.id} to Isar cache.");

    // Save to in-memory cache
    _inMemoryCache[creator.id] = creator;
    print("INFO: Saved creator ${creator.id} to in-memory cache.");

    // Notify stream listeners about the update
    _notifyCreatorUpdated(creator.id, creator);
  }

  // --- PUBLIC API ---

  Future<MemoModelCreator?> getCreator(
    String creatorId, {
    bool saveToFirebase = false,
    bool forceScrape = false,
    bool useCache = true, // New parameter to control cache usage
  }) async {
    // Step 1: Try cache (unless forced to scrape)
    if (useCache && !forceScrape) {
      final cachedCreator = await _getFromCache(creatorId);
      if (cachedCreator != null) {
        return cachedCreator;
      }
    }

    var resultCreator = MemoModelCreator(id: creatorId, name: "Loading...");

    final firebaseCreator = await ref.read(creatorServiceProvider).getCreatorOnce(creatorId);
    if (firebaseCreator != null) {
      print("INFO: Fetched creator $creatorId from Firebase. Saving to cache.");
      await saveToCache(firebaseCreator, saveToFirebase: false); // Already in Firebase
      resultCreator = firebaseCreator;
    }

    if (firebaseCreator == null || forceScrape) {
      print("INFO: Fetching fresh data for creator $creatorId from scraper.");
      final scrapedCreator = await _getFreshScrapedCreator(creatorId);
      if (scrapedCreator != null) {
        resultCreator = resultCreator.copyWith(profileText: scrapedCreator.profileText, name: scrapedCreator.name);
        await saveToCache(resultCreator, saveToFirebase: saveToFirebase);
      }
    }

    return resultCreator;
  }

  Future<String?> refreshAndCacheAvatar(String creatorId, {bool forceRefreshAfterProfileUpdate = false, String? forceImageType}) async {
    final creator = await _getFromCache(creatorId);
    if (creator == null) return null;

    String oldUrl = creator.profileImageAvatar();
    await creator.refreshAvatar(forceRefreshAfterProfileUpdate: forceRefreshAfterProfileUpdate, forceImageType: forceImageType);

    //TODO MAYBE ADD BOOL TO ONLY SAVE ON PROFILE UPDATES BECAUSE OTHERWISE WHO CARES ABOUT CREATOR BEING ON FIREBASE AS THAT ONLY MATTERS IF THEY ARE REGISTERED USERS WITH CUSTOM IMAGE URL
    if (creator.profileImageAvatar().isNotEmpty && creator.profileImageAvatar() != oldUrl) {
      await saveToCache(creator, saveToFirebase: true);
      return creator.profileImageAvatar();
    }
    return oldUrl;
  }

  Future<void> refreshCreatorCache(
    String creatorId, {
    required hasUpdatedCallback,
    required nothingChangedCallback,
    required scrapeFailedCallback,
  }) async {
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);
    if (scrapedCreator == null) {
      scrapeFailedCallback();
      return;
    }

    final cachedCreator = await _getFromCache(creatorId);

    // Check if data has changed
    final hasSameData =
        cachedCreator != null && scrapedCreator.name == cachedCreator.name && scrapedCreator.profileText == cachedCreator.profileText;

    if (hasSameData) {
      nothingChangedCallback();
      return;
    }

    // Update creator data
    final updatedCreator = cachedCreator?.copyWith(name: scrapedCreator.name, profileText: scrapedCreator.profileText) ?? scrapedCreator;

    print("INFO: New data found for creator $creatorId. Updating all storage layers.");
    await saveToCache(updatedCreator, saveToFirebase: false);
    hasUpdatedCallback();
  }

  // --- PRIVATE METHODS ---

  Future<MemoModelCreator?> _getFreshScrapedCreator(String creatorId) async {
    try {
      // Create minimal creator for scraping
      final baseCreator = MemoModelCreator(id: creatorId, name: "Loading...");
      final scraperService = MemoCreatorScraper();
      return await scraperService.fetchCreatorDetails(baseCreator, noCache: true);
    } catch (e) {
      print("ERROR: Failed to scrape creator $creatorId: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> updateProfile({required MemoModelCreator creator, String? name, String? text, String? avatar}) async {
    try {
      // final creator = user.creator;
      MemoModelCreator updatedCreator = creator;
      bool hasChanges = false;

      // Track individual operation results
      final Map<String, dynamic> successfulChanges = {};
      final Map<String, dynamic> failedChanges = {};

      // Execute blockchain operations SEQUENTIALLY
      if (name != null && name != creator.name) {
        final verification = MemoVerifier(name).verifyUserName();
        if (verification != MemoVerificationResponse.valid) {
          return {'result': verification.toString()};
        }

        final result = await _updateNameOnBlockchain(name);
        if (result == MemoAccountantResponse.yes) {
          successfulChanges['name'] = true;
          hasChanges = true;
        } else {
          failedChanges['name'] = result;
        }
      }

      if (text != null && text != creator.profileText) {
        await Future.delayed(Duration(seconds: 2));
        final verification = MemoVerifier(text).verifyProfileText();
        if (verification != MemoVerificationResponse.valid) {
          return {'result': verification.toString()};
        }

        final result = await _updateTextOnBlockchain(text);
        if (result == MemoAccountantResponse.yes) {
          successfulChanges['text'] = true;
          hasChanges = true;
        } else {
          failedChanges['text'] = result;
        }
      }

      if (avatar != null && avatar != creator.profileImgurUrl) {
        await Future.delayed(Duration(seconds: 2));
        avatar = await MemoVerifier(avatar).verifyAndBuildImgurUrl();
        if (avatar == MemoVerificationResponse.noImageNorVideo.toString()) {
          return {'result': avatar};
        }

        final result = await _updateAvatarOnBlockchain(avatar);
        if (result == MemoAccountantResponse.yes) {
          successfulChanges['avatar'] = true;
          hasChanges = true;
        } else {
          failedChanges['avatar'] = result;
        }
      }

      if (!hasChanges) {
        return {'result': "no_changes"};
      }

      // Apply successful changes to creator object
      updatedCreator = updatedCreator.copyWith(
        name: (successfulChanges.containsKey('name')) ? name : creator.name,
        profileText: (successfulChanges.containsKey('text')) ? text : creator.profileText,
        profileImgurUrl: (successfulChanges.containsKey('avatar')) ? avatar : creator.profileImgurUrl,
      );

      // Save to Firebase if ANY changes were successful
      if (hasChanges) {
        await saveToCache(updatedCreator, saveToFirebase: true);
      }

      // Return both result and updated creator
      if (successfulChanges.isNotEmpty && failedChanges.isEmpty) {
        return {'result': "success", 'updatedCreator': updatedCreator};
      } else if (successfulChanges.isNotEmpty && failedChanges.isNotEmpty) {
        return {'result': "partial_success: failed: ${failedChanges.keys.join(', ')}", 'updatedCreator': updatedCreator};
      } else {
        return {
          'result': "all_failed: ${failedChanges.values.join(', ')}",
          'updatedCreator': creator, // Return original creator since no changes
        };
      }
    } catch (e) {
      print("Error updating profile: $e");
      return {'result': "error: $e"};
    }
  }

  Future<MemoAccountantResponse> _updateNameOnBlockchain(String name) async {
    final accountant = ref.read(memoAccountantProvider);
    return await accountant.profileSetName(name);
  }

  Future<MemoAccountantResponse> _updateTextOnBlockchain(String text) async {
    final accountant = ref.read(memoAccountantProvider);
    return await accountant.profileSetText(text);
  }

  Future<MemoAccountantResponse> _updateAvatarOnBlockchain(String avatar) async {
    final accountant = ref.read(memoAccountantProvider);
    return await accountant.profileSetAvatar(avatar);
  }

  Future<void> refreshUserHasRegistered(MemoModelCreator creator) async {
    creator.refreshUserHasRegistered(ref, this);
  }
}

final creatorRepositoryProvider = Provider((ref) => CreatorRepository(ref));
