import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/add/language_selector_widget.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';

import 'intros/intro_enums.dart';
import 'intros/wrapped_animated_intro_target.dart';
import 'main.dart';

// final languageCodeProvider = StateProvider<String?>((ref) => SystemLanguage.getLanguageCode());

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
    String currentLang = ref.watch(languageCodeProvider);
    MahakkaLanguage lang = MahakkaLanguage.getLanguageByCode(currentLang)!;

    return AppBar(
      centerTitle: true,
      toolbarHeight: height,
      leading: Padding(padding: EdgeInsetsGeometry.fromLTRB(9, 0, 0, 0), child: BurnerBalanceWidget()),
      leadingWidth: 99,
      // title: Row(
      //   children: [
      //     const Spacer(),
      //     GestureDetector(
      //       onTap: () => ExternalBrowserLauncher().launchUrlWithConfirmation(context, 'https://mahakka.com'),
      //       child: Text(
      //         "mahakka.com",
      //         style: theme.textTheme.titleMedium!.copyWith(
      //           letterSpacing: 1,
      //           fontWeight: FontWeight.bold,
      //           color: theme.colorScheme.onPrimary.withAlpha(222),
      //         ),
      //       ),
      //     ),
      //   ],
      // ),
      actions: [
        // IconButton(
        //   onPressed: () {
        //     selectLanguageCode(ref, context);
        //   },
        //   icon: Icon(Icons.language_outlined),
        // ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: GestureDetector(
            onTap: () {
              selectLanguageCode(ref, context);
            },
            child: Text(
              "${lang.flag}  ${lang.name}",
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w400),
            ),
          ),
        ),
        const SizedBox(width: 6),
        buildThemeIcon(currentThemeState, ref, context),
      ],
    );
  }

  Future<void> selectLanguageCode(WidgetRef ref, BuildContext context) async {
    final selectedLangCode = await LanguageSelectorWidget.showLanguageSelector(context: context);
    if (selectedLangCode != null) {
      final success = await setUserLanguage(ref, selectedLangCode);
      MahakkaLanguage selectedLang = MahakkaLanguage.getLanguageByCode(selectedLangCode)!;
      if (success) {
        showSnackBar("Language changed to ${selectedLang.name}", type: SnackbarType.success);
      } else {
        showSnackBar("Failed to save language :(", type: SnackbarType.error);
      }
    }
  }

  // Future<void> selectLanguageCode(WidgetRef ref, BuildContext context) async {
  //   final selectedLangCode = await LanguageSelectorWidget.showLanguageSelector(context: context);
  //   if (selectedLangCode != null) {
  //     ref.read(languageCodeProvider.notifier).state = selectedLangCode;
  //   }
  // }

  static Widget buildThemeIcon(ThemeState themeState, WidgetRef ref, BuildContext context) {
    var icon = Icon(size: 24, themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined);
    if (ref.read(currentTabIndexProvider) == AppTab.profile.tabIndex)
      return WrappedAnimatedIntroTarget(
        doNotAnimate: false,
        introType: IntroType.mainApp,
        introStep: IntroStep.mainTheme,
        onTap: () {
          // ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainTheme, context);
          ref.read(themeNotifierProvider.notifier).toggleTheme();
        },
        child: icon,
      );
    // return IconButton(padding: EdgeInsets.zero, onPressed: () => ref.read(themeNotifierProvider.notifier).toggleTheme(), icon: icon);

    return WrappedAnimatedIntroTarget(
      introType: IntroType.mainApp,
      introStep: IntroStep.mainTheme,
      onTap: () {
        // ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainTheme, context);
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
      child: icon,
    );
    // return IntroAnimatedIcon(
    //   icon: themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
    //   introType: IntroType.mainApp,
    //   introStep: IntroStep.mainTheme,
    //   size: 24,
    //   padding: const EdgeInsets.fromLTRB(0, 0, 9, 0),
    //   onTap: () {
    //     ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainTheme, context);
    //     ref.read(themeNotifierProvider.notifier).toggleTheme();
    //   },
    // );
  }
}
