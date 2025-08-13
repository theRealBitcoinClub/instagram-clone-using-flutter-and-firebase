import 'package:flutter/material.dart';
import 'package:instagram_clone1/provider/user_provider.dart';
import 'package:instagram_clone1/route%20handling/auth_page.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform
  // );
  //TODO SCRAPE MEMO, FILL LOCAL MEMORY DATABASE
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_)=> UserProvider(),)
      ],
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Memogram',
          // theme: ThemeData.dark()
          //     .copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
          home: const AuthPage(),
              ),
    );
  }
}
