// home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/intros/intro_enums.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/provider/profile_balance_provider.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/screens/add_screen.dart';
import 'package:mahakka/screens/feed_screen.dart';
import 'package:mahakka/screens/profile_screen_widget.dart';
import 'package:mahakka/tab_item_data.dart';

import '../intros/intro_animated_icon.dart';
import '../memo/memo_webview_screen.dart';
import '../provider/scraper_provider.dart';

class HomeSceen extends ConsumerStatefulWidget {
  const HomeSceen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeSceen> createState() => _HomeSceenState();
}

class _HomeSceenState extends ConsumerState<HomeSceen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _indicatorAnimCtrl;

  int _currentTabIndex = 0;
  int _previousTabIndex = 0;
  static const animDuration = 250;
  static const duration = Duration(milliseconds: animDuration);

  void initState() {
    super.initState();
    final initialIndex = ref.read(currentTabIndexProvider);
    _currentTabIndex = initialIndex;
    _previousTabIndex = initialIndex;

    _tabController = TabController(length: AppTab.totalTabs, vsync: this, initialIndex: initialIndex);
    _animationController = AnimationController(vsync: this, duration: duration);
    _indicatorAnimCtrl = AnimationController(vsync: this, duration: duration);

    _animationController.forward(from: 0.0);
    // _tabController.addListener(_tabControllerListener);
    ref.read(backgroundScraperManagerProvider);
  }

  // void _tabControllerListener() {
  //   if (_tabController.indexIsChanging || _tabController.index != ref.read(currentTabIndexProvider)) {
  //     if (_tabController.index != ref.read(currentTabIndexProvider)) {
  //       // ref.read(navigationStateProvider.notifier).setTab(_tabController.index);
  //       // ref.read(currentTabIndexProvider.notifier).setTab(_tabController.index);
  //     }
  //   }
  // }

  void _animateIndicatorToTab(int targetIndex) {
    final int startIndex = _currentTabIndex;
    final int endIndex = targetIndex;
    final int tabDifference = (endIndex - startIndex).abs();
    final Duration animationDuration = Duration(milliseconds: tabDifference * animDuration);
    _previousTabIndex = _currentTabIndex;
    setState(() {
      _currentTabIndex = targetIndex;
    });

    _indicatorAnimCtrl.duration = animationDuration;
    _indicatorAnimCtrl.stop();
    _indicatorAnimCtrl.value = 0.0;
    _indicatorAnimCtrl.forward();
  }

  @override
  void dispose() {
    // _tabController.removeListener(_tabControllerListener);
    _tabController.dispose();
    _animationController.dispose();
    _indicatorAnimCtrl.dispose();
    super.dispose();
  }

  void _moveToTab(int index) {
    final tabData = AppTab.values[index];

    if (index != AppTab.profile.tabIndex) {
      ref.read(profileBalanceProvider).stopAutoRefreshBalanceProfile();
    } else {
      ref.read(profileBalanceProvider).startAutoRefreshBalanceProfile();
    }

    if (tabData == AppTab.add) {
      ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainCreate, context);
      ref.read(navigationStateProvider.notifier).navigateToAddPost();
    } else if (tabData == AppTab.profile) {
      ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainProfile, context);
      ref.read(navigationStateProvider.notifier).navigateToOwnProfile();
    } else {
      ref.read(navigationStateProvider.notifier).navigateToFeed();
    }

    // ref.read(navigationStateProvider.notifier).setTab(index);
    _animateIndicatorToTab(index);
  }

  // void _moveToTab(int index) {
  //   final tabData = AppTab.values[index];
  //
  //   if (tabData == AppTab.add) {
  //     ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainCreate, context);
  //   } else if (tabData == AppTab.profile) {
  //     ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainProfile, context);
  //   }
  //
  //   if (index != AppTab.profile.tabIndex) {
  //     ref.read(profileDataProvider.notifier).stopAutoRefreshBalanceProfile();
  //     ref.read(profileTargetIdProvider.notifier).state = null;
  //   }
  //
  //   ref.read(tabIndexProvider.notifier).setTab(index);
  //   _animateIndicatorToTab(index);
  // }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(currentTabIndexProvider); // Watch the Riverpod state
    final ThemeData theme = Theme.of(context);

    // Sync local state with Riverpod state when it changes externally
    if (currentTabIndex != _currentTabIndex && !_indicatorAnimCtrl.isAnimating) {
      _animateIndicatorToTab(currentTabIndex);
    }

    // Get only visible tabs for the bottom navigation bar
    final visibleTabs = AppTab.values.where((tabData) => tabData.isVisibleOnBar).toList();
    final tabCount = visibleTabs.length;

    // Create mapping from actual AppTab index to visible position
    final actualIndexToVisiblePosition = <int, int>{};
    for (int i = 0; i < visibleTabs.length; i++) {
      actualIndexToVisiblePosition[visibleTabs[i].tabIndex] = i;
    }

    final List<Widget> homeScreenItems = [
      FeedScreen(key: PageStorageKey('FeedScreen')),
      AddPost(key: PageStorageKey('AddPost')),
      ProfileScreenWidget(key: PageStorageKey('ProfileScreen')),
      MemoWebviewScreen(key: PageStorageKey('MemoWebviewScreen')),
    ];

    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      if (previous != next) {
        _animationController.forward(from: 0.0);
      }
    });

    DateTime? _currentBackPressTime;

    Future<bool> _onWillPop() async {
      final currentTabIndex = ref.read(currentTabIndexProvider);

      if (currentTabIndex != 0) {
        // ref.read(navigationStateProvider.notifier).navigateBackToFeed();
        _moveToTab(0);
        return false;
      }

      DateTime now = DateTime.now();
      if (_currentBackPressTime == null || now.difference(_currentBackPressTime!) > Duration(seconds: 1)) {
        _currentBackPressTime = now;
        return false;
      }

      return true;
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: List.generate(homeScreenItems.length, (index) {
            return Offstage(
              offstage: index != _currentTabIndex, // Use local state for display
              child: TickerMode(
                enabled: index == _currentTabIndex,
                child: FadeTransition(opacity: _animationController, child: homeScreenItems[index]),
              ),
            );
          }),
        ),
        bottomNavigationBar: Container(
          height: 60,
          decoration: BoxDecoration(
            color:
                theme.bottomNavigationBarTheme.backgroundColor ??
                (theme.brightness == Brightness.light ? theme.colorScheme.surface : Colors.grey[900]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8.0, offset: Offset(0, -2))],
          ),
          child: Stack(
            children: [
              // Animated indicator
              AnimatedBuilder(
                animation: _indicatorAnimCtrl,
                builder: (context, child) {
                  if (_currentTabIndex == AppTab.memo.tabIndex) {
                    return SizedBox.shrink();
                  }
                  final screenWidth = MediaQuery.of(context).size.width;
                  final tabWidth = screenWidth / tabCount;

                  double visiblePosition;
                  if (_previousTabIndex == AppTab.memo.tabIndex) {
                    visiblePosition = _currentTabIndex.toDouble();
                  } else {
                    visiblePosition = _previousTabIndex + (_currentTabIndex - _previousTabIndex) * _indicatorAnimCtrl.value;
                  }

                  return Positioned(
                    top: 0,
                    left: visiblePosition * tabWidth,
                    child: Container(
                      width: tabWidth,
                      height: 3,
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  );
                },
              ),

              Row(
                children: visibleTabs.asMap().entries.map((entry) {
                  final tabData = entry.value;
                  final actualIndex = tabData.tabIndex;
                  final isSelected = actualIndex == _currentTabIndex; // Use local state

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _moveToTab(actualIndex),
                        splashColor: theme.primaryColor.withOpacity(0.2),
                        highlightColor: theme.primaryColor.withOpacity(0.1),
                        child: Container(height: 60, child: Center(child: _buildTabIcon(tabData, isSelected, actualIndex))),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build tab icon
  Widget _buildTabIcon(AppTab tabData, bool isSelected, int tabIndex) {
    final ThemeData theme = Theme.of(context);
    IntroStep? introStep;

    if (tabData == AppTab.add) {
      introStep = IntroStep.mainCreate;
    } else if (tabData == AppTab.profile) {
      introStep = IntroStep.mainProfile;
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
