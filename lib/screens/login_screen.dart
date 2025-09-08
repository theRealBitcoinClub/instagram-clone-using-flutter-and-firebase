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
  final List<String> _wordList = Language.english.list;
  bool _isInputValid = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mnemonicController.addListener(_handleInput);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _mnemonicController.removeListener(_handleInput);
    _mnemonicController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForMnemonic();
    }
  }

  Future<void> _checkClipboardForMnemonic() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text?.trim();

    if (clipboardText != null && clipboardText.isNotEmpty) {
      try {
        Mnemonic.fromSentence(clipboardText, Language.english);
        _mnemonicController.text = clipboardText;
      } on MnemonicException {
        // Not a valid mnemonic, do nothing.
      }
    }
  }

  String _processedMnemonic = "";

  void _handleInput() {
    final text = _mnemonicController.text;
    final words = text.split(' ');
    final lastWord = words.last;

    if (lastWord.isNotEmpty) {
      final matchingWords = _wordList.where((word) => word.startsWith(lastWord)).toList();
      if (matchingWords.length == 1) {
        final newText = text.substring(0, text.length - lastWord.length) + matchingWords.first + ' ';
        _mnemonicController.value = _mnemonicController.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
          composing: TextRange.empty,
        );
      }
    }

    _validateMnemonic();
  }

  void _validateMnemonic() {
    var inputTrimmed = _mnemonicController.text.trim();
    if (inputTrimmed.isEmpty) {
      setState(() {
        _isInputValid = false;
        _errorMessage = null;
      });
      return;
    }

    _processedMnemonic = toLowCaseAndRemoveTooManySpaces(inputTrimmed);
    String verifiedMnemonic = MemoVerifier(_processedMnemonic).verifyMnemonic();
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

  String toLowCaseAndRemoveTooManySpaces(String inputTrimmed) {
    final processedMnemonic = inputTrimmed.toLowerCase().split(RegExp(r'\s+')).join(' ');
    return processedMnemonic;
  }

  void _loginUser() {
    setState(() {
      _isLoading = true;
    });
    doHeavyWork();
  }

  Future<void> doHeavyWork() async {
    try {
      final authChecker = ref.read(authCheckerProvider);
      String res = await authChecker.loginInWithMnemonic(_processedMnemonic);
      if (res != "success") {
        if (mounted) showSnackBar("Unexpected error despite on the fly check: $res", context);
      }
    } catch (e) {
      if (mounted) showSnackBar("Login failed: $e", context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              Image.asset('assets/splash.png', height: 120),
              const SizedBox(height: 56),
              TextField(
                minLines: 3,
                maxLines: 3,
                controller: _mnemonicController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Write, paste or generate 12-word mnemonic',
                  errorText: _errorMessage,
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
              _isLoading ? LinearProgressIndicator() : SizedBox(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isInputValid && !_isLoading) ? _loginUser : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isInputValid && !_isLoading) ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
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
