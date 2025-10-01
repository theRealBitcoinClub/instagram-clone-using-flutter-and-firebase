import 'dart:ui' as ui;

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
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesProvider was not initialized');
});

final sharedPreferencesInitializerProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// final languageCodeProvider = StateProvider<String?>((ref) {
//   final prefs = ref.read(sharedPreferencesProvider);
//   return prefs.getString('user_language') ?? SystemLanguage.getLanguageCode();
// });

final languageCodeProvider = StateProvider<String>((ref) {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString('user_language') ?? SystemLanguage.getLanguageCode();
  } catch (e) {
    // Fallback to system language if SharedPreferences fails
    return SystemLanguage.getLanguageCode();
  }
});

Future<bool> setUserLanguage(WidgetRef ref, String languageCode) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final success = await prefs.setString('user_language', languageCode);
    if (success) {
      ref.read(languageCodeProvider.notifier).state = languageCode;
    }
    return success;
  } catch (e) {
    return false;
  }
}

class SystemLanguage {
  /// Get system language with multiple fallback methods
  static String getLanguageCode([BuildContext? context]) {
    // Try Flutter context first (most reliable in widget tree)
    if (context != null) {
      try {
        final Locale locale = Localizations.localeOf(context);
        return locale.languageCode;
      } catch (e) {
        // Fall through to other methods
      }
    }

    // Try dart:ui window locale
    try {
      return ui.window.locale.languageCode;
    } catch (e) {
      // Fall through to platform
    }

    return '';
  }

  /// Get all supported locales from the system
  static List<Locale> getSystemLocales() {
    return ui.window.locales;
  }

  /// Get the primary system locale
  static Locale getSystemLocale() {
    return ui.window.locale;
  }
}

void main() async {
  // Handle Flutter errors silently
  // FlutterError.onError = (details) {
  //   print('Flutter error silenced: ${details.exception}');
  // };
  //
  // // Handle Dart errors
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   print('Dart error silenced: $error');
  //   return true; // Prevents default error handling
  // };
  // Load .env file
  await dotenv.load(fileName: "telegram.env");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // runApp(const ProviderScope(child: MyApp()));
  // Initialize SharedPreferences before running the app
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)], child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Helper getter for easy access to the current state
  static ScaffoldMessengerState? get scaffoldMessengerState => scaffoldMessengerKey.currentState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ThemeState> themeState = ref.watch(themeNotifierProvider);
    final AsyncValue<Isar> isar = ref.watch(isarProvider);

    return isar.when(
      data: (isar) => themeState.when(
        data: (loadedThemeState) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
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
