// home.dart
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

    final List<Widget> homeScreenItems = [
      FeedScreen(key: PageStorageKey('FeedScreen')),
      AddPost(key: PageStorageKey('AddPost')),
      ProfileScreenWidget(key: PageStorageKey('ProfileScreen')),
      MemoWebviewScreen(key: PageStorageKey('MemoWebviewScreen')),
    ];

    ref.listen<int>(tabIndexProvider, (previous, next) {
      if (previous != next) {
        _animationController.forward(from: 0.0);
      }
    });

    // Build bottom navigation items with full-width indicator and no labels
    List<BottomNavigationBarItem> buildBottomNavItems() {
      final visibleTabs = AppTab.values.where((tabData) => tabData.isVisibleOnBar).toList();

      return visibleTabs.map((tabData) {
        final isSelected = AppTab.values.indexOf(tabData) == currentTabIndex;

        // Determine which intro step corresponds to this tab
        IntroStep? introStep;
        if (tabData == AppTab.add) {
          introStep = IntroStep.main_create;
        } else if (tabData == AppTab.profile) {
          introStep = IntroStep.main_profile;
        }

        // Function to create the icon with full-width top border indicator
        Widget buildIconWidget(Widget iconWidget) {
          return Container(
            width: double.infinity, // Take full width of the tab
            height: 60, // Custom height for the entire bar
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Full-width top border indicator (1/3 of the bar width) - positioned at absolute top
                if (isSelected)
                  Positioned(
                    top: 0, // Absolutely at the top
                    child: Container(
                      height: 3,
                      width: MediaQuery.of(context).size.width / visibleTabs.length,
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                // Center the icon vertically
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 3), // Small margin to account for the border
                    child: iconWidget,
                  ),
                ),
              ],
            ),
          );
        }

        Widget iconWidget;

        if (introStep != null) {
          // Use IntroAnimatedIcon for tabs with intro functionality
          iconWidget = IntroAnimatedIcon(
            icon: isSelected ? tabData.active : tabData.icon,
            introType: IntroType.mainApp,
            introStep: introStep,
            color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
            size: 34, // Restored larger icon size
            onTap: () => _moveToTab(AppTab.values.indexOf(tabData)),
          );
        } else {
          // Regular icon with gesture detector for other tabs
          iconWidget = GestureDetector(
            onTap: () => _moveToTab(AppTab.values.indexOf(tabData)),
            child: Icon(
              isSelected ? tabData.active : tabData.icon,
              size: 34, // Restored larger icon size
              color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
            ),
          );
        }

        return BottomNavigationBarItem(
          icon: buildIconWidget(iconWidget),
          label: '', // Empty label to remove text
        );
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
        bottomNavigationBar: Container(
          height: 60, // Exact controlled height
          decoration: BoxDecoration(
            color:
                theme.bottomNavigationBarTheme.backgroundColor ??
                (theme.brightness == Brightness.light ? theme.colorScheme.surface : Colors.grey[900]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8.0, offset: Offset(0, -2))],
          ),
          child: Row(
            children: AppTab.values.where((tabData) => tabData.isVisibleOnBar).map((tabData) {
              final isSelected = AppTab.values.indexOf(tabData) == currentTabIndex;
              final tabIndex = AppTab.values.indexOf(tabData);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _moveToTab(tabIndex),
                  child: Container(
                    height: 60,
                    child: Stack(
                      children: [
                        // Full-width top border indicator
                        if (isSelected)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                        // Centered icon
                        Center(child: _buildTabIcon(tabData, isSelected, tabIndex)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Add this helper method:
  Widget _buildTabIcon(AppTab tabData, bool isSelected, int tabIndex) {
    final ThemeData theme = Theme.of(context);
    IntroStep? introStep;

    if (tabData == AppTab.add) {
      introStep = IntroStep.main_create;
    } else if (tabData == AppTab.profile) {
      introStep = IntroStep.main_profile;
    }

    if (introStep != null) {
      return IntroAnimatedIcon(
        icon: isSelected ? tabData.active : tabData.icon,
        introType: IntroType.mainApp,
        introStep: introStep,
        color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
        size: 34,
        onTap: () => _moveToTab(tabIndex),
      );
    } else {
      return Icon(
        isSelected ? tabData.active : tabData.icon,
        size: 34,
        color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
      );
    }
  }
}
