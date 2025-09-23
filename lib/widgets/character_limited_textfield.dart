import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/add_post_controller.dart';

class CharacterLimitedTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextStyle? normalTextStyle;
  final TextStyle? exceededTextStyle;
  final int? minLines;

  const CharacterLimitedTextField({
    Key? key,
    required this.controller,
    required this.maxLength,
    this.hintText = '',
    this.onChanged,
    this.normalTextStyle,
    this.exceededTextStyle,
    this.minLines,
  }) : super(key: key);

  @override
  _CharacterLimitedTextFieldState createState() => _CharacterLimitedTextFieldState();
}

class _CharacterLimitedTextFieldState extends ConsumerState<CharacterLimitedTextField> {
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
    // String? translation = ref.watch(translatedTextProvider.notifier).state;
    // if (translation != null && translation.isNotEmpty)
    //   widget.controller.text = translation;
    // translationProvider.state.
    var postController = ref.watch(addPostControllerProvider.notifier);
    final isExceeded = _remainingCharacters < postController.getMediaUrl().length;

    return Column(
      children: [
        SizedBox(height: 8),
        GestureDetector(
          onDoubleTap: () {
            _selectAllText();
          },
          behavior: HitTestBehavior.opaque,
          child: TextField(
            focusNode: _focusNode,
            maxLines: 4,
            minLines: widget.minLines ?? 1,
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
