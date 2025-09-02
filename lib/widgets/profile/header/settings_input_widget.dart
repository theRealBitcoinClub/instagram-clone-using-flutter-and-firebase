import 'package:flutter/material.dart';

class SettingsInputWidget extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String hintText;
  final TextInputType type;
  final TextEditingController controller;
  final int maxLines;

  const SettingsInputWidget({
    Key? key,
    required this.theme,
    required this.icon,
    required this.hintText,
    required this.type,
    required this.controller,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: type == TextInputType.multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: type == TextInputType.multiline ? 8.0 : 0.0),
            child: Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: type,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hintText,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
