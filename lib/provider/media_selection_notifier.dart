// media_selection_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/media_type_selector.dart';
import 'media_selection_state.dart';

class MediaSelectionNotifier extends StateNotifier<MediaSelectionState> {
  MediaSelectionNotifier() : super(const MediaSelectionState());

  void selectMediaType(MediaType mediaType) {
    state = state.copyWith(lastSelectedMediaType: mediaType);
  }

  void clearSelection() {
    state = state.copyWith(lastSelectedMediaType: null);
  }
}

final mediaSelectionProvider = StateNotifierProvider<MediaSelectionNotifier, MediaSelectionState>((ref) => MediaSelectionNotifier());
