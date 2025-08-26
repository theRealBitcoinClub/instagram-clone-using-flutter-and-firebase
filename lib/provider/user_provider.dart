// import 'package:flutter/material.dart';
// import 'package:mahakka/model_original/user.dart';
// import 'package:mahakka/resources/auth_method.dart';
//
// class UserProvider with ChangeNotifier {
//    late User _user;
//   final AuthMedthod _authMedthod = AuthMedthod();
//
//   User get getUser => _user;
//
//   Future<void> refereshUser() async {
//     User user = await _authMedthod.getUserDetails();
//     _user = user;
//     notifyListeners();
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:mahakka/memo/memomodel/memo_model_user.dart';
import 'package:mahakka/resources/auth_method.dart';

class ProviderUser with ChangeNotifier {
  MemoModelUser? memoUser;

  AuthChecker _authChecker = AuthChecker();

  Future<void> refreshUser() async {
    memoUser = await loadUserFromDb();
    notifyListeners();
  }

  Future<MemoModelUser?> loadUserFromDb() async {
    return _authChecker.getUserFromDB();
  }
}
