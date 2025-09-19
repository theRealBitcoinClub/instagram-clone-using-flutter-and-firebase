// providers/webview_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/navigation_providers.dart';
import '../tab_item_data.dart';

final tagIdProvider = StateProvider<String?>((ref) => null);
final topicIdProvider = StateProvider<String?>((ref) => null);
final targetUrlProvider = StateProvider<String?>((ref) => null);

// webview_target_enum.dart
enum WebViewShow { tag, topic, url }

// Add this to webview_providers.dart
class WebViewNavigationHelper {
  static void navigateToWebView(WidgetRef ref, WebViewShow target, String value) {
    // Reset all providers first
    ref.read(targetUrlProvider.notifier).state = null;
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    // Set the target provider based on the enum
    switch (target) {
      case WebViewShow.tag:
        ref.read(tagIdProvider.notifier).state = value;
        break;
      case WebViewShow.topic:
        ref.read(topicIdProvider.notifier).state = value;

        break;
      case WebViewShow.url:
        ref.read(targetUrlProvider.notifier).state = value;
        break;
    }

    // Navigate to the memo tab
    ref.read(tabIndexProvider.notifier).setTab(AppTab.memo.tabIndex);
  }
}
