import 'package:flutter/material.dart';
import 'package:mahakka/memomodel/memo_model_user.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/screens/home_screen.dart';
import 'package:provider/provider.dart';

import 'login_or_registed.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    ProviderUser provider = Provider.of<ProviderUser>(context);
    provider.refreshUser();
    MemoModelUser? user = provider.memoUser;
    return Scaffold(body: user != null && user.mnemonic.isNotEmpty ? HomeSceen() : LoginOrRegister());
  }
}
