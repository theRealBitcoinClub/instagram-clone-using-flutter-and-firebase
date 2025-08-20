import 'package:flutter/material.dart';
import 'package:instagram_clone1/route%20handling/auth_page.dart';
import 'memoscraper/memo_scraper_posts.dart';
import 'memoscraper/memo_scraper_tag.dart';
import 'memoscraper/memo_scraper_topics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );
  final String cacheId = "250819";
  MemoScraperTopic().startScrapeTopics(cacheId, 25);
  // MemoScraperCreator().startScrapeCreators(["/most-actions", "/most-followers"]);
  //TODO SEND CASHTOKENS WITH EVERY TRANSACTION, PEOPLE EARN TOKENS FOR INTERACTING WITH THE APP ONCE EVERY 144 blocks
  //TODO SEND NOTIFICATIONS TO REMIND USERS TO POST SOMETHING TO EARN MORE TOKEN
  //TODO SEND ALL TRANSACTIONS TWICE, PUBLISH ON A PUBLIC PROFILE/TOPIC/HASHTAG AND ON THE USERS PROFILE/TOPIC/HASHTAG
  //TODO TEST IF APP WILL BE DOWNLOADED AND USED, ADD DATABASE LATER
  //TODO SHOW CONFETTI ON LIKE AND REPLY
  //TODO ADD INPUT FOR WIF, ADD USER REGISTRATION WITH GENERATE SEED PHRASE
  //TODO SHOW SCRAPING PROGRESS, SHOW TUTORIAL VIDEO ON START
  //TODO REMOVE ADD CONTENT TAB, REPLACE WITH SORTED TAB LIKE PROFILE BUT FOR ALL CONTENT
  //TODO ADD ACTION TO OPEN POSTCARD ON CLICK OF PROFILE CONTENT
  //TODO ADD OPTION TO POST CONTENT WITH THE FANCY USERNAME TAG AND HASHTAG SEARCHBAR
  // TODO IDENTIFY CREATORS PUT THEM INTO THE TOSTORE PACKAGE DB
  //https://memo.cash/posts/top?range=1y
  //TODO HISTORICAL POSTS SHALL BE INCLUDED DESPITE BEING TEXT ONLY
  //https://memo.cash/posts/top?range=all&offset=25
  // MemoScraperTag().startScrapeTags(["/most-posts"], 250, cacheId);
  // MemoScraperTag().startScrapeTags(["/recent","/most-posts"], 25, cacheId);
  MemoScraperTag().startScrapeTags(["/most-posts"], 0, cacheId);
  MemoScraperTag().startScrapeTags(["/recent"], 0, cacheId);
  MemoScraperPost().startScrapePosts('posts/new', 100, cacheId);
  // https://memo.cash/tags/most-posts?&offset=1025
  //TODO SHOW SOME TUTORIAL STUFF WHILE INITIAL SCRAPING
  //TODO CACHE SCRAPING RESULTS IN LOCAL DATABASE
  //TODO SHOW SCRAPING PROGRESS BAR, CALL SETSTATE MORE OFTEN

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
