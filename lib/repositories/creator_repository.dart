// lib/repositories/creator_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/isar/memo_model_creator_db.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/scraper/memo_creator_scraper.dart';
import 'package:mahakka/provider/isar_provider.dart';

class CreatorRepository {
  final Ref ref;
  final Map<String, MemoModelCreator> _inMemoryCache = {};

  CreatorRepository(this.ref);

  Future<Isar> get _isar async => await ref.read(isarProvider.future);

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
  }

  // --- PUBLIC API ---

  Future<MemoModelCreator?> getCreator(
    String creatorId, {
    bool scrapeIfNotFound = true,
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

    // Step 2: Try Firebase (unless forced to scrape)
    if (!forceScrape) {
      final firebaseCreator = await ref.read(creatorServiceProvider).getCreatorOnce(creatorId);
      if (firebaseCreator != null) {
        print("INFO: Fetched creator $creatorId from Firebase. Saving to cache.");
        await saveToCache(firebaseCreator, saveToFirebase: false); // Already in Firebase
        return firebaseCreator;
      }
    }

    // Step 3: Scrape if requested or nothing found
    if (scrapeIfNotFound || forceScrape) {
      print("INFO: Fetching fresh data for creator $creatorId from scraper.");
      final scrapedCreator = await _getFreshScrapedCreator(creatorId);

      if (scrapedCreator != null) {
        print("INFO: Scraped fresh data for creator $creatorId. Saving to all storage layers.");
        await saveToCache(scrapedCreator, saveToFirebase: saveToFirebase);
        return scrapedCreator;
      }
    }

    // Step 4: Fallback - create minimal creator
    print("WARNING: Could not find creator $creatorId. Creating minimal creator.");
    final minimalCreator = MemoModelCreator(id: creatorId, name: "Loading...");
    //TODO CHECK IF IT MAKES SENSE TO EVER SAVE THIS MINIMAL CREATOR, I DONT THINK SO
    // await saveToCache(minimalCreator, saveToFirebase: false); // Don't save minimal to Firebase
    return minimalCreator;
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

  Future<Map<String, dynamic>> updateProfile({required MemoModelUser user, String? name, String? text, String? avatar}) async {
    try {
      final creator = user.creator;
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
        Future.delayed(Duration(seconds: 3));
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
        Future.delayed(Duration(seconds: 3));
        final verifiedUrl = await MemoVerifier(avatar).verifyAndBuildImgurUrl();
        if (verifiedUrl == MemoVerificationResponse.noImageNorVideo.toString()) {
          return {'result': verifiedUrl};
        }

        final result = await _updateAvatarOnBlockchain(verifiedUrl);
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
    creator.refreshUserHasRegistered(ref);
  }
}

final creatorRepositoryProvider = Provider((ref) => CreatorRepository(ref));
