import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';

import '../screens/add_post_controller.dart';

class CharacterLimitedTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final int maxLength;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final int? minLines;
  final String? topicIdPrefix;

  const CharacterLimitedTextField({
    Key? key,
    required this.controller,
    required this.maxLength,
    this.hintText = '',
    this.onChanged,
    this.minLines,
    this.topicIdPrefix,
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
    _updateCharacterCount(); // Initialize with current count
    widget.controller.addListener(_updateCharacterCount);
  }

  @override
  void didUpdateWidget(CharacterLimitedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update character count when prefix changes
    if (widget.topicIdPrefix != oldWidget.topicIdPrefix) {
      _updateCharacterCount();
    }
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
        // Calculate total length including prefix
        final prefixLength = widget.topicIdPrefix?.length ?? 0;
        final textLength = widget.controller.text.length;
        final totalLength = prefixLength + textLength;

        _remainingCharacters = widget.maxLength - totalLength;
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
    String? hint = ref.watch(autoTranslationTextProvider(widget.hintText)).value ?? widget.hintText;
    var postController = ref.watch(addPostControllerProvider.notifier);

    // Calculate if exceeded - include prefix length
    final prefixLength = widget.topicIdPrefix?.length ?? 0;
    final totalLength = prefixLength + widget.controller.text.length;
    final isExceeded = totalLength > widget.maxLength;

    // Calculate the top padding needed to accommodate the prefix
    final hasPrefix = widget.topicIdPrefix?.isNotEmpty == true;
    final topPadding = hasPrefix ? 33.0 : 12.0; // Extra space for prefix

    return Column(
      children: [
        SizedBox(height: 9),
        GestureDetector(
          onDoubleTap: () {
            _selectAllText();
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              // TextField with adjusted top padding
              TextField(
                textAlignVertical: TextAlignVertical.bottom,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: widget.minLines ?? 1,
                textInputAction: TextInputAction.newline,
                controller: widget.controller,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  errorStyle: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.error),
                  hintText: hint,
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
                  // Adjust content padding to accommodate the prefix
                  contentPadding: EdgeInsets.fromLTRB(12, topPadding, 12, 12),
                ),
                style: theme.textTheme.bodyMedium,
                buildCounter: (BuildContext context, {required int currentLength, required int? maxLength, required bool isFocused}) {
                  return const SizedBox.shrink();
                },
              ),

              // Prefix overlay - positioned to appear as first line
              if (hasPrefix)
                Positioned(
                  top: 12, // Position inside the TextField border
                  left: 15, // Align with text content
                  child: Container(
                    padding: const EdgeInsets.only(right: 9.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.background, // Match background
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      overflow: TextOverflow.ellipsis,
                      widget.topicIdPrefix!,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        height: 1.2, // Match text field line height
                      ),
                    ),
                  ),
                ),

              // Character counter that includes prefix length
              Positioned(
                bottom: 6,
                right: 9,
                child: Text(
                  '$_remainingCharacters',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: isExceeded ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 9),
      ],
    );
  }
}
