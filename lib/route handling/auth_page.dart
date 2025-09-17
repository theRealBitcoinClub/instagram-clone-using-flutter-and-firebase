import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
// Import your Riverpod user providers
import 'package:mahakka/provider/user_provider.dart'; // Ensure userProvider and userIsLoadingProvider are defined here
import 'package:mahakka/screens/home.dart';
import 'package:mahakka/screens/login_screen.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the derived provider for the user object
    final MemoModelUser? user = ref.watch(userProvider);
    // 2. Watch the derived provider specifically for the loading state
    final bool isLoading = ref.watch(userIsLoadingProvider);
    // 3. (Optional) Watch for errors if you have a derived error provider
    // final String? error = ref.watch(userErrorProvider);

    if (isLoading) {
      // While user state is loading, show a loading screen.
      // Splash screen is ideally removed after this initial loading state is resolved.
      return Scaffold(body: Center(child: Image.asset('assets/icon_round_200.png', height: 120)));
    } else
      FlutterNativeSplash.remove();

    // (Optional) Check for and handle errors if you have an error provider
    // and the error should block navigation or show a specific error UI here.
    // if (error != null && user == null) { // Condition might vary based on your error handling logic
    //   print("AuthPage: User fetch error - $error");
    //   // return Scaffold(body: Center(child: Text("Error: $error. Please try again.")));
    //   // Or proceed to login/register, logging the error
    // }

    if (user != null && user.mnemonic.isNotEmpty) {
      // return
      return const HomeSceen();
    } else {
      return const LoginScreen();
    }
    // }
  }
}
