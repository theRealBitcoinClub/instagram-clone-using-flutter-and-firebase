import 'package:flutter/material.dart';

class MnemonicBackupWidget extends StatefulWidget {
  final String mnemonic;
  final VoidCallback onVerificationComplete;

  const MnemonicBackupWidget({Key? key, required this.mnemonic, required this.onVerificationComplete}) : super(key: key);

  @override
  _MnemonicBackupWidgetState createState() => _MnemonicBackupWidgetState();
}

class _MnemonicBackupWidgetState extends State<MnemonicBackupWidget> {
  late final List<String> _mnemonicWords;
  bool _didAttemptConfirm = false;

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
        return AlertDialog(
          title: const Text("Verify Backup"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text("To confirm, enter the first and last words of your mnemonic phrase:"),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstWordCtrl,
                  decoration: const InputDecoration(labelText: "First Word"),
                  onChanged: (_) {
                    if (_didAttemptConfirm) _formKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null || value.trim().toLowerCase() != _mnemonicWords.first) {
                      return "Incorrect first word.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastWordCtrl,
                  decoration: const InputDecoration(labelText: "Last Word"),
                  onChanged: (_) {
                    if (_didAttemptConfirm) _formKey.currentState?.validate();
                  },
                  validator: (value) {
                    if (value == null || value.trim().toLowerCase() != _mnemonicWords.last) {
                      return "Incorrect last word.";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            const SizedBox(height: 12),
            TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              child: const Text("CONFIRM"),
              onPressed: () {
                // setInnerState(() {
                _didAttemptConfirm = true;
                // });
                if (_formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  widget.onVerificationComplete();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Backup Your Mnemonic Phrase"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text(
              "⚠️ This is your secret recovery phrase. Write it down and store it safely!",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: widget.mnemonic),
              readOnly: true,
              maxLines: null,
              decoration: const InputDecoration(labelText: '12-word mnemonic', border: OutlineInputBorder()),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              "By clicking 'I have backed it up', you take full responsibility for its safekeeping, anyone who has this phrase can access your wallet",
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text("I HAVE BACKED IT UP"),
          onPressed: () {
            Navigator.of(context).pop();
            _showVerificationDialog(context);
          },
          style: ElevatedButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}
