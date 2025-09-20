import 'package:flutter/material.dart';

class MediaPlaceholderWidget extends StatelessWidget {
  final String label;
  final IconData iconData;
  final VoidCallback onTap;
  final double iconSize;
  final double borderRadius;
  final double borderWidth;

  const MediaPlaceholderWidget({
    Key? key,
    required this.label,
    required this.iconData,
    required this.onTap,
    this.iconSize = 50,
    this.borderRadius = 12,
    this.borderWidth = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: colorScheme.primary, width: borderWidth),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, size: iconSize, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
