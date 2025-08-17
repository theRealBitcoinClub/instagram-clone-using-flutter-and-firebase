import 'package:flutter/material.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_posts.dart';
import 'package:instagram_clone1/route%20handling/auth_page.dart';

import 'memoscraper/memo_scraper_creator.dart';
import 'memoscraper/memo_scraper_tag.dart';
import 'memoscraper/memo_scraper_topics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );
  //TODO SCRAPE MEMO, FILL LOCAL MEMORY DATABASE
  // MemoScraperTopic().startScrapeTopics();
  // MemoScraperCreator().startScrapeCreators(["/most-actions", "/most-followers"]);
  // TODO IDENTIFY CREATORS PUT THEM INTO THE TOSTORE PACKAGE DB
  // MemoScraperPost().startScrapePosts('posts/new', 100);
  MemoScraperTag().startScrapeTags(["/most-posts"], 0);
  https://memo.cash/tags/most-posts?&offset=1025
  //TODO SHOW SOME TUTORIAL STUFF WHILE INITIAL SCRAPING
  //TODO CACHE SCRAPING RESULTS IN LOCAL DATABASE

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
      // MultiProvider(
      // providers: [
      //   TODO UNDERSTAND USER PROVIDER
      //   ChangeNotifierProvider(create: (_)=> UserProvider(),)
      // ],
      // child:
      return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Memogram',
          // theme: ThemeData.dark()
          //     .copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
          home: const AuthPage());
    // );
  }
}
