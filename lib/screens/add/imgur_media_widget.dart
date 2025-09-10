import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_post_providers.dart';

class ImgurMediaWidget extends ConsumerWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const ImgurMediaWidget({super.key, required this.theme, required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgurUrl = ref.watch(imgurUrlProvider);

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
                imgurUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(imgurUrlProvider.notifier).state = '';
                  });
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 36),
                        const SizedBox(height: 8),
                        Text("Error loading image", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
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
        TextButton.icon(
          icon: Icon(Icons.edit_outlined, size: 18),
          label: const Text("Change Image"),
          onPressed: () {
            ref.read(imgurUrlProvider.notifier).state = '';
            // ref.read(youtubeVideoIdProvider.notifier).state = '';
            // ref.read(ipfsCidProvider.notifier).state = '';
            // ref.read(odyseeUrlProvider.notifier).state = '';
            // ref.read(youtubeControllerProvider.notifier).state = null;
            // ref.read(clearMediaProvider);
          },
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.secondary,
            textStyle: textTheme.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}
