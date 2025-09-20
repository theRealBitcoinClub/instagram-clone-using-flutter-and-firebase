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

  /// Saves a creator to all cache layers (memory + Isar + Firebase optionally)
  Future<void> saveToCache(MemoModelCreator creator, {bool saveToFirebase = false}) async {
    final isar = await _isar;

    // Save to Isar
    await isar.writeTxn(() async {
      await isar.memoModelCreatorDbs.put(MemoModelCreatorDb.fromAppModel(creator));
    });
    print("INFO: Saved creator ${creator.id} to Isar cache.");

    // Save to in-memory cache
    _inMemoryCache[creator.id] = creator;
    print("INFO: Saved creator ${creator.id} to in-memory cache.");

    // Save to Firebase if requested
    if (saveToFirebase) {
      await ref.read(creatorServiceProvider).saveCreator(creator);
      print("INFO: Saved creator ${creator.id} to Firebase.");
    }
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
    await saveToCache(minimalCreator, saveToFirebase: false); // Don't save minimal to Firebase
    return minimalCreator;
  }

  /// Special method for profile widget - always fetches fresh data and updates cache
  Future<MemoModelCreator> getCreatorForProfileWidget(String creatorId) async {
    // Always force fresh scrape for profile widget
    return await getCreator(
          creatorId,
          scrapeIfNotFound: true,
          forceScrape: true,
          saveToFirebase: true,
          useCache: false, // Don't use cache for profile widget
        ) ??
        MemoModelCreator(id: creatorId, name: "Loading...");
  }

  Future<String?> refreshAndCacheAvatar(String creatorId, {bool forceRefreshAfterProfileUpdate = false, String? forceImageType}) async {
    final creator = await _getFromCache(creatorId);
    if (creator == null) return null;

    String oldUrl = creator.profileImageAvatar();
    await creator.refreshAvatar(forceRefreshAfterProfileUpdate: forceRefreshAfterProfileUpdate, forceImageType: forceImageType);

    if (creator.profileImageAvatar().isNotEmpty && creator.profileImageAvatar() != oldUrl) {
      await saveToCache(creator, saveToFirebase: false);
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

  // --- PROFILE UPDATE METHODS ---

  Future<dynamic> profileSetName(String name, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(name).verifyUserName();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = ref.read(memoAccountantProvider);
    final response = await accountant.profileSetName(name);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator.copyWith(name: name);
        await saveToCache(updatedCreator, saveToFirebase: true);
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
        return MemoAccountantResponse.lowBalance;
      case MemoAccountantResponse.connectionError:
        // TODO: Handle this case.
        throw UnimplementedError();
      case MemoAccountantResponse.insufficientBalanceForIpfs:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<dynamic> profileSetText(String text, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(text).verifyProfileText();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = ref.read(memoAccountantProvider);
    final response = await accountant.profileSetText(text);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator.copyWith(profileText: text);
        await saveToCache(updatedCreator, saveToFirebase: true);
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
        return MemoAccountantResponse.lowBalance;
      case MemoAccountantResponse.connectionError:
        // TODO: Handle this case.
        throw UnimplementedError();
      case MemoAccountantResponse.insufficientBalanceForIpfs:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<dynamic> profileSetAvatar(String imgur, MemoModelUser user) async {
    final verifiedUrl = await MemoVerifier(imgur).verifyAndBuildImgurUrl();
    if (verifiedUrl == MemoVerificationResponse.noImageNorVideo.toString()) {
      return verifiedUrl;
    }

    final accountant = ref.read(memoAccountantProvider);
    final response = await accountant.profileSetAvatar(verifiedUrl);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator.copyWith(profileImgurUrl: verifiedUrl);
        await saveToCache(updatedCreator, saveToFirebase: true);
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
        return MemoAccountantResponse.lowBalance;
      case MemoAccountantResponse.connectionError:
        // TODO: Handle this case.
        throw UnimplementedError();
      case MemoAccountantResponse.insufficientBalanceForIpfs:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // --- CACHE MANAGEMENT UTILITIES ---

  Future<void> clearMemoryCache() async {
    _inMemoryCache.clear();
    print("INFO: Cleared in-memory creator cache.");
  }

  Future<void> clearIsarCache() async {
    final isar = await _isar;
    await isar.writeTxn(() async {
      await isar.memoModelCreatorDbs.clear();
    });
    print("INFO: Cleared Isar creator cache.");
  }

  Future<void> clearAllCache() async {
    await clearMemoryCache();
    await clearIsarCache();
    print("INFO: Cleared all creator caches.");
  }

  Future<void> refreshUserHasRegistered(MemoModelCreator creator) async {
    creator.refreshUserHasRegistered(ref);
  }
}

final creatorRepositoryProvider = Provider((ref) => CreatorRepository(ref));
