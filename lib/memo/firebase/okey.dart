import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/firebase_options.dart'; // Your Firebase options
import 'package:mahakka/memo/firebase/test.dart';

import '../model/memo_model_creator.dart';
import 'creator_service.dart';
// Import your CreatorDisplayPage and CreatorService

// Dummy data creation function for testing (updated)
Future<void> _createSampleCreatorData(CreatorService service, String creatorId) async {
  // Use the static create method or default constructor
  final sampleCreator = MemoModelCreator(
    id: creatorId,
    name: "Initial Creator (Simple Model)",
    profileText: "Profile text for the simpler model.",
    followerCount: 50,
    actions: 20,
    created: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
    lastActionDate: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    // No posts here
  );
  try {
    await service.saveCreator(sampleCreator);
    print("Sample creator data (simple model) created/updated for ID: $creatorId");
  } catch (e) {
    print("Error creating sample data (simple model): $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final CreatorService creatorService = CreatorService(); // Use the real one
  final String testCreatorId = "creatorSimple002";

  // Optional: Create sample data (ensure collection name in service is correct)
  await _createSampleCreatorData(creatorService, testCreatorId);

  runApp(MyApp(creatorId: testCreatorId, creatorService: creatorService));
}

class MyApp extends StatelessWidget {
  final String creatorId;
  final CreatorService creatorService;

  const MyApp({super.key, required this.creatorId, required this.creatorService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Creator Firestore Demo (Simple)',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      home: CreatorDisplayPage(
        // This page is now simpler
        creatorId: creatorId,
        creatorService: creatorService,
      ),
    );
  }
}
