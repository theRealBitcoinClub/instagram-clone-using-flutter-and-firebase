// media_selection_state.dart
import '../widgets/media_type_selector.dart';

class MediaSelectionState {
  final MediaType? lastSelectedMediaType;

  const MediaSelectionState({this.lastSelectedMediaType});

  MediaSelectionState copyWith({MediaType? lastSelectedMediaType}) {
    return MediaSelectionState(lastSelectedMediaType: lastSelectedMediaType ?? this.lastSelectedMediaType);
  }
}
