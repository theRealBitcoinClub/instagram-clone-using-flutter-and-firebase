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

  CreatorRepository(this.ref);

  MemoModelCreator? _getCreatorFromCache(String creatorId) {
    final creatorCache = ref.read(creatorCacheProvider);
    if (creatorCache.containsKey(creatorId)) {
      print("INFO: Fetched creator $creatorId from cache.");
      return creatorCache[creatorId];
    }
    return null;
  }

  Future<MemoModelCreator?> getCreator(String creatorId, {bool scrapeIfNotFound = true, bool saveToFirebase = true}) async {
    var cachedCreator = _getCreatorFromCache(creatorId);
    if (cachedCreator != null) return cachedCreator;

    final firebaseCreator = await ref.read(creatorServiceProvider).getCreatorOnce(creatorId);
    if (firebaseCreator != null) {
      print("INFO: Fetched creator $creatorId from Firebase. Saving to cache.");
      await firebaseCreator.refreshUserData();
      _saveToCache(firebaseCreator);
      return firebaseCreator;
    }

    if (!scrapeIfNotFound) return MemoModelCreator(id: "no creator found in cache nor fb");

    print("INFO: Creator $creatorId not found. Scraping from website.");
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);

    if (scrapedCreator != null) {
      print("INFO: Scraped data for creator $creatorId. Saving to Firebase and cache.");
      if (saveToFirebase) await ref.read(creatorServiceProvider).saveCreator(scrapedCreator);
      _saveToCache(scrapedCreator);
      return scrapedCreator;
    }

    print("WARNING: Could not find or scrape creator $creatorId.");
    return null;
  }

  Future<void> saveCreator(MemoModelCreator creator) async {
    await ref.read(creatorServiceProvider).saveCreator(creator);
    _saveToCache(creator);
  }

  Future<String?> refreshAndCacheAvatar(String creatorId, {forceRefreshAfterProfileUpdate = false, String? forceImageType}) async {
    final creatorCache = ref.read(creatorCacheProvider);
    final creator = creatorCache[creatorId];
    if (creator == null) return null;
    String oldUrl = creator.profileImageAvatar();

    await creator.refreshAvatar(forceRefreshAfterProfileUpdate: forceRefreshAfterProfileUpdate, forceImageType: forceImageType);

    if (creator.profileImageAvatar().isNotEmpty && creator.profileImageAvatar() != oldUrl) {
      if (forceRefreshAfterProfileUpdate) await ref.read(creatorServiceProvider).saveCreator(creator);

      _saveToCache(creator);
      return creator.profileImageAvatar();
    }
    return oldUrl;
  }

  Future<void> refreshCreatorCache(String creatorId, hasUpdatedCallback, nothingChangedCallback) async {
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);
    MemoModelCreator? cachedCreator = _getCreatorFromCache(creatorId);
    MemoModelCreator updatedCreator = MemoModelCreator(id: "update failed", name: "update failed", profileText: "please retry");
    bool hasSameData = false;

    if (cachedCreator != null && scrapedCreator != null) {
      if (scrapedCreator.name == cachedCreator.name && scrapedCreator.profileText == cachedCreator.profileText) {
        hasSameData = true;
      }
      updatedCreator = cachedCreator.copyWith(profileText: scrapedCreator.profileText, name: scrapedCreator.name);
      print("REFRESH: Creator $creatorId not found in cache.");
    }

    if (scrapedCreator != null && !hasSameData) {
      print("INFO: Scraped data for creator $creatorId. Saving to Firebase and cache.");
      await ref.read(creatorServiceProvider).saveCreator(updatedCreator);
      _saveToCache(updatedCreator);
      hasUpdatedCallback();
    }
    nothingChangedCallback();
  }

  Future<MemoModelCreator?> _getFreshScrapedCreator(String creatorId) async {
    var cachedCreator = await getCreator(creatorId, saveToFirebase: false);
    final scraperService = MemoCreatorService();
    final scrapedCreator = await scraperService.fetchCreatorDetails(cachedCreator!, noCache: true);
    return scrapedCreator;
  }

  /// -----------------------------------------------------------
  /// New Methods for Profile Updates
  /// -----------------------------------------------------------

  Future<dynamic> profileSetName(String name, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(name).verifyUserName();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = MemoAccountant(user);
    final response = await accountant.profileSetName(name);

    switch (response) {
      case MemoAccountantResponse.yes:
        // Update the user's creator property and then save to Firebase and cache
        final updatedCreator = user.creator;
        // user.creator.copyWith()
        // if (updatedCreator != null) {
        updatedCreator.name = name;
        //the creator passed here is the up to date creator from previus method
        //TODO needs some update method, retrieve from cache and update firebase and cache
        await saveCreator(updatedCreator);
        // await refreshCreatorCache(updatedCreator.id, hasUpdatedCallback)
        // await refreshAndCacheAvatar(updatedCreator.id);
        // }
        return "success";
      case MemoAccountantResponse.noUtxo:
        return response.message;
      case MemoAccountantResponse.lowBalance:
        return response.message;
      case MemoAccountantResponse.dust:
        return response.message;
      case MemoAccountantResponse.failed:
        return response.message;
    }
  }

  Future<dynamic> profileSetText(String text, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(text).verifyProfileText();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = MemoAccountant(user);
    final response = await accountant.profileSetText(text);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator;
        // if (updatedCreator != null) {
        updatedCreator.profileText = text;
        //TODO needs some update method, retrieve from cache and update firebase and cache
        await saveCreator(updatedCreator);
        // await refreshAndCacheAvatar(updatedCreator.id);
        // }
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
      case MemoAccountantResponse.failed:
        return response.message;
    }
  }

  Future<dynamic> profileSetAvatar(String imgur, MemoModelUser user) async {
    String verifiedUrl = await MemoVerifier(imgur).verifyProfileAvatar();
    if (verifiedUrl == MemoVerificationResponse.noImageNorVideo.toString()) {
      return verifiedUrl;
    }

    final accountant = MemoAccountant(user);
    final response = await accountant.profileSetAvatar(verifiedUrl);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator;
        // if (updatedCreator != null) {
        //TODO better retrieve images from imgur than memo? but then what happens if user update image on memo
        updatedCreator.profileImgurUrl = verifiedUrl;
        //TODO needs some update method, retrieve from cache and update firebase and cache
        await saveCreator(updatedCreator);
        await refreshAndCacheAvatar(updatedCreator.id, forceRefreshAfterProfileUpdate: true, forceImageType: verifiedUrl.split('.').last);
        // }
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
      case MemoAccountantResponse.failed:
        return response.message;
    }
  }

  void _saveToCache(MemoModelCreator creator) {
    ref.read(creatorCacheProvider.notifier).update((state) {
      state[creator.id] = creator;
      return state;
    });
  }
}

final creatorRepositoryProvider = Provider((ref) => CreatorRepository(ref));
