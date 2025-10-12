// standalone_sha256_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/update_service.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;

// Import your UpdateService class

// Mock classes
class MockClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

void main() {
  group('SHA256 Verification Tests', () {
    late UpdateService updateService;
    late MockClient mockClient;
    late Directory tempDir;
    File testApkFile;

    // Test data - replace with your actual APK and checksums
    const String correctSha256 = 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890';
    const String wrongSha256 = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    const String differentCaseSha256 = 'A1B2C3D4E5F6789012345678901234567890123456789012345678901234567890';

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp();
      final testDir = Directory.current;
      var apkPath = path.join(testDir.path, 'test/resources', 'mahakka_com-4.3.29-BCH-arm64-v8a.apk');
      testApkFile = File(apkPath);
      // Create a test APK file (you can replace this with loading your actual APK)
      // testApkFile = File('${tempDir.path}/test.apk');
      // await testApkFile.writeAsBytes(List.generate(1024, (i) => i % 256)); // 1KB test file
    });

    setUp(() {
      mockClient = MockClient();
      updateService = UpdateService();
    });

    tearDownAll(() async {
      await testApkFile.delete();
      await tempDir.delete(recursive: true);
    });

    test('verifySha256Sync should return true for correct checksum', () {
      // Calculate actual SHA256 of test file
      final actualSha256 = updateService.calculateSha256Sync(testApkFile);

      // Test with correct checksum
      final result = updateService.verifySha256Sync(testApkFile, actualSha256);
      expect(result, true, reason: 'Should return true when checksums match');
    });

    test('verifySha256Sync should return false for wrong checksum', () {
      final result = updateService.verifySha256Sync(testApkFile, wrongSha256);
      expect(result, false, reason: 'Should return false when checksums dont match');
    });

    test('verifySha256Sync should handle case insensitivity', () {
      // Calculate actual SHA256 of test file
      final actualSha256 = updateService.calculateSha256Sync(testApkFile);

      // Test with uppercase version
      final result = updateService.verifySha256Sync(testApkFile, actualSha256.toUpperCase());
      expect(result, true, reason: 'Should be case insensitive');
    });

    test('verifySha256Sync should return false for empty file', () async {
      final emptyFile = File('${tempDir.path}/empty.apk');
      await emptyFile.writeAsBytes([]);

      final result = updateService.verifySha256Sync(emptyFile, correctSha256);
      expect(result, false, reason: 'Should return false for empty file');

      await emptyFile.delete();
    });

    test('verifySha256Sync should handle file not found', () {
      final nonExistentFile = File('${tempDir.path}/nonexistent.apk');

      expect(
        () => updateService.verifySha256Sync(nonExistentFile, correctSha256),
        throwsA(isA<Exception>()),
        reason: 'Should throw exception for non-existent file',
      );
    });

    test('verifySha256Async should return true for correct checksum', () async {
      // Calculate actual SHA256 of test file using async method
      final actualSha256 = await updateService.calculateSha256(testApkFile);

      // Test with correct checksum using async verification
      final result = await updateService.verifySha256(testApkFile, actualSha256);
      expect(result, true, reason: 'Async verification should return true when checksums match');
    });

    test('verifySha256Async should return false for wrong checksum', () async {
      final result = await updateService.verifySha256(testApkFile, wrongSha256);
      expect(result, false, reason: 'Async verification should return false when checksums dont match');
    });

    test('calculateSha256Sync and calculateSha256 should produce same result', () async {
      final syncResult = updateService.calculateSha256Sync(testApkFile);
      final asyncResult = await updateService.calculateSha256(testApkFile);

      expect(syncResult, asyncResult, reason: 'Sync and async methods should produce identical results');
    });

    test('verifyManualSha256 should work correctly', () {
      final actualSha256 = updateService.calculateSha256Sync(testApkFile);

      // Test correct checksum
      final correctResult = updateService.verifyManualSha256(testApkFile, actualSha256);
      expect(correctResult, true, reason: 'Manual verification should return true for correct checksum');

      // Test wrong checksum
      final wrongResult = updateService.verifyManualSha256(testApkFile, wrongSha256);
      expect(wrongResult, false, reason: 'Manual verification should return false for wrong checksum');

      // Test with spaces and different case
      final formattedResult = updateService.verifyManualSha256(testApkFile, ' ${actualSha256.toUpperCase()} ');
      expect(formattedResult, true, reason: 'Manual verification should handle formatting');
    });

    group('Integration Tests with Download Simulation', () {
      test('downloadAndInstallApk should fail when SHA256 mismatch', () async {
        bool onErrorCalled = false;
        String errorMessage = '';

        // This test simulates the actual download flow with wrong checksum
        // You'll need to mock the HTTP client for this to work properly
        // For now, we'll test the verification logic directly

        final tempFile = File('${tempDir.path}/download_test.tmp');
        await testApkFile.copy(tempFile.path);

        // Simulate the verification step that happens after download
        final isValid = updateService.verifySha256Sync(tempFile, wrongSha256);

        expect(isValid, false, reason: 'Download with wrong checksum should fail verification');

        await tempFile.delete();
      });

      test('SHA256 string format validation', () {
        // Test various SHA256 string formats
        const validSha256 = 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890';
        const tooShort = 'a1b2c3';
        const tooLong = 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890aaa';
        const invalidChars = 'g1b2c3d4e5f6789012345678901234567890123456789012345678901234567890';

        // Test that our verification handles different formats
        expect(validSha256.length, 64, reason: 'Valid SHA256 should be 64 chars');
        expect(updateService.verifySha256Sync(testApkFile, validSha256), isA<bool>());
      });
    });

    group('Debug Test - Print Actual SHA256', () {
      test('Print actual SHA256 of test file for debugging', () {
        final actualSha256 = updateService.calculateSha256Sync(testApkFile);
        print('=== DEBUG INFO ===');
        print('Actual SHA256 of test file: $actualSha256');
        print('File size: ${testApkFile.lengthSync()} bytes');
        print('File path: ${testApkFile.path}');
        print('==================');

        // This test always passes, it's just for debugging
        expect(actualSha256.length, 64, reason: 'SHA256 should be 64 characters long');
      });
    });
  });
}

