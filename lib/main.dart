import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/app_themes.dart';
import 'package:mahakka/firebase_options.dart';
import 'package:mahakka/provider/isar_provider.dart';
import 'package:mahakka/route%20handling/auth_page.dart';
import 'package:mahakka/theme_provider.dart';

void main() async {
  // Load .env file
  await dotenv.load(fileName: "telegram.env");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ThemeState> themeState = ref.watch(themeNotifierProvider);
    final AsyncValue<Isar> isar = ref.watch(isarProvider);

    return isar.when(
      data: (isar) => themeState.when(
        data: (loadedThemeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'mahakka.com',
            theme: loadedThemeState.currentTheme,
            home: const AuthPage(),
          );
        },
        loading: () {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        },
        error: (error, stackTrace) {
          print("Error loading theme in MyApp: $error");
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: darkTheme,
            home: Scaffold(body: Center(child: Text("Error loading application theme."))),
          );
        },
      ),
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (error, stackTrace) {
        print("Error initializing database: $error");
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: Text("Error initializing database"))),
        );
      },
    );
  }
}
