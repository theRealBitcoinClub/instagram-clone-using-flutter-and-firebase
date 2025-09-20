// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:isar_community/isar.dart';
// import 'package:mahakka/memo/model/memo_model_creator.dart';
//
// import '../memo/isar/memo_model_creator_db.dart';
// import '../provider/isar_provider.dart';
//
// class CreatorCacheRepository {
//   final Ref ref;
//   final Map<String, MemoModelCreator> _inMemoryCache = {};
//
//   CreatorCacheRepository(this.ref);
//
//   Future<Isar> get _isar async => await ref.read(isarProvider.future);
//
//   /// Gets a creator from cache (memory -> Isar -> Firebase)
//   Future<MemoModelCreator?> getCreator(String creatorId) async {
//     // Layer 1: Check in-memory cache
//     if (_inMemoryCache.containsKey(creatorId)) {
//       print("INFO: Fetched creator $creatorId from in-memory cache.");
//       return _inMemoryCache[creatorId];
//     }
//
//     // Layer 2: Check Isar cache
//     final isar = await _isar;
//     final cachedCreator = await isar.memoModelCreatorDbs.where().creatorIdEqualTo(creatorId).findFirst();
//
//     if (cachedCreator != null) {
//       print("INFO: Fetched creator $creatorId from Isar cache.");
//       // Convert back to app model (you'll need to implement this)
//       final creator = cachedCreator.toAppModel();
//       _inMemoryCache[creatorId] = creator;
//       return creator;
//     }
//
//     // Layer 3: Not in cache, return null to fetch from Firebase
//     return null;
//   }
//
//   /// Saves a creator to both Isar and the in-memory cache
//   Future<void> saveCreator(MemoModelCreator creator) async {
//     final isar = await _isar;
//
//     // Save to Isar
//     await isar.writeTxn(() async {
//       await isar.memoModelCreatorDbs.put(MemoModelCreatorDb.fromAppModel(creator));
//     });
//     print("INFO: Saved creator ${creator.id} to Isar cache.");
//
//     // Save to in-memory cache
//     _inMemoryCache[creator.id] = creator;
//     print("INFO: Saved creator ${creator.id} to in-memory cache.");
//   }
// }
//
// final creatorCacheRepositoryProvider = Provider((ref) => CreatorCacheRepository(ref));
