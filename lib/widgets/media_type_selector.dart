// media_type_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/media_selection_notifier.dart';
import '../screens/add/clipboard_provider.dart';

// media_type.dart
enum MediaType {
  imgur(
    title: "PASTE IMGUR URL",
    hint: "e.g. https://i.imgur.com/image.jpeg",
    outlinedIcon: Icons.add_photo_alternate_outlined,
    filledIcon: Icons.add_photo_alternate_rounded,
    label: "IMGUR",
  ),
  youtube(
    title: "PASTE YOUTUBE URL",
    hint: "e.g. https://youtu.be/video_id",
    outlinedIcon: Icons.video_call_outlined,
    filledIcon: Icons.video_call_rounded,
    label: "YOUTUBE",
  ),
  ipfs(
    title: "PASTE IPFS CID OR CREATE",
    hint: "e.g. bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74",
    outlinedIcon: Icons.cloud_upload_outlined,
    filledIcon: Icons.cloud_upload_rounded,
    label: "IPFS",
    isIpfs: true,
  ),
  odysee(
    title: "PASTE ODYSEE URL",
    hint: "e.g. https://odysee.com/@BitcoinMap:9/HijackingBitcoin:73",
    outlinedIcon: Icons.video_library_outlined,
    filledIcon: Icons.video_library_rounded,
    label: "ODYSEE",
  );

  final String title;
  final String hint;
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  final bool isIpfs;

  const MediaType({
    required this.title,
    required this.hint,
    required this.outlinedIcon,
    required this.filledIcon,
    required this.label,
    this.isIpfs = false,
  });
}

class MediaTypeSelector extends ConsumerWidget {
  final ValueChanged<MediaType> onMediaTypeSelected;

  const MediaTypeSelector({Key? key, required this.onMediaTypeSelected}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectionState = ref.watch(mediaSelectionProvider);
    final isCheckingClipboard = ref.watch(clipboardNotifierProvider.select((state) => state.isChecking));

    if (isCheckingClipboard) {
      return Container(
        color: colorScheme.surfaceVariant.withOpacity(0.1),
        height: 60,
        child: Stack(
          children: [
            LinearProgressIndicator(valueColor: AlwaysStoppedAnimation(colorScheme.primary)),
            // Keep the buttons visible but disabled
            Opacity(
              opacity: 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: MediaType.values.map((mediaType) {
                  final isSelected = selectionState.lastSelectedMediaType == mediaType;
                  return _buildMediaTypeButton(theme, mediaType, isSelected, ref);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: theme.brightness == Brightness.dark ? Colors.black.withAlpha(45) : Colors.white.withAlpha(45),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: MediaType.values.map((mediaType) {
          final isSelected = selectionState.lastSelectedMediaType == mediaType;
          return _buildMediaTypeButton(theme, mediaType, isSelected, ref);
        }).toList(),
      ),
    );
  }

  Widget _buildMediaTypeButton(ThemeData theme, MediaType mediaType, bool isSelected, WidgetRef ref) {
    final colorScheme = theme.colorScheme;
    final isCheckingClipboard = ref.watch(clipboardNotifierProvider.select((state) => state.isChecking));
    final selectionColor = isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.8);
    final backgroundColor = isSelected
        ? theme.brightness == Brightness.dark
              ? Colors.black.withAlpha(66)
              : Colors.white.withAlpha(66)
        : Colors.transparent;

    return Expanded(
      child: Tooltip(
        message: mediaType.label,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: selectionColor,
            backgroundColor: backgroundColor,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          ),
          onPressed: isCheckingClipboard
              ? null // Disable button when checking clipboard
              : () {
                  ref.read(mediaSelectionProvider.notifier).selectMediaType(mediaType);
                  onMediaTypeSelected(mediaType);
                },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? mediaType.filledIcon : mediaType.outlinedIcon, size: 24, color: selectionColor),
              const SizedBox(height: 2),
              Text(
                mediaType.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w400,
                  color: selectionColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
