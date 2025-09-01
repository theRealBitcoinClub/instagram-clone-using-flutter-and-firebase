// providers/creator_service_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';

// Provides a singleton instance of CreatorService.
final creatorServiceProvider = Provider<CreatorService>((ref) {
  return CreatorService();
});
