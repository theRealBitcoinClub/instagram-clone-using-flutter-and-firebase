import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/widgets/red_action_button.dart';

import '../../widgets/unified_image_widget.dart';
import 'add_post_providers.dart';

class IpfsMediaWidget extends ConsumerWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? ipfsCid;

  const IpfsMediaWidget({super.key, required this.theme, required this.colorScheme, required this.textTheme, this.ipfsCid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cid = ipfsCid ?? ref.watch(ipfsCidProvider);
    final ipfsUrl = '${IpfsConfig.preferredNode}$cid';

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
              child: UnifiedImageWidget(
                imageUrl: cid!,
                sourceType: ImageSourceType.ipfs,
                fitMode: ImageFitMode.contain,
                aspectRatio: 16 / 9,
                border: Border(),
                backgroundColor: colorScheme.surface,
                showLoadingProgress: true,
                errorWidget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_outlined, color: colorScheme.error.withAlpha(153), size: 36),
                    const SizedBox(height: 8),
                    Text("Error loading IPFS content", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                    const SizedBox(height: 8),
                    Text("$cid", style: textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ipfsCid == null
            ? Column(
                children: [
                  ChangeMediaButton(
                    onPressed: () {
                      ref.read(ipfsCidProvider.notifier).state = '';
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "IPFS CID: $cid",
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : SizedBox.shrink(),
      ],
    );
  }
}
