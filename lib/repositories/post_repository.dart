// repositories/post_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

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

  Future<dynamic> publishReplyTopic(MemoModelPost post) async {
    MemoVerificationResponse verifier = MemoVerifier(post.text!).checkAllPostValidations(ref);
    if (verifier == MemoVerificationResponse.valid) {
      return ref.read(memoAccountantProvider).publishReplyTopic(post);
    } else {
      return verifier;
    }
  }

  Future<dynamic> publishReplyHashtags(MemoModelPost post) async {
    MemoVerificationResponse verifier = MemoVerifier(post.text!).checkAllPostValidations(ref);
    if (verifier != MemoVerificationResponse.valid) return verifier;
    return ref.read(memoAccountantProvider).publishReplyHashtags(post);
  }

  Future<dynamic> publishImageOrVideo(String text, String? topic, {bool validate = false}) async {
    if (validate) {
      MemoVerificationResponse res = MemoVerifier(text).checkAllPostValidations(ref);
      if (res != MemoVerificationResponse.valid) return res;
    }
    return ref.read(memoAccountantProvider).publishImgurOrYoutube(topic, text);
  }

  Future<MemoModelTopic> loadTopic(MemoModelPost post) async {
    var topic;
    if (post.topicId.isNotEmpty) {
      topic = await TopicService().getTopicOnce(post.topicId);
    }
    return topic;
  }
}
