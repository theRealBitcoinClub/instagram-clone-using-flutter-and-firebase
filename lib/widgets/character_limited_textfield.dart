// character_limited_textfield.dart
import 'package:flutter/material.dart';

class CharacterLimitedTextField extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextStyle? normalTextStyle;
  final TextStyle? exceededTextStyle;

  const CharacterLimitedTextField({
    Key? key,
    required this.controller,
    required this.maxLength,
    this.hintText = '',
    this.onChanged,
    this.normalTextStyle,
    this.exceededTextStyle,
  }) : super(key: key);

  @override
  _CharacterLimitedTextFieldState createState() => _CharacterLimitedTextFieldState();
}

class _CharacterLimitedTextFieldState extends State<CharacterLimitedTextField> {
  int _remainingCharacters = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _remainingCharacters = widget.maxLength - widget.controller.text.length;
    widget.controller.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharacterCount);
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCharacterCount() {
    if (mounted) {
      setState(() {
        _remainingCharacters = widget.maxLength - widget.controller.text.length;
      });
      if (widget.onChanged != null) {
        widget.onChanged!(widget.controller.text);
      }
    }
  }

  void _selectAllText() {
    if (widget.controller.text.isNotEmpty) {
      widget.controller.selection = TextSelection(baseOffset: 0, extentOffset: widget.controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExceeded = _remainingCharacters < 0;

    return Column(
      children: [
        SizedBox(height: 8),
        // Wrap the TextField in a GestureDetector that handles double-tap
        GestureDetector(
          onDoubleTap: () {
            // Select all text on double tap
            _selectAllText();
          },
          behavior: HitTestBehavior.opaque,
          child: TextField(
            focusNode: _focusNode,
            maxLines: 4,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            controller: widget.controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: isExceeded ? Colors.red.withOpacity(0.5) : theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: isExceeded ? Colors.red.withOpacity(0.5) : theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isExceeded ? Colors.red.withOpacity(0.5) : theme.colorScheme.onSurface.withAlpha(140),
                  width: 2.0,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: widget.normalTextStyle,
            buildCounter: (BuildContext context, {required int currentLength, required int? maxLength, required bool isFocused}) {
              return const SizedBox.shrink();
            },
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
