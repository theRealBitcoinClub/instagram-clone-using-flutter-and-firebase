import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/providers/scroll_controller_provider.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/add/language_selector_widget.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'intros/intro_enums.dart';
import 'intros/wrapped_animated_intro_target.dart';
import 'main.dart';

class AppBarBurnMahakkaTheme extends ConsumerWidget implements PreferredSizeWidget {
  const AppBarBurnMahakkaTheme(this.showTitle, {super.key});
  static const double height = 40;
  final showTitle;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ThemeData theme = Theme.of(context);
    String currentLang = ref.watch(languageCodeProvider);
    MahakkaLanguage lang = MahakkaLanguage.getLanguageByCode(currentLang)!;

    return AppBar(
      toolbarHeight: height,
      leading: BurnerBalanceWidget(),
      leadingWidth: 153,
      // Remove centerTitle and use flexibleSpace for true centering
      flexibleSpace: SafeArea(
        child: Row(
          children: [
            SizedBox(width: 153), // Match leadingWidth
            Expanded(
              child: showTitle
                  ? Center(
                      child: IconButton(
                        onPressed: ref.read(feedScrollControllerProvider.notifier).resetScroll,
                        icon: Icon(Icons.arrow_drop_up_outlined, color: theme.colorScheme.onPrimary),
                      ),
                    )
                  : const SizedBox(),
            ),
            SizedBox(
              width: 153, // Approximate width for actions area
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                  buildThemeIcon(ref, context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
      title: null, // Remove title since we're using flexibleSpace
      actions: [], // Remove actions since they're in flexibleSpace
    );
    //   AppBar(
    //   centerTitle: true,
    //   toolbarHeight: height,
    //   leading: BurnerBalanceWidget(),
    //   leadingWidth: 153,
    //   title: showTitle
    //       ? IconButton(
    //           onPressed: ref.read(feedScrollControllerProvider.notifier).resetScroll,
    //           icon: Icon(Icons.arrow_circle_up_outlined, color: theme.colorScheme.onPrimary.withAlpha(111)),
    //         )
    //       : null,
    //   actions: [
    //     Material(
    //       color: Colors.transparent,
    //       child: InkWell(
    //         onTap: () {
    //           selectLanguageCode(ref, context);
    //         },
    //         borderRadius: BorderRadius.circular(18.0),
    //         child: Padding(
    //           padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 9.0),
    //           child: Text(
    //             "${lang.flag}  ${lang.name}",
    //             style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w400),
    //           ),
    //         ),
    //       ),
    //     ),
    //     const SizedBox(width: 6),
    //     buildThemeIcon(ref, context),
    //   ],
    // );
  }

  Future<void> selectLanguageCode(WidgetRef ref, BuildContext context) async {
    final selectedLangCode = await LanguageSelectorWidget.showLanguageSelector(context: context);

    try {
      Sentry.addBreadcrumb(
        Breadcrumb.userInteraction(data: {"selectedLangCode:": selectedLangCode}, message: selectedLangCode, subCategory: "languageselector"),
      );
    } catch (e) {}

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

  static Widget buildThemeIcon(WidgetRef ref, BuildContext context, theme) {
    var icon = Icon(
      size: 24,
      ref.watch(isDarkModeProvider) ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      color: theme.colorScheme.onPrimary,
    );
    if (ref.read(currentTabIndexProvider) == AppTab.profile.tabIndex) {
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
    }
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
