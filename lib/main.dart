import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:instagram_clone1/memoscraper/memo_creator_service.dart';
import 'package:instagram_clone1/provider/user_provider.dart';
import 'package:instagram_clone1/route%20handling/auth_page.dart';
import 'package:provider/provider.dart';

import 'app_themes.dart';
import 'memoscraper/memo_post_service.dart';
import 'memoscraper/memo_scraper_tag.dart';
import 'memoscraper/memo_scraper_topics.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );

  initData();
  runApp(const MyApp());
}

Future<void> initData() async {
  // Make it Future<void>
  final String cacheId = "250819";
  print("INFO: Starting initial data fetch...");

  try {
    // List of all futures to run concurrently
    final List<Future<dynamic>> dataFetchingFutures = [
      MemoScraperTopic().startScrapeTopics(cacheId, 25),
      MemoCreatorService().fetchAndProcessCreators(["/most-actions", "/most-followers"]),
      MemoScraperTag().startScrapeTags(["/most-posts", "/recent"], 0, cacheId),
      MemoPostService().scrapePostsPaginated(baseUrl: 'posts/new', initialOffset: 100, cacheId: cacheId),
      // Add any other independent data fetching operations here
    ];

    // Await all futures to complete
    // Future.wait will complete when all futures in the list have completed.
    // If any future in the list throws an error, Future.wait will also complete with that error.
    final List<dynamic> results = await Future.wait(dataFetchingFutures);

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
      providers: [ChangeNotifierProvider(create: (_) => ProviderUser())],
      child: DynamicTheme(
        themeCollection: themeCollection,
        defaultThemeId: AppThemes.LightBlue, // optional, default id is 0
        builder: (context, theme) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Memogram',
            theme: ThemeData(
              //TODO add switch color theme button top left
              // colorScheme: randomColorSchemeDark()
              // textButtonTheme: ,
              // textTheme: ,
              // dialogTheme: ,
              // primaryColorDark: const Color(0xff29d969),
              // primaryColor: const Color(0xff29d969),
              // secondaryHeaderColor: const Color(0xfff69ffb),
              // scaffoldBackgroundColor: const Color(0xff161815),
              // colorScheme: ColorScheme.dark(
            ),
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
