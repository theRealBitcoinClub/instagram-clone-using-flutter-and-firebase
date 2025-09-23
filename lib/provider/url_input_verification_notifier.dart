// url_input_verification_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../memo/base/memo_verifier.dart';
import '../../memo/memo_reg_exp.dart';
import '../screens/add/add_post_providers.dart';

class UrlInputVerificationState {
  final bool hasValidInput;
  final String? lastProcessedContent;

  UrlInputVerificationState({this.hasValidInput = false, this.lastProcessedContent});

  UrlInputVerificationState copyWith({bool? hasValidInput, String? lastProcessedContent}) {
    return UrlInputVerificationState(
      hasValidInput: hasValidInput ?? this.hasValidInput,
      lastProcessedContent: lastProcessedContent ?? this.lastProcessedContent,
    );
  }
}

class UrlInputVerificationNotifier extends StateNotifier<UrlInputVerificationState> {
  final Ref ref;

  UrlInputVerificationNotifier(this.ref) : super(UrlInputVerificationState());

  Future<void> verifyAndProcessInput(WidgetRef ref, String input) async {
    // if (input.trim().isEmpty || input == state.lastProcessedContent) {
    //   state = state.copyWith(hasValidInput: false);
    //   return;
    // }

    state = state.copyWith(lastProcessedContent: input);

    // Check IPFS
    final ipfsCid = MemoRegExp(input).extractIpfsCid();
    if (ipfsCid.isNotEmpty) {
      _handleMedia(ref, 2, ipfsCid);
      return;
    }

    // Check YouTube first
    if (MemoRegExp.extractUrls(input).isNotEmpty) {
      final ytId = YoutubePlayer.convertUrlToId(input);
      if (ytId != null && ytId.isNotEmpty) {
        _handleMedia(ref, 1, ytId);
        return;
      }
    }

    // Check Imgur/Giphy
    final imgurUrl = MemoRegExp(input).extractValidImgurOrGiphyUrl();
    if (imgurUrl.isNotEmpty) {
      _handleMedia(ref, 0, imgurUrl);
      return;
    }

    // Check Odysee
    final odyseeUrl = MemoRegExp(input).extractOdyseeUrl();
    if (odyseeUrl.isNotEmpty) {
      _handleMedia(ref, 3, odyseeUrl);
      return;
    }

    // Advanced Imgur check
    final advancedImgurUrl = await MemoVerifier(input).verifyAndBuildImgurUrl();
    if (advancedImgurUrl != MemoVerificationResponse.noImageNorVideo.toString()) {
      _handleMedia(ref, 0, advancedImgurUrl);
      return;
    }

    // No valid media found
    state = state.copyWith(hasValidInput: false);
  }

  void _handleMedia(WidgetRef ref, int type, String content) {
    switch (type) {
      case 0:
        ref.read(imgurUrlProvider.notifier).state = content;
        break;
      case 1:
        ref.read(youtubeVideoIdProvider.notifier).state = content;
        break;
      case 2:
        ref.read(ipfsCidProvider.notifier).state = content;
        break;
      case 3:
        ref.read(odyseeUrlProvider.notifier).state = content;
        break;
    }
    _clearOtherMediaProviders(ref, type);
    state = state.copyWith(hasValidInput: true);
  }

  void _clearOtherMediaProviders(ref, int index) {
    if (index != 0) ref.read(imgurUrlProvider.notifier).state = '';
    if (index != 1) ref.read(youtubeVideoIdProvider.notifier).state = '';
    if (index != 2) ref.read(ipfsCidProvider.notifier).state = '';
    if (index != 3) ref.read(odyseeUrlProvider.notifier).state = '';
  }

  void reset() {
    state = UrlInputVerificationState();
    _clearOtherMediaProviders(ref, -1);
  }
}

final urlInputVerificationProvider = StateNotifierProvider<UrlInputVerificationNotifier, UrlInputVerificationState>(
  (ref) => UrlInputVerificationNotifier(ref),
);
