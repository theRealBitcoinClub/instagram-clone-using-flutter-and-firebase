import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/red_action_button.dart';

import 'add_post_providers.dart';

class ImgurMediaWidget extends ConsumerWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String? imgurUrl;

  const ImgurMediaWidget({super.key, required this.theme, required this.colorScheme, required this.textTheme, this.imgurUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imgUrl = imgurUrl ?? ref.watch(imgurUrlProvider)!;

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
                imgUrl,
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
        imgurUrl == null
            ? Column(
                children: [
                  ChangeImageButton(
                    onPressed: () {
                      ref.read(imgurUrlProvider.notifier).state = '';
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Image Url: $imgUrl",
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
