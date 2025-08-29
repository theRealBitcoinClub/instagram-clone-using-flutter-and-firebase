import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/resources/auth_method.dart';
// import 'package:mahakka/utils/colors.dart'; // REMOVE THIS
import 'package:mahakka/utils/snackbar.dart'; // Ensure this is themed
import 'package:mahakka/widgets/textfield_input.dart'; // Ensure this is themed

class LoginScreen extends ConsumerStatefulWidget {
  final Function()? onToggle; // Assuming this is for toggling between Login/Signup

  const LoginScreen({Key? key, this.onToggle}) : super(key: key); // Use Key? and make onToggle optional

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _mnemonicController = TextEditingController();
  bool _isLoading = false; // Renamed for convention

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    // Renamed for convention & made Future<void>
    if (_mnemonicController.text.trim().isEmpty) {
      if (mounted) showSnackBar("Please enter your mnemonic phrase.", context);
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final authChecker = ref.read(authCheckerProvider);
    String res = await authChecker.loginInWithMnemonic(_mnemonicController.text.trim());

    if (mounted) {
      if (res != 'success') {
        showSnackBar(res, context); // Ensure showSnackBar is themed
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateMnemonic() {
    // This is good, directly updates the controller
    _mnemonicController.text = Mnemonic.generate(Language.english, length: MnemonicLength.words12).sentence;
    // Optionally move cursor to end if needed, though for a full phrase it might not matter
    // _mnemonicController.selection = TextSelection.fromPosition(TextPosition(offset: _mnemonicController.text.length));
    // if (mounted) {
    //   showSnackBar("New mnemonic generated in the field.", context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          // Ensures the Column takes full width for centering
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Use Spacer for flexible spacing

              // App Logo
              Image.asset(
                'assets/images/cashtoken.png', // Ensure this asset exists
                height: 80,
                // Consider adding semantic label for accessibility
                // semanticLabel: 'Cashtoken App Logo',
              ),

              const SizedBox(height: 56),

              // Adjusted spacing

              // Mnemonic Input Field
              // Assuming TextInputField is already themed. If not, replace with a standard TextField.
              TextInputField(
                textEditingController: _mnemonicController,
                hintText: 'Enter your 12-word mnemonic phrase',
                textInputType: TextInputType.text,
                // Ensure TextInputField uses theme.inputDecorationTheme and theme.textTheme
                // maxLines: 3, // Allow more lines for mnemonic
              ),

              const SizedBox(height: 16),

              TextButton.icon(
                icon: Icon(Icons.refresh_rounded, color: colorScheme.secondary),
                label: Text(
                  "GENERATE MNEMONIC",
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.secondary, // Use a secondary theme color
                  ),
                ),
                onPressed: _generateMnemonic,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
              ),

              const SizedBox(height: 24),

              // Login Button
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        // valueColor will be from theme.progressIndicatorTheme.color
                      ),
                    )
                  : SizedBox(
                      // Use SizedBox to constrain ElevatedButton width
                      width: double.infinity,
                      height: 50, // Standard button height
                      child: ElevatedButton(
                        onPressed: _loginUser,
                        // Style will be inherited from theme.elevatedButtonTheme
                        // You can override specific parts if needed:
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white70,
                          textStyle: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        child: Text(
                          "LOGIN",
                          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                        ),
                      ),
                    ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
