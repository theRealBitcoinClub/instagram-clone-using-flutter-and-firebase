import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  final Function()? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final String text;
  final Color textColor;

  const SettingsButton({
    Key? key,
    required this.backgroundColor,
    required this.borderColor,
    required this.text,
    required this.textColor,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      child: TextButton(
        onPressed: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          width: 250,
          height: 30,
        ),
      ),
    );
  }
}
