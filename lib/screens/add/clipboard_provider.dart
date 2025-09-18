import 'package:clipboard/clipboard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../memo/memo_reg_exp.dart';
import 'add_post_providers.dart';

// State to track clipboard status
class ClipboardState {
  final bool hasBeenChecked;
  final String? lastClipboardContent;
  final bool hasValidClipboardData;

  ClipboardState({this.hasBeenChecked = false, this.lastClipboardContent, this.hasValidClipboardData = false});

  ClipboardState copyWith({bool? hasBeenChecked, String? lastClipboardContent, bool? hasValidClipboardData}) {
    return ClipboardState(
      hasBeenChecked: hasBeenChecked ?? this.hasBeenChecked,
      lastClipboardContent: lastClipboardContent ?? this.lastClipboardContent,
      hasValidClipboardData: hasValidClipboardData ?? this.hasValidClipboardData,
    );
  }
}

// Clipboard Notifier
class ClipboardNotifier extends StateNotifier<ClipboardState> {
  ClipboardNotifier() : super(ClipboardState());

  Future<void> checkClipboard(WidgetRef ref) async {
    final currentTab = ref.read(tabIndexProvider);
    if (currentTab != AppTab.add.tabIndex) return;

    try {
      if (await FlutterClipboard.hasData()) {
        final urlFromClipboard = await FlutterClipboard.paste();

        // Don't process the same content twice
        if (urlFromClipboard == state.lastClipboardContent) {
          return;
        }

        bool isValidData = false;
        final memoRegex = MemoRegExp(urlFromClipboard);
        final ytId = YoutubePlayer.convertUrlToId(urlFromClipboard);

        if (ytId != null && ytId.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(youtubeVideoIdProvider.notifier).state = ytId;
            _clearOtherMediaProviders(ref, 1);
          });
          isValidData = true;
        } else {
          final imgur = memoRegex.extractValidImgurOrGiphyUrl();
          if (imgur.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(imgurUrlProvider.notifier).state = imgur;
              _clearOtherMediaProviders(ref, 0);
            });
            isValidData = true;
          } else {
            final ipfsCid = memoRegex.extractIpfsCid();
            if (ipfsCid.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(ipfsCidProvider.notifier).state = ipfsCid;
                _clearOtherMediaProviders(ref, 2);
              });
              isValidData = true;
            } else {
              final odyseeUrl = memoRegex.extractOdyseeUrl();
              if (odyseeUrl.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(odyseeUrlProvider.notifier).state = odyseeUrl;
                  _clearOtherMediaProviders(ref, 3);
                });
                isValidData = true;
              } else {
                final checkUrlRequests = await MemoVerifier(urlFromClipboard).verifyAndBuildImgurUrl();
                if (checkUrlRequests != MemoVerificationResponse.noImageNorVideo.toString()) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(imgurUrlProvider.notifier).state = checkUrlRequests;
                    _clearOtherMediaProviders(ref, 0);
                  });
                  isValidData = true;
                }
              }
            }
          }
        }

        state = state.copyWith(hasBeenChecked: true, lastClipboardContent: urlFromClipboard, hasValidClipboardData: isValidData);
      }
    } catch (e) {
      print('Error checking clipboard: $e');
      state = state.copyWith(hasValidClipboardData: false);
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
