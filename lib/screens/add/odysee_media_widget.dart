import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/red_action_button.dart';
import 'package:mahakka/widgets/unified_video_player.dart';

import 'add_post_providers.dart';

class OdyseeMediaWidget extends ConsumerWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? videoUrl;

  const OdyseeMediaWidget({super.key, required this.theme, required this.colorScheme, required this.textTheme, this.videoUrl});

  String _shortenUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 15)}...${url.substring(url.length - 15)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final odyseeUrl = videoUrl ?? ref.watch(odyseeUrlProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11.5),
              child: UnifiedVideoPlayer(
                showControls: true,
                videoUrl: odyseeUrl,
                type: VideoPlayerType.odysee,
                aspectRatio: 16 / 9,
                autoPlay: false,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        videoUrl == null
            ? Column(
                children: [
                  ChangeVideoButton(
                    onPressed: () {
                      ref.read(odyseeUrlProvider.notifier).state = '';
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Odysee URL: ${odyseeUrl}",
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : SizedBox.shrink(),
      ],
    );
  }

  // // Function to extract content name and claim ID
  // Map<String, String?>? getOdyseeVideoInfo(String url) {
  //   final match = MemoRegExp(url).firstMatch(url);
  //   if (match == null) return null;
  //
  //   return {'contentName': match.group(1), 'claimId': match.group(2)};
  // }
}
