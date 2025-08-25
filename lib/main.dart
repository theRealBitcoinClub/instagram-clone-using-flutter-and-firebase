import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:instagram_clone1/memoscraper/memo_creator_service.dart';
import 'package:instagram_clone1/provider/user_provider.dart';
import 'package:instagram_clone1/route%20handling/auth_page.dart';
import 'package:provider/provider.dart';

import 'app_themes.dart';
import 'memoscraper/memo_scraper_posts.dart';
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

initData() async {
  //TODO INITIALIZE USER WIF DATA?

  final String cacheId = "250819";
  await MemoScraperTopic().startScrapeTopics(cacheId, 25);
  await MemoCreatorService().fetchAndProcessCreators(["/most-actions", "/most-followers"]);
  //https://memo.cash/posts/top?range=1y
  //https://memo.cash/posts/top?range=all&offset=25
  // MemoScraperTag().startScrapeTags(["/most-posts"], 250, cacheId);
  // MemoScraperTag().startScrapeTags(["/recent","/most-posts"], 25, cacheId);
  await MemoScraperTag().startScrapeTags(["/most-posts", "/recent"], 0, cacheId);
  // await MemoScraperTag().startScrapeTags(["/recent"], 0, cacheId);
  await MemoScraperPost().startScrapePosts('posts/new', 100, cacheId);
  // https://memo.cash/tags/most-posts?&offset=1025

  FlutterNativeSplash.remove();
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
