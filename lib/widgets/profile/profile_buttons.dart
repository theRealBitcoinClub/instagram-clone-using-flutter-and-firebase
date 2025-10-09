import 'package:flutter/material.dart';

enum ButtonType { elevated, text, outlined }

class SettingsButtonUniversal extends StatelessWidget {
  final Function()? onPressed;
  final String text;
  final bool isPrimaryAction;
  final ButtonType buttonType;

  const SettingsButtonUniversal({
    Key? key,
    required this.text,
    this.onPressed,
    this.isPrimaryAction = false,
    this.buttonType = ButtonType.elevated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // final Color buttonBackgroundColor = isPrimaryAction ? colorScheme.primary : colorScheme.surfaceVariant;
    //
    final Color buttonTextColor = isPrimaryAction ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    //
    // final Color borderColor = isPrimaryAction ? colorScheme.primary : colorScheme.outline;

    // final commonStyle = ButtonStyle(
    //   backgroundColor: MaterialStateProperty.all(buttonBackgroundColor),
    //   foregroundColor: MaterialStateProperty.all(buttonTextColor),
    //   padding: MaterialStateProperty.all(EdgeInsets.zero),
    //   overlayColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
    //     if (states.contains(MaterialState.pressed)) {
    //       return isPrimaryAction ? colorScheme.onPrimary.withOpacity(0.2) : colorScheme.onSurfaceVariant.withOpacity(0.15);
    //     }
    //     return null;
    //   }),
    //   shape: MaterialStateProperty.all(
    //     RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(5),
    //       side: BorderSide(color: borderColor, width: 1.0),
    //     ),
    //   ),
    // );

    final Widget button;
    switch (buttonType) {
      case ButtonType.elevated:
        button = ElevatedButton(onPressed: onPressed, child: _buildText(theme, buttonTextColor));
        break;
      case ButtonType.text:
        button = TextButton(onPressed: onPressed, child: _buildText(theme, buttonTextColor));
        break;
      case ButtonType.outlined:
        button = OutlinedButton(onPressed: onPressed, child: _buildText(theme, buttonTextColor));
        break;
    }

    return SizedBox(width: 250, height: 35, child: button);
  }

  Widget _buildText(ThemeData theme, Color textColor) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w500),
    );
  }
}
