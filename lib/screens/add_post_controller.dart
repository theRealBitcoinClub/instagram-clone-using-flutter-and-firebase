import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/provider/publish_options_provider.dart';
import 'package:mahakka/provider/url_input_verification_notifier.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/taggable_providers.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/memo_confetti.dart';

import '../config_ipfs.dart';
import '../memo/base/memo_verifier.dart';
import '../memo/base/text_input_verifier.dart';
import '../memo/model/memo_model_post.dart';
import '../provider/telegram_bot_publisher.dart';
import '../provider/translation_service.dart';
import '../repositories/post_repository.dart';
import '../widgets/add/publish_confirmation_activity.dart';
import 'add/add_post_providers.dart';
import 'ipfs_gallery_screen.dart';
import 'ipfs_pin_claim_screen.dart';

// Provider for AddPostController
final addPostControllerProvider = StateNotifierProvider<AddPostController, void>((ref) {
  return AddPostController(ref: ref);
});

// // Provider for the onPublish callback
// final onPublishProvider = Provider.autoDispose<VoidCallback>((ref) {
//   final controller = ref.watch(addPostControllerProvider.notifier);
//   return () => controller.publishPost();
// });
//
// // Provider for text controller access
// final publishTextProvider = StateProvider.autoDispose<String>((ref) => '');
//
// // Provider to check if media is added
// final hasMediaToPublishProvider = Provider.autoDispose<bool>((ref) {
//   final controller = ref.watch(addPostControllerProvider.notifier);
//   return controller.hasAddedMediaToPublish();
// });

class AddPostController extends StateNotifier<void> {
  final Ref ref;
  late BuildContext _context;

  AddPostController({required this.ref}) : super(null);

  void setContext(BuildContext context) {
    _context = context;
  }

  // Helper method to show snackbars
  void _showSnackBar(String message, {bool isError = false}) {
    if (_context.mounted) {
      showSnackBar(message, _context, type: isError ? SnackbarType.error : SnackbarType.success);
    }
  }

  // Publish functionality
  Future<void> publishPost() async {
    String textContent = ref.read(taggableControllerProvider).text;
    if (ref.read(isPublishingProvider)) return;
    ref.read(isPublishingProvider.notifier).state = true;

    try {
      var verification = _handleVerification(textContent);

      if (verification != MemoVerificationResponse.valid) {
        _showSnackBar(verification.message, isError: true);
        return;
      }

      final topics = MemoRegExp.extractTopics(textContent);
      final topic = topics.isNotEmpty ? topics.first : "";
      final post = _createPostFromCurrentState(textContent, topic);
      post.parseUrlsTagsTopicClearText();
      //save ipfs cid whatever happens
      ref.read(userNotifierProvider.notifier).addIpfsUrlAndUpdate(ref.read(ipfsCidProvider));

      final shouldPublish = await PublishConfirmationActivity.show(_context, post: post);
      if (shouldPublish != true) {
        if (shouldPublish == false) {
          _context.showSnackBar(type: SnackbarType.info, 'Publication canceled');
        }
        return;
      }

      final user = ref.read(userProvider)!;
      MemoModelPost copyPost = ref.read(postTranslationProvider).applyTranslationAndAppendMediaUrl(post: post, ref: ref);

      copyPost.appendTagsTopicToText();

      //VERIFY AGAIN THAT TEXT FITS AFTER TRANSLATION
      verification = _handleVerification(copyPost.text!);
      if (verification != MemoVerificationResponse.valid) {
        _showSnackBar(verification.message, isError: true);
        return;
      }

      copyPost.appendUrlsToText();

      final response = await ref.read(postRepositoryProvider).publishImageOrVideo(copyPost.text!, topic, validate: false);

      if (response == MemoAccountantResponse.yes) {
        MemoConfetti().launch(_context);
        ref.read(urlInputVerificationProvider.notifier).reset();
        _showSnackBar('Successfully published!');
        ref.read(taggableControllerProvider).text = '';
        ref.read(telegramBotPublisherProvider).publishPost(postText: copyPost.text!, mediaUrl: null);
      } else {
        showQrCodeDialog(context: _context, user: user, memoOnly: true);
        _showSnackBar('Publish failed: ${response.message}', isError: true);
      }
    } catch (e, s) {
      print("Error during publish: $e\n$s");
      _showSnackBar('Error during publish: $e', isError: true);
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
      // creator: ref.read(userProvider)!.creator,
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
        // .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyOffensiveWords);

    return verifier.getResult();
  }

  String getMediaUrl() {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    if (youtubeId.isNotEmpty) {
      return " https://youtu.be/$youtubeId";
    } else if (imgurUrl.isNotEmpty) {
      return " $imgurUrl";
    } else if (ipfsCid.isNotEmpty) {
      return " ${IpfsConfig.preferredNode}$ipfsCid";
    } else if (odyseeUrl.isNotEmpty) {
      return " $odyseeUrl";
    }
    return "";
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
    IpfsPinClaimScreen.show(_context);
  }

  void showIpfsGallery() {
    final user = ref.read(userProvider);
    if (user == null || user.ipfsCids.isEmpty) {
      _showSnackBar('No IPFS images found in your gallery', isError: true);
      return;
    }

    Navigator.push(_context, MaterialPageRoute(builder: (context) => IPFSGalleryScreen(ipfsCids: user.ipfsCids)));
  }
}
