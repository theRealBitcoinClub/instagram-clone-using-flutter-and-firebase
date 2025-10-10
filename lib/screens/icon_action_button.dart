import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/translation_service.dart';
import '../utils/snackbar.dart'; // Make sure to import your snackbar service

enum IAB { cancel, success, alternative }

class IconAction extends ConsumerWidget {
  final String text;
  final double size;
  final VoidCallback onTap;
  final IAB type;
  final IconData icon;
  final bool skipTranslation;
  final bool disabled; // New boolean parameter to disable the button
  final String? disabledMessage; // New parameter for snackbar message when disabled

  const IconAction({
    Key? key,
    required this.text,
    this.size = 15,
    required this.onTap,
    required this.type,
    required this.icon,
    this.skipTranslation = false,
    this.disabled = false, // Default to false (enabled)
    this.disabledMessage, // Optional disabled message
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color getBackgroundColor() {
      if (disabled) {
        return Colors.transparent; // Transparent background when disabled
      } else {
        switch (type) {
          case IAB.cancel:
            return Colors.red[800]!;
          case IAB.success:
            return Colors.green[800]!;
          case IAB.alternative:
            return Colors.blue[800]!;
        }
      }
    }

    // Handle button tap
    void handleTap() {
      if (disabled) {
        // Show translated snackbar when disabled button is tapped
        if (disabledMessage != null && disabledMessage!.isNotEmpty) {
          ref.read(snackbarServiceProvider).showTranslatedSnackBar(disabledMessage!, type: SnackbarType.info);
        }
      } else {
        onTap();
      }
    }

    // Get translated text or fallback to original
    var displayText = skipTranslation ? text : ref.watch(autoTranslationTextProvider(text)).value ?? text;
    // displayText = displayText.split(" ")[0];

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: disabled ? colorScheme.onSurface : colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              // disabled
              // ? RoundedRectangleBorder(
              //     borderRadius: BorderRadius.zero,
              //     side: BorderSide(color: colorScheme.onSurface, width: 1.0),
              //   )
              // :
              const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: disabled ? 0 : null,
          // Remove shadow when disabled
        ),
        onPressed: handleTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 88),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Icon(icon, size: size * 1.5, color: disabled ? colorScheme.onSurface : null),
              ),
              SizedBox(width: size / 2),
              Text(
                displayText.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: size, color: disabled ? colorScheme.onSurface : Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
