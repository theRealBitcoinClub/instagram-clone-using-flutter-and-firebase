import 'package:clipboard/clipboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/navigation_providers.dart';
import '../../provider/url_input_verification_notifier.dart';
import '../../tab_item_data.dart';

// State to track clipboard status
class ClipboardState {
  final bool isChecking;
  final String? lastClipboardContent;
  final bool hasValidClipboardData;

  ClipboardState({this.isChecking = false, this.lastClipboardContent, this.hasValidClipboardData = false});

  ClipboardState copyWith({bool? isChecking, String? lastClipboardContent, bool? hasValidClipboardData}) {
    return ClipboardState(
      isChecking: isChecking ?? this.isChecking,
      lastClipboardContent: lastClipboardContent ?? this.lastClipboardContent,
      hasValidClipboardData: hasValidClipboardData ?? this.hasValidClipboardData,
    );
  }
}

// Clipboard Notifier (simplified)
class ClipboardNotifier extends StateNotifier<ClipboardState> {
  ClipboardNotifier() : super(ClipboardState());

  Future<void> checkClipboard(WidgetRef ref) async {
    if (state.isChecking) return;

    final currentTab = ref.read(tabIndexProvider);
    if (currentTab != AppTab.add.tabIndex) return;

    try {
      state = state.copyWith(isChecking: true);

      if (await FlutterClipboard.hasData()) {
        final urlFromClipboard = await FlutterClipboard.paste();

        if (urlFromClipboard == state.lastClipboardContent) {
          state = state.copyWith(isChecking: false);
          return;
        }

        // Use the new verification notifier
        await ref.read(urlInputVerificationProvider.notifier).verifyAndProcessInput(ref, urlFromClipboard);

        final hasValidData = ref.read(urlInputVerificationProvider).hasValidInput;

        state = state.copyWith(lastClipboardContent: urlFromClipboard, hasValidClipboardData: hasValidData);
      }
    } catch (e) {
      print('Error checking clipboard: $e');
      state = state.copyWith(hasValidClipboardData: false);
    } finally {
      state = state.copyWith(isChecking: false);
    }
  }
}

// Provider
final clipboardNotifierProvider = StateNotifierProvider<ClipboardNotifier, ClipboardState>((ref) => ClipboardNotifier());
