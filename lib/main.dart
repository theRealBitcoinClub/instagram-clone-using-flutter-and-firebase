// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Core Riverpod import
import 'package:mahakka/route%20handling/auth_page.dart';
import 'package:mahakka/theme_provider.dart'; // Assuming path is correct

import 'app_themes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // 1. Wrap your entire application with ProviderScope
    const ProviderScope(child: MyApp()),
  );
}

// 2. MyApp becomes a ConsumerWidget to watch the themeProvider
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 3. Watch the themeNotifierProvider to get the current theme state
    final AsyncValue<ThemeState> themeState = ref.watch(themeNotifierProvider);

    // Handle loading and error states for the theme
    return themeState.when(
      data: (loadedThemeState) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'mahakka.com',
          theme: loadedThemeState.currentTheme, // Use the theme from Riverpod
          // If you have defined darkTheme separately in AppThemes and want to use MaterialApp's darkTheme property:
          // darkTheme: darkTheme, // Assuming darkTheme is accessible from app_themes.dart
          // themeMode: loadedThemeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AuthPage(),
        );
      },
      loading: () {
        // Show a loading indicator or a basic MaterialApp while theme is loading
        // This is important because SharedPreferences is async
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
      error: (error, stackTrace) {
        // Show an error message or a basic MaterialApp with a default theme
        print("Error loading theme in MyApp: $error");
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: lightTheme, // Fallback to lightTheme from app_themes.dart
          home: Scaffold(body: Center(child: Text("Error loading application theme."))),
        );
      },
    );
  }
}
