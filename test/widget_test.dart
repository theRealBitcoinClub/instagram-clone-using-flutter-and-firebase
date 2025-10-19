import 'package:flutter_test/flutter_test.dart';
import 'package:mahakka/main.dart';

void main() {
  test('Basic smoke test - just verify MyApp can be instantiated', () {
    // Just test that we can create the app widget without building the full tree
    expect(() => const MyApp(), returnsNormally);
  });
}
