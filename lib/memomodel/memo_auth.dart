import 'package:instagram_clone1/memomodel/memo_model_user.dart';

class MemoAuth {
  static final MemoAuth _singleton = MemoAuth._internal();
  MemoModelUser? user;
  
  factory MemoAuth() {
    return _singleton;
  }
  
  MemoAuth._internal();

  authStateChanges() {}
}