// home.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/add_screen.dart';
import 'package:mahakka/screens/feed_screen.dart';
import 'package:mahakka/screens/profile_screen_widget.dart';
import 'package:mahakka/tab_item_data.dart';

import '../memo/memo_webview_screen.dart';
import '../provider/navigation_providers.dart';
import '../provider/scraper_provider.dart';
import 'add/add_post_providers.dart';

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
    ref.read(tabIndexProvider.notifier).setTab(index);
    if (index != AppTab.add.tabIndex) {
      ref.read(imgurUrlProvider.notifier).state = '';
      ref.read(youtubeVideoIdProvider.notifier).state = '';
      ref.read(ipfsCidProvider.notifier).state = '';
      ref.read(odyseeUrlProvider.notifier).state = '';
    }
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

    List<BottomNavigationBarItem> _buildBottomNavItems() {
      return AppTab.values.where((tabData) => tabData.isVisibleOnBar).map((tabData) {
        final isSelected = AppTab.values.indexOf(tabData) == currentTabIndex;

        var barIcon = Icon(
          isSelected ? tabData.active : tabData.icon,
          color: isSelected ? theme.primaryColor : theme.primaryColor.withAlpha(222),
        );
        return BottomNavigationBarItem(tooltip: tabData.label, activeIcon: barIcon, icon: barIcon, label: "");
      }).toList();
    }

    return Scaffold(
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
        height: 70,
        backgroundColor:
            theme.bottomNavigationBarTheme.backgroundColor ??
            (theme.brightness == Brightness.light ? theme.colorScheme.surface : Colors.grey[900]),
        activeColor: cupertinoActiveColor,
        inactiveColor: cupertinoInactiveColor,
        currentIndex: currentTabIndex == AppTab.memo.tabIndex ? 2 : currentTabIndex,
        onTap: (index) => _moveToTab(index),
        iconSize: 32.0,
        border: Border(),
        items: _buildBottomNavItems(),
      ),
    );
  }
}
