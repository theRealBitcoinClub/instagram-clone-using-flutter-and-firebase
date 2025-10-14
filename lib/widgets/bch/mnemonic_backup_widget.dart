import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/icon_action_button.dart';

import '../../main.dart';
import '../../provider/translation_service.dart';

class MnemonicBackupWidget extends ConsumerStatefulWidget {
  final String mnemonic;
  final String mnemonicBackupKey;

  const MnemonicBackupWidget({Key? key, required this.mnemonic, required this.mnemonicBackupKey}) : super(key: key);

  @override
  ConsumerState<MnemonicBackupWidget> createState() => _MnemonicBackupWidgetState();
}

class _MnemonicBackupWidgetState extends ConsumerState<MnemonicBackupWidget> {
  late final List<String> _mnemonicWords;
  bool _didAttemptConfirm = false;

  // DRY text constants
  static const String _backupTitle = "Backup Your Secret Key";
  static const String _warningText = "⚠️ This is your secret recovery key. Write it down and store it safely!";
  static const String _mnemonicLabel = "12-word mnemonic";
  static const String _responsibilityText =
      "By clicking 'I have backed it up', you take full responsibility for its safekeeping, anyone who has this phrase can access your wallet";
  static const String _backupButtonText = "I HAVE BACKED IT UP";
  static const String _verifyTitle = "Verify Backup";
  static const String _verifyInstructions = "To confirm, enter the first and last words of your secret key:";
  static const String _firstWordLabel = "First Word";
  static const String _lastWordLabel = "Last Word";
  static const String _incorrectFirstWord = "Incorrect first word.";
  static const String _incorrectLastWord = "Incorrect last word.";
  static const String _cancelText = "CANCEL";
  static const String _confirmText = "CONFIRM";

  @override
  void initState() {
    super.initState();
    _mnemonicWords = widget.mnemonic.split(' ');
  }

  void _showVerificationDialog(BuildContext context) {
    final _firstWordCtrl = TextEditingController();
    final _lastWordCtrl = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        var textTheme2 = Theme.of(dialogContext).textTheme;
        return AlertDialog(
          title: Consumer(
            builder: (context, ref, child) {
              final translatedTitle = ref.watch(autoTranslationTextProvider(_verifyTitle));
              return Text(translatedTitle.value ?? _verifyTitle);
            },
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Consumer(
                  builder: (context, ref, child) {
                    final translatedInstructions = ref.watch(autoTranslationTextProvider(_verifyInstructions));
                    return Text(translatedInstructions.value ?? _verifyInstructions);
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  style: textTheme2.bodyLarge!.copyWith(fontWeight: FontWeight.w400),
                  controller: _firstWordCtrl,
                  decoration: InputDecoration(labelText: _firstWordLabel, labelStyle: textTheme2.bodyMedium, hintStyle: textTheme2.bodyMedium),
                  onChanged: (_) {
                    if (_didAttemptConfirm) _formKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null || value.trim().toLowerCase() != _mnemonicWords.first) {
                      return _incorrectFirstWord; // Keep error messages in English as they're technical
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  style: textTheme2.bodyLarge!.copyWith(fontWeight: FontWeight.w400),
                  controller: _lastWordCtrl,
                  decoration: InputDecoration(labelText: _lastWordLabel, labelStyle: textTheme2.bodyMedium, hintStyle: textTheme2.bodyMedium),
                  onChanged: (_) {
                    if (_didAttemptConfirm) _formKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null || value.trim().toLowerCase() != _mnemonicWords.last) {
                      return _incorrectLastWord; // Keep error messages in English as they're technical
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  IconAction(text: "CANCEL", onTap: () => Navigator.of(dialogContext).pop(), type: IAB.cancel, icon: Icons.cancel_outlined),
                  IconAction(
                    icon: Icons.check_circle_outline_rounded,
                    text: "CONFIRM",
                    type: IAB.success,
                    onTap: () {
                      _didAttemptConfirm = true;
                      if (_formKey.currentState!.validate()) {
                        ref.read(sharedPreferencesProvider).setBool(widget.mnemonicBackupKey, true);
                        Navigator.of(dialogContext).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Consumer(
        builder: (context, ref, child) {
          final translatedTitle = ref.watch(autoTranslationTextProvider(_backupTitle));
          return Text(translatedTitle.value ?? _backupTitle);
        },
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Consumer(
              builder: (context, ref, child) {
                final translatedWarning = ref.watch(autoTranslationTextProvider(_warningText));
                return Text(translatedWarning.value ?? _warningText, style: const TextStyle(color: Colors.red));
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: widget.mnemonic),
              readOnly: true,
              maxLines: null,
              decoration: InputDecoration(
                labelText: _mnemonicLabel, // Technical term - keep in English
                border: const OutlineInputBorder(),
              ),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final translatedResponsibility = ref.watch(autoTranslationTextProvider(_responsibilityText));
                return Text(translatedResponsibility.value ?? _responsibilityText);
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Consumer(
          builder: (context, ref, child) {
            final translatedButton = ref.watch(autoTranslationTextProvider(_backupButtonText));
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showVerificationDialog(context);
              },
              style: ElevatedButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(translatedButton.value ?? _backupButtonText),
            );
          },
        ),
      ],
    );
  }
}
