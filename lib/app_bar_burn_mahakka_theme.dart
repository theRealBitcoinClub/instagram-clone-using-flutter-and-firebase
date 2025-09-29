import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/external_browser_launcher.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';

import 'intros/intro_animated_icon.dart';
import 'intros/intro_enums.dart';
import 'intros/intro_state_notifier.dart';

class AppBarBurnMahakkaTheme extends ConsumerWidget implements PreferredSizeWidget {
  const AppBarBurnMahakkaTheme({super.key});
  static const double height = 40;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThemeState = ref.watch(themeNotifierProvider);
    final ThemeState currentThemeState = asyncThemeState.maybeWhen(data: (data) => data, orElse: () => defaultThemeState);
    final ThemeData theme = currentThemeState.currentTheme;

    return AppBar(
      centerTitle: true,
      toolbarHeight: height,
      leading: Padding(padding: EdgeInsetsGeometry.fromLTRB(9, 0, 0, 0), child: BurnerBalanceWidget()),
      leadingWidth: 81,
      title: Row(
        children: [
          const Spacer(),
          GestureDetector(
            onTap: () => ExternalBrowserLauncher().launchUrlWithConfirmation(context, 'https://mahakka.com'),
            child: Text(
              "mahakka.com",
              style: theme.appBarTheme.titleTextStyle!.copyWith(
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary.withAlpha(222),
              ),
            ),
          ),
        ],
      ),
      actions: [buildThemeIcon(currentThemeState, ref, context)],
    );
  }

  static Widget buildThemeIcon(ThemeState themeState, WidgetRef ref, BuildContext context) {
    return IntroAnimatedIcon(
      icon: themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      introType: IntroType.mainApp,
      introStep: IntroStep.main_theme,
      size: 24,
      padding: const EdgeInsets.fromLTRB(0, 0, 9, 0),
      onTap: () {
        ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.main_theme, context);
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
    );
  }
}
