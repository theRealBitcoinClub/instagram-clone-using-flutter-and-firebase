// Import your Isar model files to access the generated schemas
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/memo/isar/memo_model_creator_db.dart';
import 'package:path_provider/path_provider.dart';

import '../memo/isar/cached_translation_db.dart';
import '../memo/isar/memo_model_post_db.dart';

// Create a provider for Isar instance
// final isarProvider = FutureProvider<Isar>((ref) async {
//   // Get the application documents directory
//   final dir = await getApplicationDocumentsDirectory();
//
//   final isar = await Isar.open(
//     directory: dir.path,
//     [MemoModelPostDbSchema, MemoModelCreatorDbSchema], // Use the correct generated schema names
//     name: 'mahakka_db',
//   );
//   return isar;
// });

// Update your existing Isar provider to include the new schema:
// isar_provider.dart
final creatorIsarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(directory: dir.path, [
    MemoModelCreatorDbSchema,
    CachedTranslationDbSchema, // Add the new schema
  ], name: 'creators');
  return isar;
});

final translationIsarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(directory: dir.path, [
    MemoModelCreatorDbSchema,
    CachedTranslationDbSchema, // Add the new schema
  ], name: 'translations');
  return isar;
});

// In your isar_provider.dart
final feedPostsIsarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    directory: dir.path,
    [MemoModelPostDbSchema],
    name: 'feed_posts', // Different database name
  );
});

final profilePostsIsarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    directory: dir.path,
    [MemoModelPostDbSchema],
    name: 'profile_posts', // Different database name
  );
});
