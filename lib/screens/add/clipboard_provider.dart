import 'package:clipboard/clipboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../memo/memo_reg_exp.dart';
import 'add_post_providers.dart';

// State to track clipboard status
class ClipboardState {
  final bool hasBeenChecked;
  final String? lastClipboardContent;

  ClipboardState({this.hasBeenChecked = false, this.lastClipboardContent});

  ClipboardState copyWith({bool? hasBeenChecked, String? lastClipboardContent}) {
    return ClipboardState(
      hasBeenChecked: hasBeenChecked ?? this.hasBeenChecked,
      lastClipboardContent: lastClipboardContent ?? this.lastClipboardContent,
    );
  }
}

// Clipboard Notifier
class ClipboardNotifier extends StateNotifier<ClipboardState> {
  ClipboardNotifier() : super(ClipboardState());

  Future<void> checkClipboard(WidgetRef ref) async {
    try {
      if (await FlutterClipboard.hasData()) {
        final urlFromClipboard = await FlutterClipboard.paste();

        // Don't process the same content twice
        if (urlFromClipboard == state.lastClipboardContent) {
          return;
        }

        final memoRegex = MemoRegExp(urlFromClipboard);
        final ytId = YoutubePlayer.convertUrlToId(urlFromClipboard);

        if (ytId != null && ytId.isNotEmpty) {
          ref.read(youtubeVideoIdProvider.notifier).state = ytId;
          _clearOtherMediaProviders(ref, 1);
        } else {
          final imgur = memoRegex.extractValidImgurOrGiphyUrl();
          if (imgur.isNotEmpty) {
            ref.read(imgurUrlProvider.notifier).state = imgur;
            _clearOtherMediaProviders(ref, 0);
          } else {
            final ipfsCid = memoRegex.extractIpfsCid();
            if (ipfsCid.isNotEmpty) {
              ref.read(ipfsCidProvider.notifier).state = ipfsCid;
              _clearOtherMediaProviders(ref, 2);
            } else {
              final odyseeUrl = memoRegex.extractOdyseeUrl();
              if (odyseeUrl.isNotEmpty) {
                ref.read(odyseeUrlProvider.notifier).state = odyseeUrl;
                _clearOtherMediaProviders(ref, 3);
              }
            }
          }
        }

        state = state.copyWith(hasBeenChecked: true, lastClipboardContent: urlFromClipboard);
      }
    } catch (e) {
      print('Error checking clipboard: $e');
    }
  }

  void _clearOtherMediaProviders(WidgetRef ref, int index) {
    if (index != 0) ref.read(imgurUrlProvider.notifier).state = '';
    if (index != 1) ref.read(youtubeVideoIdProvider.notifier).state = '';
    if (index != 2) ref.read(ipfsCidProvider.notifier).state = '';
    if (index != 3) ref.read(odyseeUrlProvider.notifier).state = '';
  }
}

// Provider
final clipboardNotifierProvider = StateNotifierProvider<ClipboardNotifier, ClipboardState>((ref) => ClipboardNotifier());
