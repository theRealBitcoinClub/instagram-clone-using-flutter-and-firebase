import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone1/memomodel/memo_auth.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/resources/auth_method.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:instagram_clone1/widgets/textfield_input.dart';
import 'package:provider/provider.dart';

import '../provider/user_provider.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onToggle;
  const LoginScreen({super.key , required this.onToggle});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _memoProfileIdController = TextEditingController();
  final TextEditingController _mnemonicController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _memoProfileIdController.dispose();
    _mnemonicController.dispose();
  }

  //login user

  void loginUser() async {
    setState(() {
      isLoading = true;
    });
    // String res = await AuthMedthod().signinUser(
    //     email: _emailController.text, password: _passwordController.text);
    String res = await AuthChecker().signInWithMnemonic(MemoModelUser.createDummy().mnemonic, context);
    // setState(() {
    //   MemoAuth().user.wif = "sdfdsfds";
    //   MemoAuth().authStateChanges();
    // });
    // String res = "success"; //TODO CHECKS USER LOGIN WITH WIF AND TEST LIKE OR ANYTHING THAT DOESNT LEAVE TRACE BUT FAILS ON WRONG WIF
    if (res != 'success') {
      showSnackBar(res, context);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      width: double.infinity,
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Flexible(
          child: Container(),
          flex: 2,
        ),

        //app logo
        SvgPicture.asset(
          'assets/images/instagram.svg',
          color: primaryColor,
          height: 80,
        ),

        const SizedBox(
          height: 64,
        ),


        //TODO CHECK IF I CAN DERIVE THE PROFILE ID FROM THE SEED USING m44/0/0 legacy format
        //TODO ANYWAY THIS ID MUST BE OPTIONAL
        //username text input
        TextInputField(
            textEditingController: _memoProfileIdController,
            hintText: 'profile id',
            textInputType: TextInputType.text),

        const SizedBox(
          height: 25,
        ),
        //password text input

        //TODO ADD GENERATE MNEMONIC BUTTON
        TextInputField(

            textEditingController: _mnemonicController,
            hintText: 'mnemonic',
            isPass: true,
            textInputType: TextInputType.text),

        const SizedBox(
          height: 25,
        ),

        //login button

        InkWell(
          onTap: loginUser,
          child: isLoading?const Center(child: CircularProgressIndicator(),) 
          :Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const ShapeDecoration(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              color: blueColor,
            ),
            child: const Text("Login"),
          ),
        ),

        Flexible(
          flex: 2,
          child: Container(),
        ),

        //dont have and account ? signup
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Text("don't have an account? "),
            ),
            GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Text(
                  "Sign Up",
                  style:
                      TextStyle(fontWeight: FontWeight.bold, color: blueColor),
                ),
              ),
            )
          ],
        ),

        Flexible(
          flex: 1,
          child: Container(),
        ),
      ]),
    )));
  }
}
