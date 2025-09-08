// repositories/creator_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/scraper/memo_creator_service.dart';
import 'package:mahakka/providers/creator_cache_provider.dart';

class CreatorRepository {
  final Ref ref;
  final CreatorCacheRepository _cacheRepository;

  CreatorRepository(this.ref) : _cacheRepository = ref.read(creatorCacheRepositoryProvider);

  Future<MemoModelCreator?> getCreator(String creatorId, {bool scrapeIfNotFound = true, bool saveToFirebase = true}) async {
    // Rely on the cache repository to get data from cache
    var cachedCreator = await _cacheRepository.getCreator(creatorId);
    if (cachedCreator != null) {
      return cachedCreator;
    }

    final firebaseCreator = await ref.read(creatorServiceProvider).getCreatorOnce(creatorId);
    if (firebaseCreator != null) {
      print("INFO: Fetched creator $creatorId from Firebase. Saving to cache.");
      // await firebaseCreator.refreshUserData(ref);
      _cacheRepository.saveCreator(firebaseCreator);
      return firebaseCreator;
    }

    if (!scrapeIfNotFound) return MemoModelCreator(id: creatorId, name: "not found in cache");

    print("INFO: Creator $creatorId not found. Scraping from website.");
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);

    if (scrapedCreator != null) {
      print("INFO: Scraped data for creator $creatorId. Saving to Firebase and cache.");
      if (saveToFirebase) await ref.read(creatorServiceProvider).saveCreator(scrapedCreator);
      _cacheRepository.saveCreator(scrapedCreator);
      return scrapedCreator;
    }

    print("WARNING: Could not find or scrape creator $creatorId.");
    return null;
  }

  Future<void> saveCreator(MemoModelCreator creator) async {
    await ref.read(creatorServiceProvider).saveCreator(creator);
    _cacheRepository.saveCreator(creator);
  }

  Future<String?> refreshAndCacheAvatar(String creatorId, {forceRefreshAfterProfileUpdate = false, String? forceImageType}) async {
    // Get a direct reference to the cached creator from the cache repository
    final creator = await _cacheRepository.getCreator(creatorId);
    if (creator == null) return null;
    String oldUrl = creator.profileImageAvatar();

    await creator.refreshAvatar(forceRefreshAfterProfileUpdate: forceRefreshAfterProfileUpdate, forceImageType: forceImageType);

    if (creator.profileImageAvatar().isNotEmpty && creator.profileImageAvatar() != oldUrl) {
      if (forceRefreshAfterProfileUpdate) await ref.read(creatorServiceProvider).saveCreator(creator);
      _cacheRepository.saveCreator(creator);
      return creator.profileImageAvatar();
    }
    return oldUrl;
  }

  Future<void> refreshCreatorCache(String creatorId, hasUpdatedCallback, nothingChangedCallback, scrapeFailedCallback) async {
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);
    if (scrapedCreator == null) {
      scrapeFailedCallback();
      return;
    }

    final cachedCreator = await _cacheRepository.getCreator(creatorId);

    // Check if data has changed
    final hasSameData =
        cachedCreator != null && scrapedCreator.name == cachedCreator.name && scrapedCreator.profileText == cachedCreator.profileText;

    if (hasSameData) {
      nothingChangedCallback();
      return;
    }

    // Update creator data
    final updatedCreator = cachedCreator?.copyWith(name: scrapedCreator.name, profileText: scrapedCreator.profileText) ?? scrapedCreator;

    print("INFO: Scraped new data for creator $creatorId. Saving to Firebase and cache.");

    // Save to both Firebase and cache
    await ref.read(creatorServiceProvider).saveCreator(updatedCreator);
    await _cacheRepository.saveCreator(updatedCreator);

    hasUpdatedCallback();
  }

  Future<MemoModelCreator?> _getFreshScrapedCreator(String creatorId) async {
    // The `getCreator` method is still used here for the full data flow.
    var cachedCreator = await getCreator(creatorId, saveToFirebase: false, scrapeIfNotFound: false);
    final scraperService = MemoCreatorService();
    final scrapedCreator = await scraperService.fetchCreatorDetails(cachedCreator!, noCache: true);
    return scrapedCreator;
  }

  /// -----------------------------------------------------------
  /// Methods for Profile Updates
  /// -----------------------------------------------------------

  Future<dynamic> profileSetName(String name, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(name).verifyUserName();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = ref.read(memoAccountantProvider);
    final response = await accountant.profileSetName(name);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator;
        updatedCreator.name = name;
        await saveCreator(updatedCreator);
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
        // case MemoAccountantResponse.failed:
        return MemoAccountantResponse.lowBalance;
    }
  }

  //TODO only save once if user updates text, name, even image same time
  Future<dynamic> profileSetText(String text, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(text).verifyProfileText();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = ref.read(memoAccountantProvider);
    final response = await accountant.profileSetText(text);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator;
        updatedCreator.profileText = text;
        await saveCreator(updatedCreator);
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
        // case MemoAccountantResponse.failed:
        return MemoAccountantResponse.lowBalance;
    }
  }

  Future<dynamic> profileSetAvatar(String imgur, MemoModelUser user) async {
    String verifiedUrl = await MemoVerifier(imgur).verifyProfileAvatar();
    if (verifiedUrl == MemoVerificationResponse.noImageNorVideo.toString()) {
      return verifiedUrl;
    }

    final accountant = ref.read(memoAccountantProvider);
    final response = await accountant.profileSetAvatar(verifiedUrl);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator;
        updatedCreator.profileImgurUrl = verifiedUrl;
        await saveCreator(updatedCreator);
        //TODO if user has profile from mahakka display that one
        // await refreshAndCacheAvatar(imgur.split(".").last);
        //TODO refresh detail image too
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
        // case MemoAccountantResponse.failed:
        return MemoAccountantResponse.lowBalance;
    }
  }
}

final creatorRepositoryProvider = Provider((ref) => CreatorRepository(ref));
