import 'package:mahakka/memo/memomodel/memo_model_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/user_provider.dart';

class AuthChecker {
  Future<MemoModelUser?> getUserFromDB() async {
    String? mnemonic = await SharedPreferencesAsync().getString("mnemonic");

    if (mnemonic == null || mnemonic.isEmpty) return null;
    //TODO load creator with profile Id, get legacy ID
    return MemoModelUser(mnemonic: mnemonic);
  }

  // Future<String> signUpCreateWif(ctx) async {
  //   //TODO create memo.cash account derive legacy m44/0/0 as profile id
  //   String res = await signInWithMnemonic(MemoModelUser.createDummy().mnemonic, ctx);
  //   ProviderUser up = Provider.of(ctx, listen: false);
  //   await up.refreshUser();
  //   return res;
  // }

  Future<String> loginInWithMnemonic(String mnemonic, ctx) async {
    try {
      if (mnemonic.isEmpty) {
        return "enter mnemonic of twelve words that is cashtoken compatible";
      }
      //TODO VALIDATE MNEMONIC
      SharedPreferencesAsync().setString("mnemonic", mnemonic);
      ProviderUser up = Provider.of(ctx, listen: false);
      await up.refreshUser();
    } catch (err) {
      return err.toString();
    }
    return "success";
  }

  Future<String> logOut(ctx) async {
    try {
      SharedPreferencesAsync().remove("mnemonic");
      ProviderUser up = Provider.of(ctx, listen: false);
      await up.refreshUser();
    } catch (err) {
      return err.toString();
    }
    return "success";
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:mahakka/model_original/user.dart' as model_original;
// import 'package:mahakka/resources/storage_methods.dart';
//
// class AuthMedthod {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
// //get snapshot of current user data
//   Future<model_original.User> getUserDetails() async {
//     User currentUser = _auth.currentUser!;
//     DocumentSnapshot snap =
//         await _firestore.collection('users').doc(currentUser.uid).get();
//
//     return model_original.User.fromSnap(snap);
//   }
//
//   Future<String> signUpUser({
//     required String email,
//     required String fullName,
//     required String username,
//     required String password,
//     required Uint8List profilePicture,
//   }) async {
//     String res = 'some error occured';
//     try {
//       if (email.isNotEmpty ||
//           fullName.isNotEmpty ||
//           username.isNotEmpty ||
//           password.isNotEmpty) {
//         //register user
//         UserCredential credential = await FirebaseAuth.instance
//             .createUserWithEmailAndPassword(email: email, password: password);
//
//         String photoURL = await StorageMethod()
//             .uploadImageToStorage('ProfilePics', profilePicture, false);
//
//         //upload userdata to database
//
//         model_original.User user = model_original.User(
//             email: email,
//             uid: credential.user!.uid,
//             fullName: fullName,
//             username: username,
//             password: password,
//             followers: [],
//             followings: [],
//             photoURL: photoURL);
//         await _firestore.collection('users').doc(credential.user!.uid).set(
//               user.toJason(),
//             );
//         res = 'success';
//       }
//     } catch (err) {
//       res = err.toString();
//     }
//     return res;
//   }
//
//   //login user
//
//   Future<String> signinUser(
//       {required String email, required String password}) async {
//     String res = "some error occured";
//
//     try {
//       if (email.isNotEmpty && password.isNotEmpty) {
//         await _auth.signInWithEmailAndPassword(
//             email: email, password: password);
//         res = "success";
//       } else {
//         res = "please enter all the field";
//       }
//     } catch (err) {
//       res = err.toString();
//     }
//
//     return res;
//   }
// }
