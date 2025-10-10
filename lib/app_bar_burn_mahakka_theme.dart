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

class AppBarBurnMahakkaTheme extends ConsumerWidget implements PreferredSizeWidget {
  const AppBarBurnMahakkaTheme({super.key});
  static const double height = 40;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final asyncThemeState = ref.watch(themeNotifierProvider);
    // final ThemeState currentThemeState = asyncThemeState.maybeWhen(data: (data) => data, orElse: () => defaultThemeState);
    // final ThemeData theme = currentThemeState.currentTheme;
    ThemeData theme = Theme.of(context);
    String currentLang = ref.watch(languageCodeProvider);
    MahakkaLanguage lang = MahakkaLanguage.getLanguageByCode(currentLang)!;

    return AppBar(
      centerTitle: true,
      toolbarHeight: height,
      leading: BurnerBalanceWidget(),
      leadingWidth: 153,
      actions: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              selectLanguageCode(ref, context);
            },
            borderRadius: BorderRadius.circular(18.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 9.0),
              child: Text(
                "${lang.flag}  ${lang.name}",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w400),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        buildThemeIcon(ref, context),
      ],
    );
  }

  Future<void> selectLanguageCode(WidgetRef ref, BuildContext context) async {
    final selectedLangCode = await LanguageSelectorWidget.showLanguageSelector(context: context);
    if (selectedLangCode != null) {
      final success = await setUserLanguage(ref, selectedLangCode);
      MahakkaLanguage selectedLang = MahakkaLanguage.getLanguageByCode(selectedLangCode)!;
      if (success) {
        ref
            .read(snackbarServiceProvider)
            .showPartiallyTranslatedSnackBar(translateable: "Language changed to ", fixedAfter: selectedLang.name, type: SnackbarType.success);
      } else {
        ref.read(snackbarServiceProvider).showTranslatedSnackBar("Failed to save language :(", type: SnackbarType.error);
      }
    }
  }

  static Widget buildThemeIcon(WidgetRef ref, BuildContext context) {
    var icon = Icon(size: 24, ref.watch(isDarkModeProvider) ? Icons.light_mode_outlined : Icons.dark_mode_outlined);
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
