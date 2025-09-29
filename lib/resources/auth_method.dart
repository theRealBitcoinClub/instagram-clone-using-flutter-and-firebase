import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/navigation_providers.dart';
import '../provider/user_provider.dart';

// 1. (Optional but good practice) Define a provider for AuthChecker itself
final authCheckerProvider = Provider<AuthChecker>((ref) {
  return AuthChecker(ref);
});

// Provider for the mnemonic hash to make it easily accessible
final mnemonicHashProvider = FutureProvider<String?>((ref) async {
  final authChecker = ref.read(authCheckerProvider);
  return await authChecker.getCurrentUserMnemonicHash();
});

class AuthChecker {
  // Add a Ref member to access other providers
  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthChecker(this._ref);

  // Generate or retrieve encryption key from secure storage
  Future<encrypt.Key> _getEncryptionKey() async {
    String? keyString = await _secureStorage.read(key: "encryption_key");

    if (keyString == null) {
      // Generate a new random key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      keyString = base64Url.encode(keyBytes);
      await _secureStorage.write(key: "encryption_key", value: keyString);
    }

    return encrypt.Key.fromBase64(keyString);
  }

  // Encrypt mnemonic before storage
  Future<String> _encryptMnemonic(String mnemonic) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromLength(16); // Initialization vector
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(mnemonic, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  // Decrypt mnemonic after retrieval
  Future<String> _decryptMnemonic(String encryptedData) async {
    final key = await _getEncryptionKey();
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid encrypted data format');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Create a unique hash from mnemonic (cannot be used to decipher it)
  String createMnemonicHash(String mnemonic) {
    // Combine mnemonic with a fixed salt and hash multiple times
    // This makes it computationally infeasible to reverse
    const salt = "mahakka_mnemonic_hash_salt_v1"; // Fixed application salt

    // First hash: mnemonic + salt
    var bytes = utf8.encode(mnemonic + salt);
    var digest = sha256.convert(bytes);

    // Second hash: first hash + reversed salt for additional security
    var secondBytes = utf8.encode(digest.toString() + salt.split('').reversed.join());
    var finalDigest = sha256.convert(secondBytes);

    // Return the hash as a string
    return finalDigest.toString();
  }

  Future<MemoModelUser?> createUserFromMnemonic() async {
    final prefs = await SharedPreferences.getInstance();
    String? encryptedMnemonic = prefs.getString("encrypted_mnemonic");

    if (encryptedMnemonic == null || encryptedMnemonic.isEmpty) return null;

    try {
      String mnemonic = await _decryptMnemonic(encryptedMnemonic);
      var user = MemoModelUser.fromMnemonic(mnemonic: mnemonic);
      return user;
    } catch (e) {
      print("Error decrypting mnemonic: $e");
      return null;
    }
  }

  // Get the mnemonic hash for the current user (if exists)
  Future<String?> getCurrentUserMnemonicHash() async {
    final prefs = await SharedPreferences.getInstance();
    String? encryptedMnemonic = prefs.getString("encrypted_mnemonic");

    if (encryptedMnemonic == null || encryptedMnemonic.isEmpty) return null;

    try {
      String mnemonic = await _decryptMnemonic(encryptedMnemonic);
      return createMnemonicHash(mnemonic);
    } catch (e) {
      print("Error getting mnemonic hash: $e");
      return null;
    }
  }

  // Get cached mnemonic hash from SharedPreferences (faster, for frequent access)
  Future<String?> getCachedMnemonicHash() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("mnemonic_hash");
  }

  Future<String> loginInWithMnemonic(String mnemonic) async {
    try {
      String verificationMsg = MemoVerifier(mnemonic).verifyMnemonic();
      if (verificationMsg != "success") {
        return verificationMsg;
      }

      // Encrypt and save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String encryptedMnemonic = await _encryptMnemonic(mnemonic);
      await prefs.setString("encrypted_mnemonic", encryptedMnemonic);

      // Also store the hash for quick access (cached)
      String mnemonicHash = createMnemonicHash(mnemonic);
      await prefs.setString("mnemonic_hash", mnemonicHash);

      // Trigger user refresh using the UserNotifier from Riverpod
      await _ref.read(userNotifierProvider.notifier).refreshUser(true);

      // Invalidate the hash provider to refresh any listeners
      _ref.invalidate(mnemonicHashProvider);

      return "success";
    } catch (err) {
      print("Error during loginInWithMnemonic: $err");
      return err.toString();
    }
  }

  Future<String> logOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Remove encrypted mnemonic and cached hash
      await prefs.remove("encrypted_mnemonic");
      await prefs.remove("mnemonic_hash");

      // Remove encryption key from secure storage (optional - makes old data unrecoverable)
      await _secureStorage.delete(key: "encryption_key");

      _ref.read(userNotifierProvider.notifier).clearUser();
      _ref.read(profileTargetIdProvider.notifier).state = null;
      _ref.read(tabIndexProvider.notifier).setTab(AppTab.feed.tabIndex);

      // Invalidate the hash provider
      _ref.invalidate(mnemonicHashProvider);

      return "success";
    } catch (err) {
      print("Error during logOut: $err");
      return err.toString();
    }
  }

  // Utility method to verify if a given hash matches the current user's mnemonic
  Future<bool> verifyMnemonicHash(String hashToVerify) async {
    final currentHash = await getCurrentUserMnemonicHash();
    return currentHash == hashToVerify;
  }

  // Check if user is logged in (has a mnemonic)
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("encrypted_mnemonic");
  }

  // Clear all secure data (for debugging or complete reset)
  Future<void> clearAllSecureData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("encrypted_mnemonic");
    await prefs.remove("mnemonic_hash");
    await _secureStorage.delete(key: "encryption_key");
    _ref.invalidate(mnemonicHashProvider);
  }
}
