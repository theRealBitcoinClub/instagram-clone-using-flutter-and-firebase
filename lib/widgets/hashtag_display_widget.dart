import 'package:flutter/material.dart';

class HashtagDisplayWidget extends StatefulWidget {
  final List<String> hashtags;
  final ThemeData theme;
  final List<bool>? selectedHashtags;
  final Function(int)? onSelectHashtag;
  final int maxTagsCounter;
  final bool noBorder;
  static const borderRadius = 9.0;
  static const borderWidth = 1.2;

  const HashtagDisplayWidget({
    Key? key,
    required this.hashtags,
    required this.theme,
    this.selectedHashtags,
    this.onSelectHashtag,
    this.noBorder = false,
    this.maxTagsCounter = 3,
  }) : super(key: key);

  static BoxDecoration borderDecoration({required bool isSelected, required ThemeData theme}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(HashtagDisplayWidget.borderRadius),
      border: Border.all(
        color: isSelected ? theme.colorScheme.secondary.withAlpha(111) : theme.colorScheme.outline.withAlpha(222),
        width: isSelected ? HashtagDisplayWidget.borderWidth + 0.3 : HashtagDisplayWidget.borderWidth,
      ),
    );
  }

  @override
  State<HashtagDisplayWidget> createState() => _HashtagDisplayWidgetState();
}

class _HashtagDisplayWidgetState extends State<HashtagDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    final int displayCount = widget.hashtags.length > widget.maxTagsCounter ? widget.maxTagsCounter : widget.hashtags.length;

    if (displayCount == 0) return const SizedBox.shrink();

    final bool isSelectable = widget.selectedHashtags != null && widget.onSelectHashtag != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(displayCount, (index) {
          final bool isSelected = isSelectable && widget.selectedHashtags!.length > index && widget.selectedHashtags![index];

          // Changed variable name from 'widget' to 'container' to avoid conflict
          final container = Container(
            margin: const EdgeInsets.only(right: 0.0),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: widget.noBorder ? null : HashtagDisplayWidget.borderDecoration(isSelected: isSelected, theme: widget.theme),
            child: Text(
              widget.hashtags[index],
              style: widget.theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: isSelected ? widget.theme.colorScheme.secondary : widget.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );

          if (isSelectable) {
            return Padding(
              padding: EdgeInsets.only(right: 9),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.onSelectHashtag!(index),
                  borderRadius: BorderRadius.circular(HashtagDisplayWidget.borderRadius),
                  child: container,
                ),
              ),
            );
          } else {
            return container;
          }
        }),
      ),
    );
  }
}
