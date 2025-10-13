import 'package:flutter/material.dart';

class SettingsInputWidget extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String hintText;
  final TextInputType type;
  final TextEditingController controller;
  final int maxLines;
  final int? maxLength;

  const SettingsInputWidget({
    Key? key,
    required this.theme,
    required this.icon,
    required this.hintText,
    required this.type,
    required this.controller,
    this.maxLength,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              maxLength: maxLength,
              controller: controller,
              keyboardType: type,
              maxLines: maxLines,
              style: theme.textTheme.bodyMedium,
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
