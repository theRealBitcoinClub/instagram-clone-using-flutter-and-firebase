import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/user_provider.dart';

// 1. (Optional but good practice) Define a provider for AuthChecker itself
final authCheckerProvider = Provider<AuthChecker>((ref) {
  return AuthChecker(ref); // Pass ref to AuthChecker
});

class AuthChecker {
  // Add a Ref member to access other providers
  final Ref _ref;
  AuthChecker(this._ref);

  Future<MemoModelUser?> getUserFromDB() async {
    final prefs = await SharedPreferences.getInstance();
    String? mnemonic = prefs.getString("mnemonic");

    if (mnemonic == null || mnemonic.isEmpty) return null;
    var user = MemoModelUser.fromMnemonic(mnemonic: mnemonic);
    if (user.hasInit) {
      user.saveToFirebase();
    } else {
      throw Exception("MNEMONIC WRONG? : $mnemonic");
    }
    return user;
  }

  Future<String> loginInWithMnemonic(String mnemonic) async {
    // Removed 'ctx' parameter, will use _ref to access UserNotifier
    try {
      String verificationMsg = MemoVerifier(mnemonic).verifyMnemonic();
      if (verificationMsg != "success") {
        return verificationMsg;
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("mnemonic", mnemonic);

      // Trigger user refresh using the UserNotifier from Riverpod
      // This will update the UserState and any widgets watching it.
      await _ref.read(userNotifierProvider.notifier).refreshUser();
      return "success";
    } catch (err) {
      print("Error during loginInWithMnemonic: $err");
      return err.toString();
    }
  }

  Future<String> logOut() async {
    // Removed 'ctx' parameter
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("mnemonic");

      // Clear the user state and trigger a refresh/update
      // You might have a specific 'clearUser' method in your UserNotifier
      // or refreshUser will handle the null state from getUserFromDB.
      _ref.read(userNotifierProvider.notifier).clearUser(); // Ideal if you have this
      // OR if clearUser also calls refreshUser or updates state appropriately:
      // await _ref.read(userNotifierProvider.notifier).refreshUser();

      return "success";
    } catch (err) {
      print("Error during logOut: $err");
      return err.toString();
    }
  }
}
