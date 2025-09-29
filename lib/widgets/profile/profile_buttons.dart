import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  final Function()? onPressed;
  final String text;
  final bool isPrimaryAction; // To differentiate styling slightly if needed

  const SettingsButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isPrimaryAction = false, // Default to a less prominent style
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Determine colors based on theme and if it's a primary action
    final Color buttonBackgroundColor = isPrimaryAction
        ? colorScheme
              .primary // Use primary color for primary actions
        : colorScheme.surfaceVariant; // Use a subtle background otherwise

    final Color buttonBorderColor = isPrimaryAction
        ? colorScheme
              .primary // Border matches background for a solid look
        : colorScheme.outline; // Standard outline color

    final Color buttonTextColor = isPrimaryAction
        ? colorScheme
              .onPrimary // Text color for onPrimary
        : colorScheme.onSurfaceVariant; // Text color for onSurfaceVariant

    return Container(
      // margin: const EdgeInsets.symmetric(vertical: 4.0), // Optional margin
      width: 250, // Specific width requirement
      height: 35, // Specific height requirement (adjust if needed for tap target)
      child: TextButton(
        onPressed: onPressed,
        style:
            TextButton.styleFrom(
              padding: EdgeInsets.zero, // Remove TextButton's default padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // Match your decoration's border radius
              ),
            ).copyWith(
              // Overlay color for tap feedback, can be themed
              overlayColor: MaterialStateProperty.all(colorScheme.onSurface.withOpacity(0.1)),
            ),
        child: Container(
          decoration: BoxDecoration(
            color: buttonBackgroundColor,
            border: Border.all(color: buttonBorderColor, width: 1.0), // Standard border width
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: theme.textTheme.labelMedium!.copyWith(
              // Use a standard text style from theme
              color: buttonTextColor,
              // fontWeight: FontWeight.bold, // Keep bold if that's the desired style
            ),
          ),
        ),
      ),
    );
  }
}
