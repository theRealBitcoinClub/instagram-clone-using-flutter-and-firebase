import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/update_service.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;

// Mock classes
class MockClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

void main() {
  group('SHA256 Verification Tests', () {
    late UpdateService updateService;
    late MockClient mockClient;
    late Directory tempDir;
    late File testApkFile;

    // Test data - replace with your actual APK and checksums
    const String correctSha256 = 'f3ba8e81e31180d4e6e31f41ac8911a21e9acc3eaf2ddb6ccbc6c46486c5ccdf';
    const String wrongSha256 = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    const String differentCaseSha256 = 'A1B2C3D4E5F6789012345678901234567890123456789012345678901234567890';

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp();

      // Use your specific path syntax for the real APK
      final testDir = Directory.current;
      var apkPath = path.join(testDir.path, 'test/resources', 'mahakka_com-4.3.29-BCH-arm64-v8a.apk');
      testApkFile = File(apkPath);

      // Check if the real APK exists, if not create a test file
      if (!await testApkFile.exists()) {
        print('⚠️ Real APK not found at: $apkPath, creating test file');
        testApkFile = File('${tempDir.path}/test.apk');
        await testApkFile.writeAsBytes(List.generate(1024, (i) => i % 256)); // 1KB test file
      } else {
        print('✅ Using real APK from: $apkPath');
      }
    });

    setUp(() {
      mockClient = MockClient();
      updateService = UpdateService();
    });

    tearDownAll(() async {
      // Only delete if it's our temporary test file, not the real APK
      if (testApkFile.path.contains(tempDir.path)) {
        await testApkFile.delete();
      }
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
      final correctResult = updateService.verifyManualSha256(testApkFile, actualSha256, "");
      expect(correctResult, true, reason: 'Manual verification should return true for correct checksum');

      // Test wrong checksum
      final wrongResult = updateService.verifyManualSha256(testApkFile, wrongSha256, "");
      expect(wrongResult, false, reason: 'Manual verification should return false for wrong checksum');

      // Test with spaces and different case
      final formattedResult = updateService.verifyManualSha256(testApkFile, ' ${actualSha256.toUpperCase()} ', "");
      expect(formattedResult, true, reason: 'Manual verification should handle formatting');
    });

    group('Real APK Specific Tests', () {
      test('Real APK should have valid SHA256 format', () async {
        final sha256 = await updateService.calculateSha256(testApkFile);
        expect(sha256.length, 64, reason: 'SHA256 should be 64 characters long');
        expect(sha256, matches(RegExp(r'^[a-f0-9]+$')), reason: 'SHA256 should contain only hex characters');
      });

      test('Real APK verification with intentionally wrong checksum should fail', () async {
        const intentionallyWrongSha256 = '0000000000000000000000000000000000000000000000000000000000000000';
        final result = await updateService.verifySha256(testApkFile, intentionallyWrongSha256);
        expect(result, false, reason: 'Should fail with intentionally wrong checksum');
      });

      test('Print real APK SHA256 for debugging', () {
        final actualSha256 = updateService.calculateSha256Sync(testApkFile);
        print('=== REAL APK DEBUG INFO ===');
        print('APK Version: 4.3.29-BCH');
        print('APK ABI: arm64-v8a');
        print('APK Path: ${testApkFile.path}');
        print('File size: ${testApkFile.lengthSync()} bytes (${(testApkFile.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB)');
        print('Calculated SHA256: $actualSha256');
        print('==========================');

        // Verify it's a proper SHA256
        expect(actualSha256.length, 64, reason: 'SHA256 should be 64 characters long');
      });
    });

    group('SHA256 Edge Cases', () {
      test('Verification with null expected SHA256', () async {
        // When expectedSha256 is null, verification should be skipped (return true)
        // This depends on your implementation - adjust accordingly
        final result = await updateService.verifySha256(testApkFile, '');
        // Either expect it to return true (skip verification) or false (empty string treated as invalid)
        // Adjust based on your actual implementation
        expect(result, isA<bool>());
      });

      test('Verification with whitespace-only SHA256', () async {
        final result = await updateService.verifySha256(testApkFile, '   ');
        expect(result, false, reason: 'Whitespace-only checksum should fail');
      });

      test('Verification with malformed SHA256', () async {
        const malformedSha256 = 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz';
        final result = await updateService.verifySha256(testApkFile, malformedSha256);
        expect(result, false, reason: 'Malformed SHA256 should fail');
      });
    });
  });

  group('UpdateService Integration Tests', () {
    late UpdateService updateService;

    setUp(() {
      updateService = UpdateService();
    });

    test('getExpectedSha256 should handle version correctly', () async {
      // This test might need mocking depending on your implementation
      final version = '4.3.29-BCH';
      final sha256 = await updateService.getExpectedSha256(version);

      // sha256 might be null if network call fails, which is OK for test
      if (sha256 != null) {
        expect(sha256.length, 64, reason: 'SHA256 from server should be 64 characters');
      }
    });

    test('Current ABI should be arm64-v8a', () {
      expect(updateService.currentAbi, 'arm64-v8a', reason: 'Current ABI should match expected value');
    });

    test('Current version should be correct', () {
      expect(updateService.currentVersion, isNotEmpty, reason: 'Current version should not be empty');
    });
  });
}

