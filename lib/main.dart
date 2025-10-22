import 'dart:io';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:mahakka/app_themes.dart';
import 'package:mahakka/firebase_options.dart';
import 'package:mahakka/memo/isar/memo_model_creator_db.dart';
import 'package:mahakka/permission_helper.dart';
import 'package:mahakka/route%20handling/auth_page.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/update_monitor.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../memo/isar/cached_translation_db.dart';
import '../memo/isar/isar_shared_preferences_model.dart';
import '../memo/isar/memo_model_post_db.dart';
import 'memo/isar/isar_shared_preferences.dart';

// Sentry configuration provider
final sentryConfigProvider = Provider<SentryConfig>((ref) {
  return SentryConfig(
    dsn: dotenv.env['SENTRY_DSN'] ?? '',
    environment: dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development',
    release: dotenv.env['SENTRY_RELEASE'] ?? '1.0.0',
  );
});

class SentryConfig {
  final String dsn;
  final String environment;
  final String release;

  SentryConfig({required this.dsn, required this.environment, required this.release});
}

final sharedPreferencesProvider = Provider<IsarSharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferencesProvider was not initialized');
});

final languageCodeProvider = StateProvider<String>((ref) {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString('user_language22') ?? SystemLanguage.getLanguageCode();
  } catch (e) {
    Sentry.captureException(e);
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

void _enhanceSentryContext() async {
  try {
    // Get app version info
    final packageInfo = await PackageInfo.fromPlatform();

    // FIXED: Use proper Contexts structure
    Sentry.configureScope((scope) {
      // Create proper Contexts object
      // final contexts = Contexts(
      //   // App context with proper structure
      //   app: SentryApp(
      //     identifier: packageInfo.packageName,
      //     name: packageInfo.appName,
      //     version: packageInfo.version,
      //     buildType: packageInfo.buildNumber,
      //   ),
      //   // Device context with proper structure
      //   device: SentryDevice(
      //     name: Platform.localHostname,
      //     family: Platform.operatingSystem,
      //     model: Platform.operatingSystem,
      //     simulator: !Platform.isAndroid && !Platform.isIOS, // True for emulators
      //   ),
      //   // Operating system context
      //   operatingSystem: SentryOperatingSystem(
      //     name: Platform.operatingSystem,
      //     version: Platform.operatingSystemVersion,
      //   ),
      // );

      // Set the complete contexts object
      // scope.setUser(SentryUser());
      // scope.setContexts(key, value)

      // Also set as tags for easy filtering
      scope.setTag('app.version', packageInfo.version);
      scope.setTag('app.build', packageInfo.buildNumber);
      scope.setTag('app.name', packageInfo.appName);
      scope.setTag('device.platform', Platform.operatingSystem);

      Sentry.logger.debug('Sentry context enhanced successfully');
    });
  } catch (e, stackTrace) {
    // Report the context enhancement error to Sentry
    Sentry.captureException(e, stackTrace: stackTrace, hint: Hint.withMap({'context': 'sentry_context_enhancement'}));
    Sentry.logger.error('Sentry context enhancement failed: $e');
  }
}

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar was not initialized');
});

void main() async {
  await dotenv.load(fileName: "telegram.env");

  // FIXED: Use SentryWidgetsFlutterBinding instead of WidgetsFlutterBinding
  final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  PermissionHelper.initializeOneSignal();

  // Open Isar directly
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [MemoModelCreatorDbSchema, MemoModelPostDbSchema, CachedTranslationDbSchema, IsarPreferenceSchema],
    directory: dir.path,
    name: 'mahakka_mka',
    maxSizeMiB: 144,
  );

  await IsarSharedPreferences.initialize(isar: isar);
  final isarPrefs = await IsarSharedPreferences.getInstance();

  final finalContainer = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(isarPrefs),
      isarProvider.overrideWithValue(isar), // Provide the ready Isar instance
    ],
  );
  // Get Isar instance first
  // final isar = await containerInit.read(unifiedIsarProvider.future);
  // // Initialize IsarSharedPreferences
  // await IsarSharedPreferences.initialize(isar: isar);
  // final isarPrefs = await IsarSharedPreferences.getInstance();
  //
  // // Override the provider with IsarSharedPreferences instance
  // final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(isarPrefs)]);

  // Get Sentry config
  final sentryConfig = SentryConfig(
    dsn: dotenv.env['SENTRY_DSN'] ?? '',
    environment: dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development',
    release: dotenv.env['SENTRY_RELEASE'] ?? '1.0.0',
  );

  // Initialize Sentry
  if (sentryConfig.dsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        // === SIMPLIFIED CORE CONFIGURATION ===
        createSentryConfig(options, sentryConfig);
      },
      appRunner: () {
        _enhanceSentryContext();
        runApp(UncontrolledProviderScope(container: finalContainer, child: const MyApp()));
      },
    );
  } else {
    // Run without Sentry if DSN is not configured
    runApp(UncontrolledProviderScope(container: finalContainer, child: const MyApp()));
  }
}

void createSentryConfig(SentryFlutterOptions options, SentryConfig sentryConfig) {
  // === SIMPLIFIED CORE CONFIGURATION ===
  options.dsn = sentryConfig.dsn;
  options.environment = sentryConfig.environment;
  options.release = sentryConfig.release;

  // === BASIC PERFORMANCE MONITORING ===
  options.tracesSampleRate = 1.0;
  options.enableAutoPerformanceTracing = true;

  // === BASIC ERROR CONTEXT ===
  options.sendDefaultPii = true;
  options.attachStacktrace = true;
  options.diagnosticLevel = SentryLevel.debug;

  // === NATIVE CRASH HANDLING ===
  options.enableNativeCrashHandling = true;
  // options.enableOutOfMemoryTracking = true;
  options.anrEnabled = true;
  options.anrTimeoutInterval = Duration(milliseconds: 5000);

  // === SESSION TRACKING ===
  options.enableAutoSessionTracking = true;

  // === BREADCRUMBS (ESSENTIAL ONLY) ===
  options.enableAppLifecycleBreadcrumbs = true;
  options.enableUserInteractionBreadcrumbs = true;

  options.enableLogs = true;

  // === REMOVED COMPLEX FEATURES CAUSING ERRORS ===
  // options.attachScreenshot = false; // Remove for now
  // options.attachViewHierarchy = false; // Remove for now
  // options.enableTimeToFullDisplayTracing = false; // Remove for now
  // options.replay.sessionSampleRate = 0.0; // Disable session replay
  // options.profilesSampleRate = 0.0; // Disable profiling for now
  // options.enableFramesTracking = true; // This should work now with SentryWidgetsFlutterBinding

  // === SIMPLIFIED NETWORK SETTINGS ===
  options.connectionTimeout = Duration(seconds: 10);
  options.readTimeout = Duration(seconds: 10);

  // === BASIC REPORTING ===
  options.reportSilentFlutterErrors = true;
  options.reportPackages = true;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Helper getter for easy access to the current state
  static ScaffoldMessengerState? get scaffoldMessengerState => scaffoldMessengerKey.currentState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ThemeState> themeState = ref.watch(themeNotifierProvider);

    return themeState.when(
      data: (loadedThemeState) {
        return MaterialApp(
          navigatorObservers: [SentryNavigatorObserver()],
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          title: 'mahakka.com',
          theme: loadedThemeState.currentTheme,
          home: Stack(children: [const AuthPage(), const UpdateMonitor()]),
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
    );
  }
}
