import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/resources/auth_method.dart';
import 'package:mahakka/utils/snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with WidgetsBindingObserver {
  final TextEditingController _mnemonicController = TextEditingController();
  bool _isInputValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mnemonicController.addListener(_validateMnemonic);
    // Add the observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _mnemonicController.removeListener(_validateMnemonic);
    _mnemonicController.dispose();
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The app has just been resumed from the background.
      _checkClipboardForMnemonic();
    }
  }

  Future<void> _checkClipboardForMnemonic() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text?.trim();

    if (clipboardText != null && clipboardText.isNotEmpty) {
      // Check if the clipboard content is a valid mnemonic
      try {
        Mnemonic.fromSentence(clipboardText, Language.english);
        // It's a valid mnemonic, so update the text field
        _mnemonicController.text = clipboardText;
        // The listener will automatically validate and update the UI
      } on MnemonicException {
        // Not a valid mnemonic, do nothing.
      }
    }
  }

  void _validateMnemonic() {
    final input = _mnemonicController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _isInputValid = false;
        _errorMessage = null;
      });
      return;
    }

    String verifiedMnemonic = MemoVerifier(input).verifyMnemonic();
    if (verifiedMnemonic != "success") {
      setState(() {
        _isInputValid = false;
        _errorMessage = verifiedMnemonic;
      });
      return;
    }

    setState(() {
      _isInputValid = true;
      _errorMessage = null;
    });
  }

  Future<void> _loginUser() async {
    final authChecker = ref.read(authCheckerProvider);
    String res = await authChecker.loginInWithMnemonic(_mnemonicController.text.trim());

    if (res != "success") {
      if (mounted) showSnackBar("Unexpected error despite on the fly check: $res", context);
    }
  }

  void _generateMnemonic() {
    _mnemonicController.text = Mnemonic.generate(Language.english, length: MnemonicLength.words12).sentence;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              Image.asset('assets/images/cashtoken.png', height: 80),

              const SizedBox(height: 56),

              // Corrected TextField implementation
              TextField(
                minLines: 3,
                maxLines: 3,
                controller: _mnemonicController,
                keyboardType: TextInputType.text,
                // maxLines: null, // Allows for multiline input
                decoration: InputDecoration(
                  hintText: 'Write, paste or generate 12-word mnemonic',
                  errorText: _errorMessage, // Passed the error message
                  border: OutlineInputBorder(borderSide: Divider.createBorderSide(context)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: Divider.createBorderSide(context, color: _isInputValid ? Colors.green : theme.colorScheme.primary),
                  ),
                  enabledBorder: OutlineInputBorder(borderSide: Divider.createBorderSide(context)),
                  filled: true,
                  contentPadding: const EdgeInsets.all(8),
                ),
              ),

              const SizedBox(height: 16),

              TextButton.icon(
                icon: Icon(Icons.refresh_rounded, color: colorScheme.secondary),
                label: Text(
                  "GENERATE MNEMONIC",
                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.secondary),
                ),
                onPressed: _generateMnemonic,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16)),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // The onPressed callback is conditionally set
                  onPressed: _isInputValid ? _loginUser : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isInputValid ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
                    foregroundColor: colorScheme.onPrimary,
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
