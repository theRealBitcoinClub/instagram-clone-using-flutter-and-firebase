import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText; // Renamed from 'hint' to match InputDecoration property
  final Widget? suffixIcon; // Renamed from 'suffix' to match InputDecoration property
  final int? minLines; // Made these optional with defaults
  final int? maxLines;
  final TextInputType? keyboardType; // Added for more flexibility
  final bool obscureText; // Added for password fields
  final String? Function(String?)? validator; // Added for form validation
  final ValueChanged<String>? onChanged; // Added callback for text changes
  final TextCapitalization textCapitalization; // Added for text capitalization

  const CustomTextField({
    Key? key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.suffixIcon,
    this.minLines, // Default will be 1 if not a multiline field
    this.maxLines = 1, // Default to single line
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // InputDecoration will largely be styled by theme.inputDecorationTheme
    // TextStyle for input will largely be styled by theme.textTheme.titleMedium (for TextFormField)

    // Determine default minLines if not a multi-line field from maxLines
    final int effectiveMinLines = (maxLines != null && maxLines! > 1) ? (minLines ?? 1) : 1;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      minLines: effectiveMinLines, // Use effectiveMinLines
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      // The style of the text entered by the user.
      // This will often be inherited from the default text style for TextFormFields
      // which is typically derived from theme.textTheme.titleMedium or similar.
      // You can override it if needed, but it's best to rely on the theme's defaults.
      style: theme.textTheme.bodyLarge?.copyWith(
        // Example: if you need to ensure a specific color not covered by the base style
        // color: theme.colorScheme.onSurface,
      ),
      cursorColor: theme.textSelectionTheme.cursorColor ?? theme.colorScheme.primary, // Themed cursor color
      decoration: InputDecoration(
        hintText: hintText,
        // hintStyle will be taken from theme.inputDecorationTheme.hintStyle
        // If you need to override:
        // hintStyle: theme.inputDecorationTheme.hintStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        suffixIcon: suffixIcon,
        // Border properties (border, enabledBorder, focusedBorder, errorBorder, etc.)
        // will be primarily defined by your theme.inputDecorationTheme.
        // The following are examples if you NEED to override specific aspects not covered by your global theme.
        // It's generally better to define these in your main theme's InputDecorationTheme.

        // Example: If you want all borders to have a specific radius for THIS text field only.
        // border: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(30),
        //   borderSide: BorderSide(color: theme.colorScheme.outline), // Use outline color from theme
        // ),
        // enabledBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(30),
        //   borderSide: BorderSide(color: theme.colorScheme.outline),
        // ),
        // focusedBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(30),
        //   borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0), // Focused border uses primary color
        // ),
        // errorBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(30),
        //   borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
        // ),
        // focusedErrorBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(30),
        //   borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
        // ),
        // disabledBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(30),
        //   borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.38)),
        // ),

        // To use the default theme's border settings, simply don't specify these border properties here.
        // The InputDecoration will automatically use theme.inputDecorationTheme.
      ),
    );
  }
}
