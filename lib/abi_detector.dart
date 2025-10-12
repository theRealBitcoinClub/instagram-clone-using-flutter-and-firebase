// lib/services/abi_detector.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_info/phone_info.dart';

class AbiDetector {
  static const List<String> supportedAbis = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];

  static Future<String> detectAbi() async {
    try {
      // Try phone_info package first (most reliable)
      final String? phoneInfoAbi = await _detectViaPhoneInfo();
      if (phoneInfoAbi != null && supportedAbis.contains(phoneInfoAbi)) {
        print('✅ Phone Info ABI detected: $phoneInfoAbi');
        return phoneInfoAbi;
      }

      // Fallback to platform channels if available
      final String? platformAbi = await _detectViaPlatform();
      if (platformAbi != null && supportedAbis.contains(platformAbi)) {
        print('⚠️ Platform ABI detected: $platformAbi');
        return platformAbi;
      }

      // Statistical fallback
      print('🔶 Using statistical fallback: arm64-v8a');
      return 'arm64-v8a';
    } catch (e) {
      print('❌ ABI detection error: $e');
      return 'arm64-v8a';
    }
  }

  static Future<String?> _detectViaPhoneInfo() async {
    try {
      // Request necessary permissions
      await _requestPermissions();

      // Get architecture directly from phone_info
      final String? architecture = await PhoneInfoPlugin.getArchitecture();
      return _normalizeArchitecture(architecture);
    } catch (e) {
      print('Phone info detection failed: $e');
      return null;
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      // Request phone permission if needed
      final status = await Permission.phone.status;
      if (!status.isGranted) {
        await Permission.phone.request();
      }
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  static String? _normalizeArchitecture(String? architecture) {
    if (architecture == null) return null;

    const architectureMap = {
      'aarch64': 'arm64-v8a',
      'arm64': 'arm64-v8a',
      'armv7': 'armeabi-v7a',
      'armeabi-v7a': 'armeabi-v7a',
      'x86_64': 'x86_64',
      'x86': 'x86_64',
    };

    final normalized = architectureMap[architecture.toLowerCase()];
    print('Architecture: $architecture → Normalized: $normalized');
    return normalized;
  }

  // Keep your existing platform channel method as fallback
  static Future<String?> _detectViaPlatform() async {
    // Your existing platform channel implementation
    return null;
  }
}
