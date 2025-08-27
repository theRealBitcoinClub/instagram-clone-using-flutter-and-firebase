import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/screens/home.dart';
import 'package:provider/provider.dart';

import 'login_or_registed.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    ProviderUser provider = Provider.of<ProviderUser>(context);
    provider.refreshUser();
    MemoModelUser? user = provider.memoUser;
    FlutterNativeSplash.remove();
    return Scaffold(body: user != null && user.mnemonic.isNotEmpty ? HomeSceen() : LoginOrRegister());
  }
}
