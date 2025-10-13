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
import 'package:mahakka/provider/isar_provider.dart';
import 'package:mahakka/route%20handling/auth_page.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/update_monitor.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add OneSignal provider
final oneSignalProvider = Provider<OneSignalController>((ref) {
  return OneSignalController();
});

class OneSignalController {
  Future<void> initialize() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.error);
      OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      OneSignal.consentRequired(false);
      OneSignal.initialize(dotenv.env['ONE_SIGNAL']!); // Replace with your app ID
      OneSignal.LiveActivities.setupDefault();
      OneSignal.Notifications.clearAll();
      // // Remove this method to stop OneSignal Debugging
      // OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      //
      // // Initialize OneSignal
      // OneSignal.initialize(dotenv.env['ONE_SIGNAL']!); // Replace with your app ID
      //
      // // Request permission for iOS (optional for Android)
      // OneSignal.Notifications.requestPermission(true);

      // Handle notification clicks
      // OneSignal.Notifications.addClickListener((event) {
      //   // Handle notification click
      //   print('Notification clicked: ${event.notification}');
      //   // You can navigate to specific screens based on notification data
      //   final additionalData = event.notification.additionalData;
      //   if (additionalData != null) {
      //     print('Additional data: $additionalData');
      //     // Handle custom data from notification
      //   }
      // });
      //
      // // Handle notification received while app is in foreground
      // OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      //   print('Notification received in foreground: ${event.notification}');
      //   // You can prevent the notification from showing by using:
      //   // event.preventDefault();
      //   // event.notification.display(); to display it later
      // });
    } catch (e) {}
  }
}

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
      scope.setUser(SentryUser());
      // scope.setContexts(key, value)

      // Also set as tags for easy filtering
      scope.setTag('app.version', packageInfo.version);
      scope.setTag('app.build', packageInfo.buildNumber);
      scope.setTag('app.name', packageInfo.appName);
      scope.setTag('device.platform', Platform.operatingSystem);

      print('Sentry context enhanced successfully');
    });
  } catch (e, stackTrace) {
    // Report the context enhancement error to Sentry
    Sentry.captureException(e, stackTrace: stackTrace, hint: Hint.withMap({'context': 'sentry_context_enhancement'}));
    print('Sentry context enhancement failed: $e');
  }
}

void main() async {
  await dotenv.load(fileName: "telegram.env");

  // FIXED: Use SentryWidgetsFlutterBinding instead of WidgetsFlutterBinding
  final widgetsBinding = SentryWidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)]);

  // Initialize OneSignal
  final oneSignalController = OneSignalController();
  await oneSignalController.initialize();

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
      },
      appRunner: () {
        _enhanceSentryContext();
        runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
      },
    );
  } else {
    // Run without Sentry if DSN is not configured
    runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
  }
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
