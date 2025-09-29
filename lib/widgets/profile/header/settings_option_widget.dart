import 'package:flutter/material.dart';
import 'package:mahakka/utils/snackbar.dart';

class SettingsOptionWidget extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String text;
  final BuildContext dialogContext;
  final VoidCallback onSelect;
  final bool isDestructive;
  final bool isEnabled;

  const SettingsOptionWidget({
    Key? key,
    required this.theme,
    required this.icon,
    required this.text,
    required this.dialogContext,
    required this.onSelect,
    this.isDestructive = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseColor = isDestructive ? theme.colorScheme.error : (theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface);

    final color = isEnabled ? baseColor : baseColor.withOpacity(0.4);

    final onPressedCallback = isEnabled
        ? () {
            Navigator.of(dialogContext).pop();
            onSelect();
          }
        : () => showSnackBar(type: SnackbarType.error, "You have to backup your mnemonic first.", dialogContext);

    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      onPressed: onPressedCallback,
      child: Row(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 20),
          const SizedBox(width: 16),
          Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: color, letterSpacing: 1)),
        ],
      ),
    );
  }
}
