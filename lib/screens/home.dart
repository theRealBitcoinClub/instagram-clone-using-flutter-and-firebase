// home.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/intros/intro_enums.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/provider/profile_providers.dart';
import 'package:mahakka/screens/add_screen.dart';
import 'package:mahakka/screens/feed_screen.dart';
import 'package:mahakka/screens/profile_screen_widget.dart';
import 'package:mahakka/tab_item_data.dart';

import '../intros/intro_animated_icon.dart';
import '../memo/memo_webview_screen.dart';
import '../provider/navigation_providers.dart';
import '../provider/scraper_provider.dart';

class HomeSceen extends ConsumerStatefulWidget {
  const HomeSceen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeSceen> createState() => _HomeSceenState();
}

class _HomeSceenState extends ConsumerState<HomeSceen> with TickerProviderStateMixin {
  late TabController _tabController;

  late AnimationController _animationController;

  void initState() {
    super.initState();
    final initialIndex = ref.read(tabIndexProvider);

    _tabController = TabController(length: AppTab.totalTabs, vsync: this, initialIndex: initialIndex);
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _animationController.forward(from: 0.0);
    _tabController.addListener(_tabControllerListener);
    ref.read(backgroundScraperManagerProvider);
  }

  void _tabControllerListener() {
    if (_tabController.indexIsChanging || _tabController.index != ref.read(tabIndexProvider)) {
      if (_tabController.index != ref.read(tabIndexProvider)) {
        ref.read(tabIndexProvider.notifier).setTab(_tabController.index);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_tabControllerListener);
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // home.dart (updated _moveToTab method)
  void _moveToTab(int index) {
    final tabData = AppTab.values[index];

    if (tabData == AppTab.add) {
      ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.main_create, context);
    } else if (tabData == AppTab.profile) {
      ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.main_profile, context);
    }

    if (index != AppTab.profile.tabIndex) {
      ref.read(profileDataProvider.notifier).stopAutoRefreshBalanceProfile();
    }

    ref.read(tabIndexProvider.notifier).setTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(tabIndexProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color cupertinoActiveColor = colorScheme.primary;
    final Color cupertinoInactiveColor = colorScheme.onSurface.withOpacity(0.6);

    final List<Widget> homeScreenItems = [
      FeedScreen(key: PageStorageKey('FeedScreen')),
      AddPost(key: PageStorageKey('AddPost')),
      ProfileScreenWidget(key: PageStorageKey('ProfileScreen')),
      MemoWebviewScreen(key: PageStorageKey('MemoWebviewScreen')), // Added webview tab
    ];

    ref.listen<int>(tabIndexProvider, (previous, next) {
      if (previous != next) {
        _animationController.forward(from: 0.0);
      }
    });

    List<BottomNavigationBarItem> buildBottomNavItems() {
      return AppTab.values.where((tabData) => tabData.isVisibleOnBar).map((tabData) {
        final isSelected = AppTab.values.indexOf(tabData) == currentTabIndex;

        // Determine which intro step corresponds to this tab
        IntroStep? introStep;
        if (tabData == AppTab.add) {
          introStep = IntroStep.main_create;
        } else if (tabData == AppTab.profile) {
          introStep = IntroStep.main_profile;
        }

        Widget barIcon;

        if (introStep != null) {
          // Use animated icon for tabs that have intro steps
          barIcon = Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0), // (70 - 32) / 2 = 19px padding
            child: IntroAnimatedIcon(
              icon: isSelected ? tabData.active : tabData.icon,
              introType: IntroType.mainApp,
              introStep: introStep,
              color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
              size: 34,
              // padding: const EdgeInsets.all(6.0),
              onTap: () => _moveToTab(AppTab.values.indexOf(tabData)),
            ),
          );
        } else {
          // Regular icon for other tabs
          barIcon = Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0), // (70 - 32) / 2 = 19px padding
            child: GestureDetector(
              onTap: () => _moveToTab(AppTab.values.indexOf(tabData)),
              child: Icon(
                isSelected ? tabData.active : tabData.icon,
                color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
                size: 34,
              ),
            ),
          );
        }

        return BottomNavigationBarItem(tooltip: tabData.label, activeIcon: barIcon, icon: barIcon, label: "");
      }).toList();
    }

    DateTime? _currentBackPressTime;

    Future<bool> _onWillPop() async {
      final currentTabIndex = ref.read(tabIndexProvider);

      // If not on feed screen (tab 0), navigate to feed
      if (currentTabIndex != 0) {
        _moveToTab(0);
        return false;
      }

      // If on feed screen, use double-tap to exit
      DateTime now = DateTime.now();
      if (_currentBackPressTime == null || now.difference(_currentBackPressTime!) > Duration(seconds: 1)) {
        _currentBackPressTime = now;
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Press back again to exit app'), duration: Duration(seconds: 2)));
        return false;
      }

      return true; // Exit app
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: List.generate(homeScreenItems.length, (index) {
            return Offstage(
              offstage: index != currentTabIndex,
              child: TickerMode(
                enabled: index == currentTabIndex,
                child: FadeTransition(opacity: _animationController, child: homeScreenItems[index]),
              ),
            );
          }),
        ),
        bottomNavigationBar: CupertinoTabBar(
          height: 50,
          backgroundColor:
              theme.bottomNavigationBarTheme.backgroundColor ??
              (theme.brightness == Brightness.light ? theme.colorScheme.surface : Colors.grey[900]),
          activeColor: cupertinoActiveColor,
          inactiveColor: cupertinoInactiveColor,
          currentIndex: currentTabIndex == AppTab.memo.tabIndex ? 2 : currentTabIndex,
          onTap: (index) => _moveToTab(index),
          iconSize: 32.0,
          border: Border(),
          items: buildBottomNavItems(),
        ),
      ),
    );
  }
}
