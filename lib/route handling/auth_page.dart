import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/provider/user_provider.dart';
import 'package:instagram_clone1/screens/home_screen.dart';
import 'package:provider/provider.dart';

import '../memomodel/memo_auth.dart';
import 'login_or_registed.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<ProviderUser>(context).memoUser;
    return Scaffold(
        // body: StreamBuilder<User?>(
      body:
      // StreamBuilder<MemoModelUser?>(
      //   stream: MemoAuth().authStateChanges(),
        // stream: FirebaseAuth.instance.authStateChanges(),
        // builder: (context, snap) {
          //is user logged in
          // if (snapshot.hasData) {
          // if(snap.hasData && MemoAuth().user.wif != null) {
                user != null && user.mnemonic.isNotEmpty
               ? HomeSceen()
               : LoginOrRegister()
          // }
          //is user not logged in
          // else {
          //   return const LoginOrRegister();
          // }
        // },
      // ),
    );
  }
}
