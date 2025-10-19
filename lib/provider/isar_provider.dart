// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:isar_community/isar.dart';
// import 'package:mahakka/memo/isar/memo_model_creator_db.dart';
// import 'package:path_provider/path_provider.dart';
//
// import '../memo/isar/cached_translation_db.dart';
// import '../memo/isar/isar_shared_preferences_model.dart';
// import '../memo/isar/memo_model_post_db.dart';
//
// final _isarInstanceProvider = Provider<Future<Isar>>((ref) async {
//   final dir = await getApplicationDocumentsDirectory();
//   return Isar.open(
//     [MemoModelCreatorDbSchema, MemoModelPostDbSchema, CachedTranslationDbSchema, IsarPreferenceSchema],
//     directory: dir.path,
//     name: 'mahakka_mka',
//     maxSizeMiB: 144,
//   );
// });
//
// final unifiedIsarProvider = FutureProvider<Isar>((ref) async {
//   return ref.read(_isarInstanceProvider);
// });
//
// // // Updated isar_provider.dart with optimized settings
// // final unifiedIsarProvider = FutureProvider<Isar>((ref) async {
// //   final dir = await getApplicationDocumentsDirectory();
// //   return await Isar.open(
// //     [MemoModelCreatorDbSchema, MemoModelPostDbSchema, CachedTranslationDbSchema, IsarPreferenceSchema],
// //     directory: dir.path,
// //     name: 'mahakka_mka',
// //     maxSizeMiB: 144, // 256MB per database
// //     // compactOnLaunch: const CompactCondition(
// //     //   minFileSize: 50 * 1024 * 1024, // 50MB minimum file size
// //     //   minBytes: 10 * 1024 * 1024, // Free at least 10MB
// //     //   minRatio: 1.5, // Compact if we can reduce size by 33%
// //     // ),
// //   );
// // });
//
// // // Updated isar_provider.dart with optimized settings
// // final creatorIsarProvider = FutureProvider<Isar>((ref) async {
// //   final dir = await getApplicationDocumentsDirectory();
// //   return await Isar.open(
// //     [MemoModelCreatorDbSchema],
// //     directory: dir.path,
// //     name: 'creators',
// //     maxSizeMiB: 18, // 256MB per database
// //     // compactOnLaunch: const CompactCondition(
// //     //   minFileSize: 50 * 1024 * 1024, // 50MB minimum file size
// //     //   minBytes: 10 * 1024 * 1024, // Free at least 10MB
// //     //   minRatio: 1.5, // Compact if we can reduce size by 33%
// //     // ),
// //   );
// // });
// //
// // final translationIsarProvider = FutureProvider<Isar>((ref) async {
// //   final dir = await getApplicationDocumentsDirectory();
// //   return await Isar.open(
// //     [CachedTranslationDbSchema],
// //     directory: dir.path,
// //     name: 'translations',
// //     maxSizeMiB: 9, // Smaller since translations are smaller
// //     // compactOnLaunch: const CompactCondition(
// //     //   minFileSize: 20 * 1024 * 1024, // 20MB minimum file size
// //     //   minBytes: 5 * 1024 * 1024, // Free at least 5MB
// //     //   minRatio: 2.0, // Compact if we can halve the size
// //     // ),
// //   );
// // });
// //
// // final feedPostsIsarProvider = FutureProvider<Isar>((ref) async {
// //   final dir = await getApplicationDocumentsDirectory();
// //   return await Isar.open(
// //     [MemoModelPostDbSchema],
// //     directory: dir.path,
// //     name: 'feed_posts',
// //     maxSizeMiB: 36, // Larger for feed posts
// //     // compactOnLaunch: const CompactCondition(
// //     //   minFileSize: 100 * 1024 * 1024, // 100MB minimum file size
// //     //   minBytes: 25 * 1024 * 1024, // Free at least 25MB
// //     //   minRatio: 1.8, // Compact if we can reduce by 45%
// //     // ),
// //   );
// // });
// //
// // final profilePostsIsarProvider = FutureProvider<Isar>((ref) async {
// //   final dir = await getApplicationDocumentsDirectory();
// //   return await Isar.open(
// //     [MemoModelPostDbSchema],
// //     directory: dir.path,
// //     name: 'profile_posts',
// //     maxSizeMiB: 36,
// //     // compactOnLaunch: const CompactCondition(
// //     //   minFileSize: 50 * 1024 * 1024, // 50MB minimum file size
// //     //   minBytes: 10 * 1024 * 1024, // Free at least 10MB
// //     //   minRatio: 1.7, // Compact if we can reduce by 41%
// //     // ),
// //   );
// // });
