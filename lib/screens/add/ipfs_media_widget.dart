import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/red_action_button.dart';

import 'add_post_providers.dart';

class IpfsMediaWidget extends ConsumerWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const IpfsMediaWidget({super.key, required this.theme, required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cid = ref.watch(ipfsCidProvider);
    final ipfsUrl = 'https://free-bch.fullstack.cash/ipfs/view/$cid';

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
              child: Image.network(
                ipfsUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined, color: colorScheme.error, size: 36),
                        const SizedBox(height: 8),
                        Text("Error loading IPFS content", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                        const SizedBox(height: 8),
                        Text("CID: $cid", style: textTheme.bodySmall),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
    );
  }
}
