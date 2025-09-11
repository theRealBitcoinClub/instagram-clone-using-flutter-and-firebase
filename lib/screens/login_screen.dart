import 'dart:async';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/resources/auth_method.dart';

import '../utils/snackbar.dart';
import '../widgets/animations/animated_grow_fade_in.dart'; // Import your animation widget

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
  Timer? _clipboardTimer;
  final FocusNode _mnemonicFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mnemonicController.addListener(_handleInput);
    WidgetsBinding.instance.addObserver(this);

    // Start clipboard checking timer
    _startClipboardTimer();
  }

  @override
  void dispose() {
    _mnemonicFocusNode.dispose();
    _mnemonicController.removeListener(_handleInput);
    _mnemonicController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // Cancel the timer to prevent memory leaks
    _clipboardTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForMnemonic();
      // Restart timer when app comes back to foreground
      _startClipboardTimer();
    } else if (state == AppLifecycleState.paused) {
      // Stop timer when app goes to background
      _clipboardTimer?.cancel();
    }
  }

  void _startClipboardTimer() {
    // Cancel existing timer if any
    _clipboardTimer?.cancel();

    // Create a new timer that checks clipboard every second
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkClipboardForMnemonic();
    });
  }

  Future<void> _checkClipboardForMnemonic() async {
    // Don't check if already has valid input or loading
    if (_isInputValid || _isLoading) {
      return;
    }

    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final clipboardText = clipboardData?.text?.trim();

    if (clipboardText != null && clipboardText.isNotEmpty) {
      try {
        // Validate if it's a proper mnemonic
        final mnemonic = Mnemonic.fromSentence(clipboardText, Language.english);

        // Only set if it's different from current text
        if (_mnemonicController.text != mnemonic.sentence) {
          if (mounted) {
            setState(() {
              _mnemonicController.text = mnemonic.sentence;
            });
          }
        }
      } on MnemonicException {
        // Not a valid mnemonic, do nothing.
      } catch (e) {
        // Handle any other errors silently
      }
    }
  }

  void _handleInput() {
    final text = _mnemonicController.text;

    // Check if we should clear on backspace
    if (text.length < _previousTextLength && _isInputValid) {
      _mnemonicController.clear();
      _previousText = '';
      _previousTextLength = 0;
      _validateMnemonic();
      return;
    }

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

    // Store previous values for backspace detection
    _previousText = text;
    _previousTextLength = text.length;

    _validateMnemonic();
  }

  // Add these variables to your class
  String _previousText = '';
  int _previousTextLength = 0;

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

    // Focus on the textfield and open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mnemonicFocusNode.requestFocus();

      // Optional: Move cursor to the end
      _mnemonicController.selection = TextSelection.fromPosition(TextPosition(offset: _mnemonicController.text.length));
    });

    _validateMnemonic();
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
                  focusNode: _mnemonicFocusNode,
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

                // REPLACED: TextButton with Animated ElevatedButton
                AnimatedGrowFadeIn(
                  show: !_isInputValid, // Show only when no valid mnemonic
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateMnemonic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red background
                        foregroundColor: Colors.white, // White text
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          inherit: false, // Consistent with theme
                        ),
                      ),
                      child: const Text("GENERATE MNEMONIC"),
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
                          inherit: false,
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
