import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/screens/home_screen.dart';

import '../memomodel/memo_auth.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MemoModelUser?>(
        stream: MemoAuth().authStateChanges(),
        builder: (context, snapshot) {
          //is user logged in
          // if (snapshot.hasData) {
          // if(MemoAuth().user?.WIF != null && MemoAuth().user?.creator?.id != null) {
           return HomeSceen();
          // }
          //is user not logged in
          // else {
          //   return const LoginOrRegister();
          // }
        },
      ),
    );
  }
}
