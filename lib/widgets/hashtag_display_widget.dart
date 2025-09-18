import 'package:flutter/material.dart';

class HashtagDisplayWidget extends StatelessWidget {
  final List<String> hashtags;
  final ThemeData theme;
  final List<bool>? selectedHashtags;
  final Function(int)? onSelectHashtag;
  final int maxTagsCounter;

  const HashtagDisplayWidget({
    Key? key,
    required this.hashtags,
    required this.theme,
    this.selectedHashtags,
    this.onSelectHashtag,
    this.maxTagsCounter = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int displayCount = hashtags.length > maxTagsCounter ? maxTagsCounter : hashtags.length;

    if (displayCount == 0) return const SizedBox.shrink();

    final bool isSelectable = selectedHashtags != null && onSelectHashtag != null;

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List<Widget>.generate(displayCount, (index) {
        final bool isSelected = isSelectable && selectedHashtags!.length > index && selectedHashtags![index];

        final widget = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            // color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : theme.colorScheme.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.colorScheme.primary.withAlpha(111) : theme.colorScheme.outline.withAlpha(222),
              width: 1.2,
            ),
          ),
          child: Text(
            hashtags[index],
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );

        if (isSelectable) {
          return InkWell(onTap: () => onSelectHashtag!(index), borderRadius: BorderRadius.circular(16), child: widget);
        } else {
          return widget;
        }
      }),
    );
  }
}
