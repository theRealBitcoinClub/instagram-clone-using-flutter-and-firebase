import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/translation_service.dart';

class SettingsOptionWidget extends ConsumerWidget {
  final ThemeData theme;
  final IconData icon;
  final String text;
  final BuildContext dialogContext;
  final VoidCallback onSelect;
  final bool isDestructive;
  final bool isEnabled;

  const SettingsOptionWidget({
    super.key,
    required this.theme,
    required this.icon,
    required this.text,
    required this.dialogContext,
    required this.onSelect,
    this.isDestructive = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translatedText = ref.watch(autoTranslationTextProvider(text));

    return translatedText.when(
      data: (translated) => _buildContent(context, translated.toUpperCase(), ref),
      loading: () => _buildContent(context, text, ref), // Show original while loading
      error: (error, stack) => _buildContent(context, text, ref), // Fallback to original
    );
  }

  Widget _buildContent(BuildContext context, String displayText, ref) {
    final baseColor = isDestructive ? theme.colorScheme.error : (theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface);
    final color = isEnabled ? baseColor.withAlpha(222) : baseColor.withAlpha(153);

    final onPressedCallback = isEnabled
        ? () {
            Navigator.of(dialogContext).pop();
            onSelect();
          }
        : onSelect;

    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
      onPressed: onPressedCallback,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(displayText, style: theme.textTheme.bodyLarge?.copyWith(color: color, letterSpacing: 1)),
        ],
      ),
    );
  }
}
