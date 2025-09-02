import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/navigation_providers.dart'; // Import for profileTargetIdProvider
import 'package:url_launcher/url_launcher.dart';

import '../../provider/profile_providers.dart';

class ProfileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  // Changed to ConsumerWidget
  final MemoModelCreator? creator;
  final bool isOwnProfile;
  final VoidCallback onShowBchQrDialog;

  const ProfileAppBar({Key? key, required this.creator, required this.isOwnProfile, required this.onShowBchQrDialog}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AppBar(
      toolbarHeight: 40,
      centerTitle: false,
      titleSpacing: NavigationToolbar.kMiddleSpacing,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          ref.read(profileTargetIdProvider.notifier).state = null;
          ref.read(tabIndexProvider.notifier).setTab(0);
        },
      ),
      title: creator?.id != null && creator!.id.isNotEmpty
          ? TextButton(
              onPressed: () {
                if (creator?.id != null && creator!.id.isNotEmpty) {
                  // Redundant check, but safe
                  launchUrl(Uri.parse("https://memo.cash/profile/${creator!.id}"));
                }
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              child: Text(
                creator!.id,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: (theme.appBarTheme.titleTextStyle?.color ?? colorScheme.onSurface).withOpacity(0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          : Text(
              isOwnProfile ? "My Profile" : "Profile",
              style:
                  theme.appBarTheme.titleTextStyle?.copyWith(
                    fontSize: theme.textTheme.bodySmall?.fontSize,
                    color: (theme.appBarTheme.titleTextStyle?.color ?? colorScheme.onSurface).withOpacity(0.7),
                  ) ??
                  theme.textTheme.bodySmall?.copyWith(color: (theme.textTheme.bodySmall?.color ?? colorScheme.onSurface).withOpacity(0.7)),
            ),
      actions: [
        if (isOwnProfile)
          IconButton(icon: const Icon(Icons.qr_code_scanner_rounded), tooltip: "Show Deposit QR", onPressed: onShowBchQrDialog)
        else // Show "Home/My Profile" button if not own profile
          IconButton(
            icon: const Icon(Icons.home_filled), // Or Icons.person_outline for "My Profile"
            tooltip: "View My Profile",
            onPressed: () {
              ref.read(profileTargetIdProvider.notifier).state = null;
              ref.refresh(creatorStateProvider);
              ref.refresh(postsStreamProvider);
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(40);
}
