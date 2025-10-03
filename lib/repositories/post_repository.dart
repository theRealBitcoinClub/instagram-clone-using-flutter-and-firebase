import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/post_service_feed.dart';
import 'package:mahakka/memo/firebase/post_service_profile.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

import '../memo/base/memo_accountant.dart';
import '../memo/base/memo_verifier.dart';

final postServiceProfileProvider = Provider((ref) => PostServiceProfile());
final postServiceFeedProvider = Provider((ref) => PostServiceFeed());
final postRepositoryProvider = Provider((ref) => PostRepository(ref));

class PostRepository {
  final Ref ref;

  PostRepository(this.ref);

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
}
