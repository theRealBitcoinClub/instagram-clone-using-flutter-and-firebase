import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/provider/publish_options_provider.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../config_ipfs.dart';
import '../memo/base/memo_verifier.dart';
import '../memo/base/text_input_verifier.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/telegram_bot_publisher.dart';
import '../provider/translation_service.dart';
import '../repositories/post_repository.dart';
import '../widgets/add/publish_confirmation_activity.dart';
import 'add/add_post_providers.dart';
import 'ipfs_gallery_screen.dart' hide IpfsConfig;
import 'ipfs_pin_claim_screen.dart';

class AddPostController {
  final WidgetRef ref;
  final BuildContext context;
  final VoidCallback onPublish;
  final VoidCallback clearInputs;
  final Function(String) showErrorSnackBar;
  final Function(String) showSuccessSnackBar;
  final Function(String) log;

  AddPostController({
    required this.ref,
    required this.context,
    required this.onPublish,
    required this.clearInputs,
    required this.showErrorSnackBar,
    required this.showSuccessSnackBar,
    required this.log,
  });

  // Media URL handlers
  void handleImgurInput(String text) {
    if (text.trim().isEmpty) return;

    final newImgurUrl = MemoRegExp(text).extractValidImgurOrGiphyUrl();

    if (newImgurUrl.isNotEmpty) {
      ref.read(imgurUrlProvider.notifier).state = newImgurUrl;
      _clearOtherMediaProviders(0);
    } else {
      _tryAdvancedImgurCheck(text);
    }
  }

  Future<void> _tryAdvancedImgurCheck(String text) async {
    final newImgurUrl = await MemoVerifier(text).verifyAndBuildImgurUrl();

    if (newImgurUrl != MemoVerificationResponse.noImageNorVideo.toString()) {
      ref.read(imgurUrlProvider.notifier).state = newImgurUrl;
      _clearOtherMediaProviders(0);
    }
  }

  void handleYouTubeInput(String text) {
    if (text.trim().isEmpty) return;

    final newVideoId = YoutubePlayer.convertUrlToId(text);

    if (newVideoId != null && newVideoId.isNotEmpty) {
      ref.read(youtubeVideoIdProvider.notifier).state = newVideoId;
      _clearOtherMediaProviders(1);
    }
  }

  void handleOdyseeInput(String text) {
    if (text.trim().isEmpty) return;

    final newOdyseeUrl = MemoRegExp(text).extractOdyseeUrl();

    if (newOdyseeUrl.isNotEmpty) {
      ref.read(odyseeUrlProvider.notifier).state = newOdyseeUrl;
      _clearOtherMediaProviders(3);
    }
  }

  void handleIpfsInput(String text) {
    if (text.trim().isEmpty) return;

    final ipfsCid = MemoRegExp(text).extractIpfsCid();

    if (ipfsCid.isNotEmpty) {
      ref.read(ipfsCidProvider.notifier).state = ipfsCid;
      _clearOtherMediaProviders(2);
    }
  }

  void _clearOtherMediaProviders(int index) {
    if (index != 0) ref.read(imgurUrlProvider.notifier).state = "";
    if (index != 1) ref.read(youtubeVideoIdProvider.notifier).state = "";
    if (index != 2) ref.read(ipfsCidProvider.notifier).state = "";
    if (index != 3) ref.read(odyseeUrlProvider.notifier).state = "";
  }

