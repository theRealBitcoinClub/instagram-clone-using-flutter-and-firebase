import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/translation_service.dart';

enum IAB { cancel, success, alternative }

class IconAction extends ConsumerWidget {
  final String text;
  final double size;
  final VoidCallback onTap;
  final IAB type;
  final IconData icon;
  final bool skipTranslation;

  const IconAction({
    Key? key,
    required this.text,
    this.size = 15,
    required this.onTap,
    required this.type,
    required this.icon,
    this.skipTranslation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color getBackgroundColor() {
      switch (type) {
        case IAB.cancel:
          return Colors.red[800]!;
        case IAB.success:
          return Colors.green[800]!;
        case IAB.alternative:
          return Colors.blue[800]!;
      }
    }

    // Get translated text or fallback to original
    var displayText = skipTranslation ? text : ref.watch(autoTranslationTextProvider(text)).value ?? text;
    displayText = displayText.split(" ")[0];

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 88),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: Icon(icon, size: size * 1.5)),
              SizedBox(width: size / 2),
              Text(
                displayText.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: size, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
