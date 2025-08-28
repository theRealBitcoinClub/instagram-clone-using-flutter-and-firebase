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

    // TODO: VERIFY MNEMONIC IS VALID locally before sending to AuthChecker if possible
    // This could involve checking word count, checksum, etc. using the bip39_mnemonic package.
    // Example (very basic, actual validation is more complex):
    // if (!Mnemonic.isValid(_mnemonicController.text.trim())) {
    //   if (mounted) {
    //     showSnackBar("Invalid mnemonic phrase format.", context);
    //     setState(() => _isLoading = false);
    //   }
    //   return;
    // }

    final authChecker = ref.read(authCheckerProvider);
    String res = await authChecker.loginInWithMnemonic(_mnemonicController.text.trim());

    if (mounted) {
      // Check mounted again after await
      if (res != 'success') {
        showSnackBar(res, context); // Ensure showSnackBar is themed
      }
      // If login is successful, AuthChecker should handle navigation.
      // If not, we just stop loading.
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
    if (mounted) {
      showSnackBar("New mnemonic generated in the field.", context);
    }
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

              // Generate Mnemonic Button (Addressing the TODO)
              TextButton.icon(
                icon: Icon(Icons.refresh_rounded, color: colorScheme.secondary),
                label: Text(
                  "GENERATE NEW MNEMONIC",
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
                        // style: ElevatedButton.styleFrom(
                        //   backgroundColor: colorScheme.primary,
                        //   foregroundColor: colorScheme.onPrimary,
                        //   textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                        // ),
                        child: Text(
                          "LOGIN",
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            // If your ElevatedButtonTheme doesn't set text color, you might need:
                            // color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),

              const Spacer(flex: 2),

              // Toggle to Signup Screen (if `onToggle` is provided)
              if (widget.onToggle != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Are you a new user? ", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                        // Add padding for better tap target
                        child: Text(
                          "SIGN UP",
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary, // Use primary color for the link
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
