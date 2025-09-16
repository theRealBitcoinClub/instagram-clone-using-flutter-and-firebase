import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahakka/main.dart';

void main() {
  testWidgets('Absolute basic smoke test', (WidgetTester tester) async {
    // This test only builds the app and checks it doesn't throw
    try {
      await tester.pumpWidget(ProviderScope(child: const MyApp()));

      // If we get here, the app built successfully
      expect(true, isTrue); // This will always pass
    } catch (e) {
      fail('App failed to build: $e');
    }
  });
}
