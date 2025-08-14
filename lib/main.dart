import 'package:flutter/material.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper.dart';
import 'package:instagram_clone1/route%20handling/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );
  //TODO SCRAPE MEMO, FILL LOCAL MEMORY DATABASE
  MemoScraper().startMemoScraper();
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
