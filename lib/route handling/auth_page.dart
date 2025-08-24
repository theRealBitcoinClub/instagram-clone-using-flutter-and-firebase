import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/provider/user_provider.dart';
import 'package:instagram_clone1/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'login_or_registed.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    ProviderUser provider = Provider.of<ProviderUser>(context);
    provider.refreshUser();
    MemoModelUser? user = provider.memoUser;
    return Scaffold(
      body: user != null && user.mnemonic.isNotEmpty
          ? HomeSceen()
          : LoginOrRegister(),
    );
  }
}
