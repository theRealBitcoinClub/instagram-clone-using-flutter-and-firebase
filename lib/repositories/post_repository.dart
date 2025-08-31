// repositories/post_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../memo/base/memo_accountant.dart';
import '../memo/base/memo_verifier.dart';
import '../memo/firebase/topic_service.dart';

// Assuming you have a postServiceProvider
final postServiceProvider = Provider((ref) => PostService());

final postRepositoryProvider = Provider((ref) => PostRepository(ref));

class PostRepository {
  final Ref ref;

  PostRepository(this.ref);

  Stream<List<MemoModelPost>> getPostsByCreatorId(String creatorId) {
    return ref.read(postServiceProvider).getPostsByCreatorIdStream(creatorId);
  }

  Future<dynamic> publishReplyTopic(MemoModelPost post, String replyText) async {
    MemoVerificationResponse verifier = MemoVerifier(replyText).checkAllPostValidations();
    if (verifier == MemoVerificationResponse.valid) {
      return ref.read(memoAccountantProvider).publishReplyTopic(post, replyText);
    } else {
      return verifier;
    }
  }

  Future<dynamic> publishReplyHashtags(MemoModelPost post, String text) async {
    MemoVerificationResponse verifier = MemoVerifier(text).checkAllPostValidations();
    if (verifier != MemoVerificationResponse.valid) return verifier;
    return ref.read(memoAccountantProvider).publishReplyHashtags(post, text);
  }

  Future<dynamic> publishImageOrVideo(String text, String? topic, {bool validate = false}) async {
    if (validate) {
      MemoVerificationResponse res = MemoVerifier(text).checkAllPostValidations();
      if (res != MemoVerificationResponse.valid) return res;
    }
    return ref.read(memoAccountantProvider).publishImgurOrYoutube(topic, text);
  }

  Future<void> loadTopic(MemoModelPost post) async {
    if (post.topicId.isNotEmpty) {
      post.topic = await TopicService().getTopicOnce(post.topicId);
    }
  }
}
