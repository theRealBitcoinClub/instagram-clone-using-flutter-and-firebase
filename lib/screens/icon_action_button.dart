import 'package:flutter/material.dart';

enum IAB { cancel, success, alternative }

class IconAction extends StatelessWidget {
  final String text;
  final double size;
  final VoidCallback onTap;
  final IAB type;
  final IconData icon;

  const IconAction({Key? key, required this.text, this.size = 16, required this.onTap, required this.type, required this.icon})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color getBackgroundColor() {
      switch (type) {
        case IAB.cancel:
          return Colors.red[900]!;
        case IAB.success:
          return Colors.green[900]!;
        case IAB.alternative:
          return Colors.blue[900]!;
      }
    }

    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: getBackgroundColor(),
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 88),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: Icon(icon, size: size * 1.5)),
              SizedBox(width: size / 2),
              Text(text.toUpperCase(), style: TextStyle(fontSize: size)),
            ],
          ),
        ),
      ),
    );
  }
}
