// draft_post_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

final draftPostProvider = StateProvider<MemoModelPost?>((ref) => null);