  // Publish functionality
  Future<void> publishPost(String textContent) async {
    if (ref.read(isPublishingProvider)) return;
    ref.read(isPublishingProvider.notifier).state = true;

    try {
      final verification = _handleVerification(textContent);

      if (verification != MemoVerificationResponse.valid) {
        showErrorSnackBar(verification.message);
        return;
      }

      final finalTextContent = _appendMediaUrlToText(textContent);
      final topics = MemoRegExp.extractTopics(finalTextContent);
      final topic = topics.isNotEmpty ? topics.first : "";
      final post = _createPostFromCurrentState(finalTextContent, topic);

      final shouldPublish = await PublishConfirmationActivity.show(context, post: post);
      if (shouldPublish != true) {
        if (shouldPublish == false) {
          showSnackBar(type: SnackbarType.info, 'Publication canceled', context);
        }
        return;
      }

      final user = ref.read(userProvider)!;
      final translation = ref.read(postTranslationProvider);
      final useTranslation = translation.targetLanguage != translation.originalLanguage;

      final lang = useTranslation ? translation.targetLanguage! : translation.originalLanguage!;
      final content = useTranslation ? translation.translatedText : finalTextContent;
      final formattedContent = "${lang.flag} $content";

      final response = await ref.read(postRepositoryProvider).publishImageOrVideo(formattedContent, topic, validate: false);

      if (response == MemoAccountantResponse.yes) {
        MemoConfetti().launch(context);
        clearInputs();
        showSuccessSnackBar('Successfully published!');
        ref.read(telegramBotPublisherProvider).publishPost(postText: formattedContent, mediaUrl: null);
      } else {
        showQrCodeDialog(context: context, user: user, memoOnly: true);
        showErrorSnackBar('Publish failed: ${response.message}');
      }
    } catch (e, s) {
      log("Error during publish: $e\n$s");
      showErrorSnackBar('Error during publish: $e');
    } finally {
      ref.read(translatedTextProvider.notifier).state = null;
      ref.read(postTranslationProvider.notifier).reset();
      ref.read(isPublishingProvider.notifier).state = false;
    }
  }

  MemoModelPost _createPostFromCurrentState(String textContent, String? topic) {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    return MemoModelPost(
      id: null,
      text: textContent,
      imgurUrl: imgurUrl.isNotEmpty ? imgurUrl : null,
      youtubeId: youtubeId.isNotEmpty ? youtubeId : null,
      imageUrl: null,
      videoUrl: odyseeUrl.isNotEmpty ? odyseeUrl : null,
      ipfsCid: ipfsCid.isNotEmpty ? ipfsCid : null,
      tagIds: MemoRegExp.extractHashtags(textContent),
      topicId: topic ?? "",
      topic: topic != null ? MemoModelTopic(id: topic) : null,
      creator: ref.read(userProvider)!.creator,
      creatorId: ref.read(userProvider)!.id,
    );
  }

  MemoVerificationResponse _handleVerification(String textContent) {
    final verifier = MemoVerifierDecorator(textContent)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyNoTopicNorTag)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyOffensiveWords);

    return verifier.getResult();
  }

  String _appendMediaUrlToText(String text) {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    if (youtubeId.isNotEmpty) {
      return "$text https://youtu.be/$youtubeId";
    } else if (imgurUrl.isNotEmpty) {
      return "$text $imgurUrl";
    } else if (ipfsCid.isNotEmpty) {
      return "$text ${IpfsConfig.preferredNode}$ipfsCid";
    } else if (odyseeUrl.isNotEmpty) {
      return "$text $odyseeUrl";
    }
    return text;
  }

  bool hasAddedMediaToPublish() {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    return imgurUrl.isNotEmpty || youtubeId.isNotEmpty || ipfsCid.isNotEmpty || odyseeUrl.isNotEmpty;
  }

  // In AddPostController class
  void showIpfsUploadScreen() {
    IpfsPinClaimScreen.show(context);
  }

  void showIpfsGallery() {
    final user = ref.read(userProvider);
    if (user == null || user.ipfsCids.isEmpty) {
      showErrorSnackBar('No IPFS images found in your gallery');
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => IPFSGalleryScreen(ipfsCids: user.ipfsCids))).then((selectedCid) {
      if (selectedCid != null && context.mounted) {
        ref.read(ipfsCidProvider.notifier).state = selectedCid;
        _clearOtherMediaProviders(2);
      }
    });
  }
}
