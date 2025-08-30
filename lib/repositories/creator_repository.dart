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

  Future<MemoModelCreator?> getCreator(String creatorId) async {
    final creatorCache = ref.read(creatorCacheProvider);
    if (creatorCache.containsKey(creatorId)) {
      print("INFO: Fetched creator $creatorId from cache.");
      return creatorCache[creatorId];
    }

    final firebaseCreator = await ref.read(creatorServiceProvider).getCreatorOnce(creatorId);
    if (firebaseCreator != null) {
      print("INFO: Fetched creator $creatorId from Firebase. Saving to cache.");
      await firebaseCreator.refreshUserData();
      _saveToCache(firebaseCreator);
      return firebaseCreator;
    }

    print("INFO: Creator $creatorId not found. Scraping from website.");
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);

    if (scrapedCreator != null) {
      print("INFO: Scraped data for creator $creatorId. Saving to Firebase and cache.");
      await ref.read(creatorServiceProvider).saveCreator(scrapedCreator);
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

  Future<String?> refreshAndCacheAvatar(String creatorId) async {
    final creatorCache = ref.read(creatorCacheProvider);
    final creator = creatorCache[creatorId];
    if (creator == null) return null;

    await creator.refreshAvatar();

    if (creator.profileImageAvatar().isNotEmpty) {
      _saveToCache(creator);
      return creator.profileImageAvatar();
    }
    return null;
  }

  Future<void> refreshCreatorCache(String creatorId, hasUpdatedCallback) async {
    final scrapedCreator = await _getFreshScrapedCreator(creatorId);

    if (scrapedCreator != null) {
      print("INFO: Scraped data for creator $creatorId. Saving to Firebase and cache.");
      await ref.read(creatorServiceProvider).saveCreator(scrapedCreator);
      _saveToCache(scrapedCreator);
      hasUpdatedCallback();
    }
  }

  Future<MemoModelCreator?> _getFreshScrapedCreator(String creatorId) async {
    final scraperService = MemoCreatorService();
    final scrapedCreator = await scraperService.fetchCreatorDetails(MemoModelCreator(id: creatorId), noCache: true);
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
        if (updatedCreator != null) {
          updatedCreator.name = name;
          await saveCreator(updatedCreator);
          await refreshAndCacheAvatar(updatedCreator.id);
        }
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
        if (updatedCreator != null) {
          updatedCreator.profileText = text;
          await saveCreator(updatedCreator);
          await refreshAndCacheAvatar(updatedCreator.id);
        }
        return "success";
      case MemoAccountantResponse.noUtxo:
      case MemoAccountantResponse.lowBalance:
      case MemoAccountantResponse.dust:
      case MemoAccountantResponse.failed:
        return response.message;
    }
  }

  Future<dynamic> profileSetAvatar(String imgur, MemoModelUser user) async {
    final verificationResponse = MemoVerifier(imgur).verifyImgur();
    if (verificationResponse != MemoVerificationResponse.valid) {
      return verificationResponse;
    }

    final accountant = MemoAccountant(user);
    final response = await accountant.profileSetAvatar(imgur);

    switch (response) {
      case MemoAccountantResponse.yes:
        final updatedCreator = user.creator;
        if (updatedCreator != null) {
          // updatedCreator.profileImgurUrl = imgur;
          await saveCreator(updatedCreator);
          await refreshAndCacheAvatar(updatedCreator.id);
        }
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
