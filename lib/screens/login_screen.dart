import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/resources/auth_method.dart';

import '../utils/snackbar.dart';

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
  String _processedMnemonic = "";

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
    return inputTrimmed.toLowerCase().split(RegExp(r'\s+')).join(' ');
  }

  void _loginUser() {
    setState(() {
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      doHeavyWork();
    });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
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
                // FIXED: TextButton with proper inherit handling
                TextButton(
                  onPressed: _generateMnemonic,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    foregroundColor: colorScheme.secondary,
                  ),
                  child: Text(
                    "GENERATE MNEMONIC",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                      inherit: false, // ← CRITICAL FIX: Set inherit to false
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading) LinearProgressIndicator(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isInputValid && !_isLoading) ? _loginUser : null,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return colorScheme.primary.withOpacity(0.5);
                        }
                        return colorScheme.primary;
                      }),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return colorScheme.onPrimary.withOpacity(0.5);
                        }
                        return colorScheme.onPrimary;
                      }),
                      textStyle: MaterialStateProperty.resolveWith<TextStyle>((Set<MaterialState> states) {
                        final baseStyle = textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                          inherit: false, // ← CONSISTENT: Set inherit to false
                        );

                        if (states.contains(MaterialState.disabled)) {
                          return baseStyle?.copyWith(color: colorScheme.onPrimary.withOpacity(0.5)) ??
                              TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary.withOpacity(0.5),
                                inherit: false,
                              );
                        }
                        return baseStyle ?? TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onPrimary, inherit: false);
                      }),
                    ),
                    child: const Text("LOGIN"),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
