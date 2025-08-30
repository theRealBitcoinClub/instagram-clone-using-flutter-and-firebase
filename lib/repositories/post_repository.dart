// repositories/post_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

// Assuming you have a postServiceProvider
final postServiceProvider = Provider((ref) => PostService());

final postRepositoryProvider = Provider((ref) => PostRepository(ref));

class PostRepository {
  final Ref ref;

  PostRepository(this.ref);

  Stream<List<MemoModelPost>> getPostsByCreatorId(String creatorId) {
    return ref.read(postServiceProvider).getPostsByCreatorIdStream(creatorId);
  }
}
