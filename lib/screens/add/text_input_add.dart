import 'package:flutter/material.dart';

class TextInputFieldAddDialog extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final TextInputType textInputType;
  final Color? borderColor;
  final String? errorText;

  const TextInputFieldAddDialog({
    required this.textEditingController,
    required this.hintText,
    required this.textInputType,
    this.borderColor,
    this.errorText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: textEditingController,
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surface,
        hintText: hintText,
        border: const OutlineInputBorder(),
        focusedBorder: borderColor != null ? OutlineInputBorder(borderSide: BorderSide(color: borderColor!, width: 2.0)) : null,
        enabledBorder: borderColor != null ? OutlineInputBorder(borderSide: BorderSide(color: borderColor!, width: 1.0)) : null,
        errorText: errorText,
        errorStyle: TextStyle(fontSize: 12, letterSpacing: 1.2, height: 3, color: colorScheme.error, fontWeight: FontWeight.bold),
      ),
      keyboardType: textInputType,
    );
  }
}
