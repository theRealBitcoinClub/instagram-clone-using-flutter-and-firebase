import 'package:flutter/material.dart';

class RedActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final double? width;

  const RedActionButton({super.key, required this.onPressed, required this.text, this.icon = Icons.edit_outlined, this.width});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(text),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: Size(width ?? double.infinity, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// Optional: Specific button variants for common use cases
class ChangeImageButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ChangeImageButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RedActionButton(onPressed: onPressed, text: "CHANGE IMAGE", icon: Icons.edit_outlined);
  }
}

class ChangeVideoButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ChangeVideoButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RedActionButton(onPressed: onPressed, text: "CHANGE VIDEO", icon: Icons.video_library_outlined);
  }
}

class ChangeMediaButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ChangeMediaButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return RedActionButton(onPressed: onPressed, text: "CHANGE MEDIA", icon: Icons.clear_outlined);
  }
}
