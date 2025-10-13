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
import 'package:mahakka/update_monitor.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesProvider was not initialized');
});

final sharedPreferencesInitializerProvider = FutureProvider<SharedPreferences>((ref) async {
  return ref.read(sharedPreferencesProvider);
});

final languageCodeProvider = StateProvider<String>((ref) {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString('user_language22') ?? SystemLanguage.getLanguageCode();
  } catch (e) {
    // Fallback to system language if SharedPreferences fails
    return SystemLanguage.getLanguageCode();
  }
});

Future<bool> setUserLanguage(WidgetRef ref, String languageCode) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final success = await prefs.setString('user_language22', languageCode);
    if (success) {
      ref.read(languageCodeProvider.notifier).state = languageCode;
    }
    return success;
  } catch (e) {
    return false;
  }
}

class SystemLanguage {
  static String getLanguageCode([BuildContext? context]) {
    if (context != null) {
      try {
        final Locale locale = Localizations.localeOf(context);
        return locale.languageCode;
      } catch (e) {}
    }

    try {
      return ui.window.locale.languageCode;
    } catch (e) {}

    return '';
  }

  static List<Locale> getSystemLocales() {
    return ui.window.locales;
  }

  static Locale getSystemLocale() {
    return ui.window.locale;
  }
}

void main() async {
  await dotenv.load(fileName: "telegram.env");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)]);

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Helper getter for easy access to the current state
  static ScaffoldMessengerState? get scaffoldMessengerState => scaffoldMessengerKey.currentState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ThemeState> themeState = ref.watch(themeNotifierProvider);
    final AsyncValue<Isar> isar = ref.watch(unifiedIsarProvider);

    return isar.when(
      data: (isar) => themeState.when(
        data: (loadedThemeState) {
          return MaterialApp(
            scaffoldMessengerKey: scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            title: 'mahakka.com',
            theme: loadedThemeState.currentTheme,
            home: Stack(
              children: [
                const AuthPage(), // Your main content
                const UpdateMonitor(), // Update monitoring overlay
              ],
            ),
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
