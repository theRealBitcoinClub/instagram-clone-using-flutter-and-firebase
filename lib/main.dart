import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/route%20handling/auth_page.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:provider/provider.dart' as legacy;

import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return legacy.MultiProvider(
      providers: [
        legacy.ChangeNotifierProvider(create: (_) => ProviderUser()),
        legacy.ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: legacy.Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ProviderScope(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'mahakka.com',
              theme: themeProvider.currentTheme,
              home: const AuthPage(),
            ),
          );
        },
      ),
    );
    // );
  }
}
