// // test/test_helpers.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:isar_community/isar.dart';
// import 'package:mahakka/main.dart';
// import 'package:mahakka/memo/isar/cached_translation_db.dart';
// import 'package:mahakka/memo/isar/isar_shared_preferences.dart';
// import 'package:mocktail/mocktail.dart';
//
// // Mock classes
// class MockIsarSharedPreferences extends Mock implements IsarSharedPreferences {}
//
// class MockIsar extends Mock implements Isar {}
//
// class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
//
// class MockCollectionReference extends Mock implements CollectionReference {}
//
// class MockQuerySnapshot extends Mock implements QuerySnapshot {}
//
// class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot {}
//
// // Mock Firebase
// class MockFirebaseApp extends Mock implements FirebaseApp {}
//
// void setupFirebaseMocks() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   // Mock Firebase initialization
//   when(() => Firebase.initializeApp()).thenAnswer((_) async => MockFirebaseApp());
// }
//
// ProviderContainer createTestContainer() {
//   final mockPrefs = MockIsarSharedPreferences();
//   final mockIsar = MockIsar();
//   final mockFirestore = MockFirebaseFirestore();
//   final mockCollection = MockCollectionReference();
//   final mockSnapshot = MockQuerySnapshot();
//   final mockDocSnapshot = MockQueryDocumentSnapshot();
//
//   // Setup mock behavior for SharedPreferences
//   when(() => mockPrefs.getString(any())).thenReturn(null);
//   when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
//   when(() => mockPrefs.getBool(any())).thenReturn(null);
//   when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
//   when(() => mockPrefs.getInt(any())).thenReturn(null);
//   when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
//   when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);
//
//   // Setup mock behavior for Firestore
//   when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
//   when(() => mockCollection.where(any(), isEqualTo: any(named: 'isEqualTo'))).thenReturn(mockCollection);
//   when(() => mockCollection.get()).thenAnswer((_) async => mockSnapshot);
//   when(() => mockSnapshot.docs).thenReturn([]);
//
//   // Setup mock behavior for Isar collections
//   when(() => mockIsar.cachedTranslationDbs).thenThrow(UnimplementedError('Mock Isar collection'));
//
//   return ProviderContainer(
//     overrides: [
//       sharedPreferencesProvider.overrideWithValue(mockPrefs),
//       isarProvider.overrideWithValue(mockIsar),
//       // Add more provider overrides as needed
//     ],
//   );
// }
