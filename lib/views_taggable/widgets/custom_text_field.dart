import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final Widget? suffixIcon;
  final int? minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.suffixIcon,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int effectiveMinLines = (maxLines != null && maxLines! > 1) ? (minLines ?? 1) : 1;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      minLines: effectiveMinLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: theme.textTheme.bodyLarge?.copyWith(),
      cursorColor: theme.textSelectionTheme.cursorColor ?? theme.colorScheme.primary,
      decoration: InputDecoration(hintText: hintText, suffixIcon: suffixIcon),
    );
  }
}
