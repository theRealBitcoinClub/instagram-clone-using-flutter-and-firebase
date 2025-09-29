// lib/widgets/profile/profile_app_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/providers/webview_providers.dart';

import '../../provider/profile_providers.dart';
import '../../theme_provider.dart';

class ProfileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final MemoModelCreator? creator;
  final bool isOwnProfile;
  final VoidCallback onShowBchQrDialog;
  final ScrollController scrollController;

  const ProfileAppBar({
    Key? key,
    required this.creator,
    required this.isOwnProfile,
    required this.onShowBchQrDialog,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeState = ref.watch(themeStateProvider);
    final ThemeData theme = currentThemeState.currentTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    return AppBar(
      toolbarHeight: AppBarBurnMahakkaTheme.height,
      elevation: 4,
      centerTitle: false,
      titleSpacing: NavigationToolbar.kMiddleSpacing,
      leading: isOwnProfile
          ? IconButton(icon: const Icon(Icons.qr_code_scanner_rounded), tooltip: "Show Deposit QR", onPressed: onShowBchQrDialog)
          : IconButton(
              icon: const Icon(Icons.home_filled),
              tooltip: "View My Profile",
              onPressed: () {
                ref.read(profileTargetIdProvider.notifier).state = null;
                context.afterBuild(refreshUI: true, () {
                  ref.invalidate(profileDataProvider); // Invalidate first
                  ref.refresh(profileDataProvider); // Then refresh
                });
              },
            ),
      title: creator?.id != null && creator!.id.isNotEmpty
          ? TextButton(
              onPressed: () {
                if (creator?.id != null && creator!.id.isNotEmpty) {
                  WebViewNavigator.navigateTo(ref, WebViewShow.url, "https://memo.cash/profile/${creator!.id}");
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
      actions: [AppBarBurnMahakkaTheme.buildThemeIcon(currentThemeState, ref, context)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppBarBurnMahakkaTheme.height);
}