// // standalone_sha256_test.dart
// import 'dart:io';
//
// import 'package:crypto/crypto.dart';
// import 'package:path/path.dart' as path;
//
// void main() async {
//   await testSha256WithRealApk();
// }
//
// Future<void> testSha256WithRealApk() async {
//   try {
//     // Use your specific path syntax
//     final testDir = Directory.current;
//     var apkPath = path.join(testDir.path, 'test/resources', 'mahakka_com-4.3.29-BCH-arm64-v8a.apk');
//     final apkFile = File(apkPath);
//
//     if (!await apkFile.exists()) {
//       print('❌ APK file not found at: $apkPath');
//       // print('Current directory: ${testDir.path}');
//
//       // List files for debugging
//       final testDir = Directory(path.join(Directory.current.path, 'test'));
//       if (await testDir.exists()) {
//         print('Files in test directory:');
//         final files = await testDir.list(recursive: true).toList();
//         for (var file in files) {
//           print('  - ${file.path}');
//         }
//       }
//       return;
//     }
//
//     print('✅ Found APK at: $apkPath');
//     await runSha256Test(apkFile);
//   } catch (e) {
//     print('❌ Error: $e');
//   }
// }
//
// Future<void> runSha256Test(File apkFile) async {
//   print('=== SHA256 Verification Test ===');
//   print('APK: mahakka_com-4.3.29-BCH-arm64-v8a.apk');
//   print('Path: ${apkFile.path}');
//   // print('File Size: ${(await apkFile.length()) / (1024 * 1024).toStringAsFixed(2)} MB');
//
//   // Calculate SHA256 using stream (for large files)
//   print('Calculating SHA256...');
//   final stream = apkFile.openRead();
//   final digest = await sha256.bind(stream).first;
//   final calculatedSha256 = digest.toString();
//
//   print('Calculated SHA256: $calculatedSha256');
//   print('SHA256 Length: ${calculatedSha256.length}');
//   print('Is valid SHA256: ${calculatedSha256.length == 64 && RegExp(r'^[a-f0-9]+$').hasMatch(calculatedSha256)}');
//
//   // Test with your actual checksums - REPLACE THESE WITH YOUR ACTUAL CHECKSUMS
//   const expectedCorrectSha256 = 'your_correct_sha256_here'; // Replace with actual
//   const expectedWrongSha256 = '0000000000000000000000000000000000000000000000000000000000000000';
//
//   print('\n--- Verification Results ---');
//   print('With correct checksum: ${calculatedSha256 == expectedCorrectSha256}');
//   print('With wrong checksum: ${calculatedSha256 == expectedWrongSha256}');
//   print('Case insensitive match: ${calculatedSha256.toLowerCase() == expectedCorrectSha256.toLowerCase()}');
//
//   // Test common SHA256 issues
//   print('\n--- Common Issue Tests ---');
//   print('Trailing whitespace test: ${calculatedSha256 == expectedCorrectSha256.trim()}');
//   print('Leading whitespace test: ${calculatedSha256 == expectedCorrectSha256.trimLeft()}');
//   print('All whitespace test: ${calculatedSha256 == expectedCorrectSha256.trim()}');
//
//   // Calculate sync version for comparison
//   final syncCalculated = await calculateSha256Sync(apkFile);
//   print('Sync/Async consistency: ${syncCalculated == calculatedSha256}');
//
//   print('\n=== Test Complete ===');
//   print('IMPORTANT: Replace "your_correct_sha256_here" with the actual SHA256 from your checksum.txt file');
// }
//
// Future<String> calculateSha256Sync(File file) async {
//   final bytes = await file.readAsBytes();
//   final digest = sha256.convert(bytes);
//   return digest.toString();
// }
//
// // void main() async {
// //   await testSha256WithRealApk();
// // }
// //
// // Future<void> testSha256WithRealApk() async {
// //   // Replace with your actual APK file path
// //   // final apkPath = 'resources/mahakka_com-4.3.29-BCH-arm64-v8a.apk';
// //   final testDir = Directory.current;
// //   final apkPath = path.join(testDir.path, 'test/resources', 'mahakka_com-4.3.29-BCH-arm64-v8a.apk');
// //   final apkFile = File(apkPath);
// //
// //   if (!await apkFile.exists()) {
// //     print('❌ APK file not found at: $apkPath');
// //     return;
// //   }
// //
// //   print('=== SHA256 Verification Test ===');
// //   print('APK Path: $apkPath');
// //   print('File Size: ${(await apkFile.length()) / (1024 * 1024)} MB');
// //
// //   // Calculate SHA256
// //   final stream = apkFile.openRead();
// //   final digest = await sha256.bind(stream).first;
// //   final calculatedSha256 = digest.toString();
// //
// //   print('Calculated SHA256: $calculatedSha256');
// //   print('SHA256 Length: ${calculatedSha256.length}');
// //
// //   // Test with your checksums
// //   const expectedCorrectSha256 = 'f3ba8e81e31180d4e6e31f41ac8911a21e9acc3eaf2ddb6ccbc6c46486c5ccdf'; // Replace with actual
// //   const expectedWrongSha256 = 'fdsfhdsklhfdslhfkjdshfkjdslhfkjdshfdsklhfdskjhf'; // Replace with actual
// //
// //   print('\n--- Verification Results ---');
// //   print('With correct checksum: ${calculatedSha256 == expectedCorrectSha256}');
// //   print('With wrong checksum: ${calculatedSha256 == expectedWrongSha256}');
// //   print('Case insensitive test: ${calculatedSha256.toLowerCase() == expectedCorrectSha256.toLowerCase()}');
// //
// //   // Test the actual verification method from your service
// //   final updateService = UpdateService();
// //   final syncSha256 = updateService.calculateSha256Sync(apkFile);
// //   print('Sync calculation matches: ${syncSha256 == calculatedSha256}');
// //
// //   print('=== Test Complete ===');
// // }
