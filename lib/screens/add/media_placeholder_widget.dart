import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/translation_service.dart';

class MediaPlaceholderWidget extends ConsumerWidget {
  final String label;
  final IconData iconData;
  final VoidCallback onTap;
  final double iconSize;
  final double borderRadius;
  final double borderWidth;

  const MediaPlaceholderWidget({
    super.key,
    required this.label,
    required this.iconData,
    required this.onTap,
    this.iconSize = 50,
    this.borderRadius = 12,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    String displayLabel = ref.watch(autoTranslationTextProvider(label)).value ?? label;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: colorScheme.onSurface, width: borderWidth),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: colorScheme.primary.withOpacity(0.3),
            highlightColor: colorScheme.primary.withOpacity(0.1),
            child: AspectRatio(
              aspectRatio: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(iconData, size: iconSize, color: colorScheme.onSurface),
                  const SizedBox(height: 8),
                  Text(
                    displayLabel,
                    style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
