// repositories/creator_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/scraper/memo_creator_service.dart';
import 'package:mahakka/providers/creator_cache_provider.dart';

import '../memo/firebase/creator_service.dart'; // Your Firebase service

class CreatorRepository {
  final Ref ref;

  CreatorRepository(this.ref);

  Future<MemoModelCreator?> getCreator(String creatorId) async {
    // 1. Check in-memory cache first
    final creatorCache = ref.read(creatorCacheProvider);
    if (creatorCache.containsKey(creatorId)) {
      print("INFO: Fetched creator $creatorId from cache.");
      return creatorCache[creatorId];
    }

    // 2. Not in cache, check Firebase
    final firebaseCreator = await ref.read(creatorServiceProvider).getCreatorOnce(creatorId);
    if (firebaseCreator != null) {
      print("INFO: Fetched creator $creatorId from Firebase. Saving to cache.");
      await firebaseCreator.refreshUserData();
      // Save to cache
      _saveToCache(firebaseCreator);
      return firebaseCreator;
    }

    // 3. Not in Firebase, scrape the data
    print("INFO: Creator $creatorId not found. Scraping from website.");
    final scraperService = MemoCreatorService();
    // Create a barebones creator model to pass to the scraper
    final scrapedCreator = await scraperService.fetchCreatorDetails(MemoModelCreator(id: creatorId));

    if (scrapedCreator != null) {
      print("INFO: Scraped data for creator $creatorId. Saving to Firebase and cache.");
      // Persist the newly scraped data to Firebase
      await ref.read(creatorServiceProvider).saveCreator(scrapedCreator);
      // Save to cache
      _saveToCache(scrapedCreator);
      return scrapedCreator;
    }

    print("WARNING: Could not find or scrape creator $creatorId.");
    return null; // Return null if all sources fail
  }

  // New method to refresh and cache the creator's avatar.
  Future<String?> refreshAndCacheAvatar(String creatorId) async {
    final creatorCache = ref.read(creatorCacheProvider);

    // Get the creator from the cache.
    final creator = creatorCache[creatorId];
    if (creator == null) {
      // If creator is not in cache, you might need to fetch it first.
      // For simplicity, we assume the getCreator call has already been made.
      return null;
    }

    // Call the network request to refresh the avatar.
    await creator.refreshAvatar();

    // Update the creator in the cache with the new avatar URL.
    if (creator.profileImageAvatar().isNotEmpty) {
      _saveToCache(creator);
      return creator.profileImageAvatar();
    }
    return null;
  }

  void _saveToCache(MemoModelCreator creator) {
    ref.read(creatorCacheProvider.notifier).update((state) {
      state[creator.id] = creator;
      return state;
    });
  }
}

final creatorRepositoryProvider = Provider((ref) => CreatorRepository(ref));