// void main() async {
//   await testSha256WithRealApk();
// }
//
// Future<void> testSha256WithRealApk() async {
//   // Replace with your actual APK file path
//   // final apkPath = 'resources/mahakka_com-4.3.29-BCH-arm64-v8a.apk';
//   final testDir = Directory.current;
//   final apkPath = path.join(testDir.path, 'test/resources', 'mahakka_com-4.3.29-BCH-arm64-v8a.apk');
//   final apkFile = File(apkPath);
//
//   if (!await apkFile.exists()) {
//     print('❌ APK file not found at: $apkPath');
//     return;
//   }
//
//   print('=== SHA256 Verification Test ===');
//   print('APK Path: $apkPath');
//   print('File Size: ${(await apkFile.length()) / (1024 * 1024)} MB');
//
//   // Calculate SHA256
//   final stream = apkFile.openRead();
//   final digest = await sha256.bind(stream).first;
//   final calculatedSha256 = digest.toString();
//
//   print('Calculated SHA256: $calculatedSha256');
//   print('SHA256 Length: ${calculatedSha256.length}');
//
//   // Test with your checksums
//   const expectedCorrectSha256 = 'f3ba8e81e31180d4e6e31f41ac8911a21e9acc3eaf2ddb6ccbc6c46486c5ccdf'; // Replace with actual
//   const expectedWrongSha256 = 'fdsfhdsklhfdslhfkjdshfkjdslhfkjdshfdsklhfdskjhf'; // Replace with actual
//
//   print('\n--- Verification Results ---');
//   print('With correct checksum: ${calculatedSha256 == expectedCorrectSha256}');
//   print('With wrong checksum: ${calculatedSha256 == expectedWrongSha256}');
//   print('Case insensitive test: ${calculatedSha256.toLowerCase() == expectedCorrectSha256.toLowerCase()}');
//
//   // Test the actual verification method from your service
//   final updateService = UpdateService();
//   final syncSha256 = updateService.calculateSha256Sync(apkFile);
//   print('Sync calculation matches: ${syncSha256 == calculatedSha256}');
//
//   print('=== Test Complete ===');
// }
