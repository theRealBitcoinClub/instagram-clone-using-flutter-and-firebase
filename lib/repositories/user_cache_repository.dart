// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:isar_community/isar.dart';
// import 'package:mahakka/memo/model/memo_model_user.dart';
//
// import '../memo/isar/memo_model_user_db.dart';
// import '../provider/isar_provider.dart';
//
// class UserCacheRepository {
//   final Ref ref;
//   final Map<String, MemoModelUser> _inMemoryCache = {};
//
//   UserCacheRepository(this.ref);
//
//   Future<Isar> get _isar async => await ref.read(isarProvider.future);
//
//   /// Gets a user from cache
//   Future<MemoModelUser?> getUser(String userId) async {
//     // In-memory cache
//     if (_inMemoryCache.containsKey(userId)) {
//       return _inMemoryCache[userId];
//     }
//
//     // Isar cache
//     final isar = await _isar;
//     final cachedUser = await isar.memoModelUserDbs.where().userIdEqualTo(userId).findFirst();
//
//     if (cachedUser != null) {
//       final user = cachedUser.toPartialAppModel();
//       _inMemoryCache[userId] = user;
//       return user;
//     }
//
//     return null;
//   }
//
//   /// Saves a user to cache
//   Future<void> saveUser(MemoModelUser user) async {
//     final isar = await _isar;
//
//     await isar.writeTxn(() async {
//       await isar.memoModelUserDbs.put(MemoModelUserDb.fromAppModel(user));
//     });
//
//     _inMemoryCache[user.id] = user;
//   }
//
//   /// Updates user balances in cache
//   Future<void> updateBalances(String userId, {String? cashtokens, String? bchDevPath145, String? bchDevPath0Memo}) async {
//     final isar = await _isar;
//
//     await isar.writeTxn(() async {
//       final userDb = await isar.memoModelUserDbs.where().userIdEqualTo(userId).findFirst();
//
//       if (userDb != null) {
//         userDb.balanceCashtokensDevPath145 = cashtokens ?? userDb.balanceCashtokensDevPath145;
//         userDb.balanceBchDevPath145 = bchDevPath145 ?? userDb.balanceBchDevPath145;
//         userDb.balanceBchDevPath0Memo = bchDevPath0Memo ?? userDb.balanceBchDevPath0Memo;
//
//         await isar.memoModelUserDbs.put(userDb);
//       }
//     });
//
//     // Update in-memory cache if present
//     if (_inMemoryCache.containsKey(userId)) {
//       final user = _inMemoryCache[userId]!;
//       user.balanceCashtokensDevPath145 = cashtokens ?? user.balanceCashtokensDevPath145;
//       user.balanceBchDevPath145 = bchDevPath145 ?? user.balanceBchDevPath145;
//       user.balanceBchDevPath0Memo = bchDevPath0Memo ?? user.balanceBchDevPath0Memo;
//     }
//   }
//
//   /// Clears user cache
//   Future<void> clearUserCache(String userId) async {
//     final isar = await _isar;
//
//     await isar.writeTxn(() async {
//       await isar.memoModelUserDbs.where().userIdEqualTo(userId).deleteAll();
//     });
//
//     _inMemoryCache.remove(userId);
//   }
// }
//
// final userCacheRepositoryProvider = Provider((ref) => UserCacheRepository(ref));
