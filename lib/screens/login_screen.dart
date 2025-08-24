import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/resources/auth_method.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:instagram_clone1/widgets/textfield_input.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onToggle;

  const LoginScreen({super.key, required this.onToggle});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _mnemonicController.dispose();
  }

  //login user

  void loginUser() async {
    setState(() {
      isLoading = true;
    });
    String res = await AuthChecker().loginInWithMnemonic(_mnemonicController.text, context);
    //TODO VERIFY MNEMONIC IS VALID
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: Container(), flex: 2),

              //app logo
              Image.asset('assets/images/cashtoken.png', height: 80),

              const SizedBox(height: 64),

              //TODO ADD GENERATE MNEMONIC BUTTON
              TextInputField(
                textEditingController: _mnemonicController,
                hintText: 'mnemonic',
                textInputType: TextInputType.text,
              ),

              const SizedBox(height: 25),

              //login button
              InkWell(
                onTap: loginUser,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                          color: blueColor,
                        ),
                        child: const Text("Login"),
                      ),
              ),

              Flexible(flex: 2, child: Container()),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: const Text("Are you a new user? "),
                  ),
                  GestureDetector(
                    // onTap: widget.onToggle,
                    onTap: generateMnemonic,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        "GENERATE MNEMONIC",
                        style: TextStyle(fontWeight: FontWeight.bold, color: blueColor),
                      ),
                    ),
                  ),
                ],
              ),

              Flexible(flex: 1, child: Container()),
            ],
          ),
        ),
      ),
    );
  }

  generateMnemonic() {
    _mnemonicController.text = Mnemonic.generate(Language.english, length: MnemonicLength.words12).sentence;
  }
}
