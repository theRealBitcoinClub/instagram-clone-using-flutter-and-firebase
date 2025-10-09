import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/provider/url_input_verification_notifier.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/screens/ipfs_pin_claim_screen.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/widgets/unified_image_widget.dart';
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
    var themeData = Theme.of(context);
    final TextTheme textTheme = themeData.textTheme;
    final backgroundColor = ref.watch(isDarkModeProvider) ? Colors.black.withAlpha(133) : Colors.white.withAlpha(133);
    final validCids = ipfsCids.reversed.where((cid) => cid.isNotEmpty).toList();
    var colorScheme = themeData.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBarBurnMahakkaTheme.height,
        leadingWidth: 50,
        title: Text(
          hasSelection ? '${selectedCid}' : 'Tap image to select or create new one',
          style: textTheme.bodySmall!.copyWith(color: colorScheme.onPrimary),
        ),
        leading: IconButton(icon: const Icon(Icons.cancel_outlined), onPressed: () => Navigator.pop(context)),
        actions: [
          AppBarBurnMahakkaTheme.buildThemeIcon(ref, context),
          if (!hasSelection)
            IconButton(
              icon: Icon(Icons.upload_outlined, color: colorScheme.onPrimary),
              onPressed: () => _createNewIpfsPin(context),
              tooltip: 'Create new IPFS pin',
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
              onPressed: () => ref.read(selectedCidProvider.notifier).state = null,
              tooltip: 'Clear selection',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // IPFS Images ListView
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
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
                        // height: 300,
                        decoration: BoxDecoration(
                          // borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                          color: backgroundColor,
                        ),
                        child: UnifiedImageWidget(
                          imageUrl: cid,
                          sourceType: ImageSourceType.ipfs,
                          fitMode: ImageFitMode.contain,
                          // aspectRatio: 16 / 9,
                          border: Border(),
                          backgroundColor: colorScheme.surface,
                          showLoadingProgress: true,
                          errorWidget: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off_outlined, color: colorScheme.error.withAlpha(153), size: 36),
                              const SizedBox(height: 8),
                              Text("Error loading IPFS content", style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                              const SizedBox(height: 8),
                              Text("$cid", style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurface)),
                            ],
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
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
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
    final cid = ref.watch(selectedCidProvider);
    final hasSelection = cid != null;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkTheme ? Colors.black.withAlpha(133) : Colors.white.withAlpha(133);

    return Container(
      height: 60, // Fixed height
      color: backgroundColor, // Theme-aware background color
      child: hasSelection
          ? AnimGrowFade(
              show: hasSelection,
              // duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  IconAction(text: "RESET", onTap: () => resetSelection(ref), type: IAB.cancel, icon: Icons.refresh),
                  IconAction(text: "LINK", onTap: () => _shareImage(cid), type: IAB.alternative, icon: Icons.link),
                  IconAction(text: "POST", onTap: () => _reuseImage(context, ref, cid), type: IAB.success, icon: Icons.check_circle_outline),
                ],
              ),
            )
          : AnimGrowFade(
              show: !hasSelection,
              // duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  IconAction(text: "CANCEL", onTap: () => Navigator.of(context).pop(), type: IAB.cancel, icon: Icons.cancel_outlined),
                  IconAction(text: "CREATE", onTap: () => _createNewIpfsPin(context), type: IAB.success, icon: Icons.upload_outlined),
                ],
              ),
            ),
    );
  }

  Null resetSelection(WidgetRef ref) => ref.read(selectedCidProvider.notifier).state = null;

  void _createNewIpfsPin(BuildContext context) {
    Navigator.pop(context);
    IpfsPinClaimScreen.show(context);
  }

  void _shareImage(String selectedCid) {
    final shareUrl = '${IpfsConfig.preferredNode}$selectedCid';
    SharePlus.instance.share(ShareParams(title: "IPFS", uri: Uri.parse(shareUrl)));
  }

  void _reuseImage(context, ref, String selectedCid) {
    ref.read(urlInputVerificationProvider.notifier).reset();
    ref.read(ipfsCidProvider.notifier).state = selectedCid;
    Navigator.pop(context);
  }
}
