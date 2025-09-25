import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/provider/url_input_verification_notifier.dart';
import 'package:mahakka/screens/ipfs_pin_claim_screen.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/animations/animated_grow_fade_in.dart';
import 'add/add_post_providers.dart';

// Provider for selected CID state
final selectedCidProvider = StateProvider<String?>((ref) => null);

class IPFSGalleryScreen extends ConsumerWidget {
  final List<String> ipfsCids;

  const IPFSGalleryScreen({Key? key, required this.ipfsCids}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCid = ref.watch(selectedCidProvider);
    final hasSelection = selectedCid != null;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme ? Colors.black.withAlpha(133) : Colors.white.withAlpha(133);
    final validCids = ipfsCids.where((cid) => cid.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 50,
        title: Text(
          hasSelection ? '${selectedCid}' : 'Tap image to select or create new one',
          style: textTheme.titleSmall!.copyWith(letterSpacing: 0.2, fontWeight: FontWeight.w400, fontSize: 14),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          if (!hasSelection)
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () => _createNewIpfsPin(context),
              tooltip: 'Create new IPFS pin',
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () => ref.read(selectedCidProvider.notifier).state = null,
              tooltip: 'Clear selection',
            ),
        ],
      ),
      body: Column(
        children: [
          // IPFS Images ListView
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: validCids.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: validCids.length,
                        itemBuilder: (context, index) {
                          final cid = validCids[index];
                          final isSelected = selectedCid == cid;
                          return IPFSImageCard(cid: cid, isSelected: isSelected);
                        },
                      ),
              ),
            ),
          ),

          // Button Row
          GalleryActionButtonRow(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No IPFS images found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first IPFS pin to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _createNewIpfsPin(BuildContext context) {
    Navigator.pop(context);
    IpfsPinClaimScreen.show(context);
  }
}

class IPFSImageCard extends ConsumerWidget {
  final String cid;
  final bool isSelected;

  const IPFSImageCard({Key? key, required this.cid, required this.isSelected}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imageUrl = '${IpfsConfig.preferredNode}$cid';
    final isDarkTheme = theme.brightness == Brightness.dark;
    final overlayColor = isDarkTheme ? Colors.black.withAlpha(133) : Colors.white.withAlpha(133);
    final backgroundColor = isDarkTheme ? Colors.black.withAlpha(133) : Colors.white.withAlpha(133);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      elevation: 2,
      color: backgroundColor,
      child: GestureDetector(
        onTap: () => ref.read(selectedCidProvider.notifier).state = cid,
        child: Stack(
          children: [
            InkWell(
              onTap: () => ref.read(selectedCidProvider.notifier).state = cid,
              // borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      // Image
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          color: backgroundColor,
                        ),
                        child: CachedNetworkImage(
                          alignment: Alignment.bottomCenter,
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceVariant,
                            child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary))),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.errorContainer,
                            child: Center(child: Icon(Icons.broken_image_outlined, size: 48, color: colorScheme.onErrorContainer)),
                          ),
                        ),
                      ),

                      // Selection badge
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Icon(Icons.check, size: 30, color: colorScheme.onPrimary),
                          ),
                        ),
                    ],
                  ),

                  // CID info
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      cid,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontFamily: 'Monospace'),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Selection overlay
            if (ref.read(selectedCidProvider) != null && !isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: overlayColor,
                    // borderRadius: BorderRadius.vertical(top: Radius.circular(0), bottom: Radius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GalleryActionButtonRow extends ConsumerWidget {
  const GalleryActionButtonRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCid = ref.watch(selectedCidProvider);
    final hasSelection = selectedCid != null;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme ? Colors.black.withAlpha(133) : Colors.white.withAlpha(133);

    return Container(
      height: 80, // Fixed height
      color: backgroundColor, // Theme-aware background color
      child: hasSelection
          ? AnimatedGrowFadeIn(
              show: hasSelection,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => ref.read(selectedCidProvider.notifier).state = null,
                        child: const Text('RESET'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[900],
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _shareImage(selectedCid!),
                        child: const Text('SHARE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _reuseImage(context, ref, selectedCid!),
                        child: const Text('CHOOSE'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : AnimatedGrowFadeIn(
              show: !hasSelection,
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => _createNewIpfsPin(context),
                        child: const Text('CREATE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _createNewIpfsPin(BuildContext context) {
    Navigator.pop(context);
    IpfsPinClaimScreen.show(context);
  }

  void _shareImage(String selectedCid) {
    final shareUrl = '${IpfsConfig.preferredNode}$selectedCid';
    SharePlus.instance.share(ShareParams(title: "IPFS", uri: Uri.parse(shareUrl)));
  }

  void _reuseImage(context, ref, String selectedCid) {
    ref.read(urlInputVerificationProvider.notifier).reset(ref);
    ref.read(ipfsCidProvider.notifier).state = selectedCid;
    Navigator.pop(context);
  }
}
