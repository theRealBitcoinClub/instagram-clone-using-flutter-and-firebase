import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/scraper/memo_scraper_topics.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/route%20handling/auth_page.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'memo/model/memo_model_creator.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initData();
  runApp(const MyApp());
}

Future<void> initData() async {
  // Make it Future<void>
  final String cacheId = "250825";
  print("INFO: Starting initial data fetch...");

  try {
    // int index = 0;
    // for (int off = 525; off <= 1000; off += 25) {
    //   var result = MemoCreatorService().fetchAndProcessCreators(["/most-actions?offset=$off"]);
    //   List<MemoModelCreator> creators = await result;
    //   for (var c in creators) {
    //     CreatorService().saveCreator(c);
    //     index++;
    //   }
    //   sleep(Duration(seconds: 1));
    // }
    int index = 0;
    for (int off = 525; off <= 1000; off += 25) {
      var result = MemoScraperTopic().startScrapeTopics(["/most-actions?offset=$off"]);
      List<MemoModelCreator> creators = await result;
      for (var c in creators) {
        CreatorService().saveCreator(c);
        index++;
      }
      sleep(Duration(seconds: 1));
    }

    print("TOTAL AMOUNT $index");

    // Optional: You can inspect the results if your methods return values
    // For example, if startScrapeTopics returned a list of topics:
    // List<Topic> topics = results[0] as List<Topic>;
    // print("INFO: Fetched ${topics.length} topics.");
    print("INFO: All initial data fetched successfully.");
  } catch (e, stackTrace) {
    // Handle any error that occurred during any of the concurrent operations
    print("ERROR: Failed to fetch initial data: $e");
    print("Stack trace: $stackTrace");
    // You might want to implement retry logic or show an error to the user
  } finally {
    // This will be called whether the operations succeeded or failed
    print("INFO: Removing splash screen.");
    FlutterNativeSplash.remove();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProviderUser()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        // Use Consumer to access ThemeProvider for MaterialApp
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Memogram',
            theme: themeProvider.currentTheme,
            // theme: ThemeData.dark()
            //     .copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
            home: const AuthPage(),
          );
        },
      ),
    );
    // );
  }
}
