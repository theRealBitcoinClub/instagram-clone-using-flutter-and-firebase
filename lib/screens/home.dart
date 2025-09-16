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
            theme.bottomNavigationBarTheme.backgroundColor ?? (theme.brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]),
        activeColor: cupertinoActiveColor,
        inactiveColor: cupertinoInactiveColor,
        currentIndex: currentTabIndex,
        onTap: (index) => ref.read(tabIndexProvider.notifier).setTab(index),
        iconSize: 30.0,
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
        items: AppTab.values.map((tabData) {
          //TODO this could be improved so that switching the AppTab index means also reordering the controller tabs
          bool isSelected = AppTab.values.indexOf(tabData) == currentTabIndex;
          return BottomNavigationBarItem(icon: Icon(isSelected ? tabData.active : tabData.icon));
        }).toList(),
      ),
    );
  }
}
