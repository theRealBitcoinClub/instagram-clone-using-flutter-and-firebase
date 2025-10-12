// home.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/intros/intro_enums.dart';
import 'package:mahakka/intros/intro_state_notifier.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/screens/add_screen.dart';
import 'package:mahakka/screens/feed_screen.dart';
import 'package:mahakka/screens/profile_screen_widget.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../intros/intro_animated_icon.dart';
import '../ipfs/ipfs_pin_claim_service.dart';
import '../memo/memo_webview_screen.dart';
import '../provider/electrum_provider.dart';
import '../provider/scraper_provider.dart';
import '../providers/scroll_controller_provider.dart';
import '../providers/token_limits_provider.dart';

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

    context.afterBuildAsync(refreshUI: false, () async {
      final bitcoinBase = await ref.read(electrumServiceProvider.future);
      final ipfsService = IpfsPinClaimService(bitcoinBase: bitcoinBase, serverUrl: 'https://file-stage.fullstack.cash');
      ipfsService.executeFakeApiRequestForWakeUp();
    });
  }

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
    _tabController.dispose();
    _animationController.dispose();
    _indicatorAnimCtrl.dispose();
    super.dispose();
  }

  int _lastIndex = -1;

  void _moveToTab(int index) {
    if (_lastIndex != index) {
      context.afterLayout(refreshUI: true, () {
        ref.read(feedScrollControllerProvider.notifier).resetScroll();
      });
      _lastIndex = index;
    } else
      print("SAME TAB");
    final tabData = AppTab.values[index];
    if (tabData == AppTab.add) {
      ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainCreate, context);
      ref.read(navigationStateProvider.notifier).navigateToAddPost();
    } else if (tabData == AppTab.profile) {
      ref.read(introStateNotifierProvider.notifier).triggerIntroAction(IntroType.mainApp, IntroStep.mainProfile, context);
      ref.read(navigationStateProvider.notifier).navigateToOwnProfile();
    } else {
      ref.read(navigationStateProvider.notifier).navigateToFeed();
    }

    _animateIndicatorToTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(currentTabIndexProvider); // Watch the Riverpod state
    final ThemeData theme = Theme.of(context);
    var tokenLimit = ref.watch(currentTokenLimitEnumProvider);
    // ref.watch(profileBalanceProvider);
    // ref.read(profileBalanceProvider).startAutoRefreshBalanceProfile();

    ref.listen<AsyncValue<TokenLimitsState>>(tokenLimitsProvider, (previous, current) {
      // Perform side effects when token limits change
      if (current.hasValue && previous?.value?.currentLimit != current.value?.currentLimit) {
        ref
            .read(snackbarServiceProvider)
            .showTranslatedSnackBar('Level changed to: ${current.value?.currentLimit.name}', type: SnackbarType.success);
      }
    });

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
      FeedScreen(key: PageStorageKey('FeedScreen${tokenLimit.name}')),
      AddPost(key: PageStorageKey('AddPost')),
      ProfileScreenWidget(key: PageStorageKey('ProfileScreen${tokenLimit.name}')),
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
        bottomNavigationBar: SafeArea(child: buildBottomNavBar(theme, tabCount, visibleTabs)),
      ),
    );
  }

  Container buildBottomNavBar(ThemeData theme, int tabCount, List<AppTab> visibleTabs) {
    return Container(
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
          buildAnimatedTabIndicator(tabCount, theme),

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
                    child: Container(
                      height: 60,
                      child: Center(
                        child: Padding(padding: EdgeInsets.only(bottom: 3), child: _buildTabIcon(tabData, isSelected, actualIndex)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  AnimatedBuilder buildAnimatedTabIndicator(int tabCount, ThemeData theme) {
    return AnimatedBuilder(
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
          top: 54,
          left: visiblePosition * tabWidth,
          child: Container(
            width: tabWidth,
            height: 6,
            decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(3)),
          ),
        );
      },
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
