import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/add_screen.dart'; // Ensure AddPost is themed
import 'package:mahakka/screens/feed_screen.dart'; // Ensure FeedScreen is themed
import 'package:mahakka/screens/profile_screen_widget.dart';
import 'package:mahakka/tab_item_data.dart';

import '../provider/navigation_providers.dart';
import '../provider/scraper_provider.dart';

class HomeSceen extends ConsumerStatefulWidget {
  const HomeSceen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeSceen> createState() => _HomeSceenState();
}

class _HomeSceenState extends ConsumerState<HomeSceen> with TickerProviderStateMixin {
  late TabController _tabController;
  final int _totalTabs = 3; // Keep this for bounds and controller lengths

  late AnimationController _animationController;

  void initState() {
    super.initState();
    final initialIndex = ref.read(tabIndexProvider);

    // Initialize the TabController to sync with the BottomNavigationBar.
    _tabController = TabController(length: _totalTabs, vsync: this, initialIndex: initialIndex);

    // Initialize the AnimationController for the FadeTransition.
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _animationController.forward(from: 0.0); // Trigger the animation for the initial screen.

    // This listener updates the tab index in Riverpod when the user taps on the TabBar.
    _tabController.addListener(_tabControllerListener);

    // This is a one-time read for the background scraper, still correct here.
    ref.read(backgroundScraperManagerProvider);

    // Note: The PageController and its listeners have been removed.
  }

  // A private method to hold the listener logic
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
    _animationController.dispose(); // This is for the fade animation
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(tabIndexProvider);
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color cupertinoActiveColor = colorScheme.primary;
    final Color cupertinoInactiveColor = colorScheme.onSurface.withOpacity(0.6);
    // Define screens with unique keys for state preservation.
    final List<Widget> homeScreenItems = [
      FeedScreen(key: PageStorageKey('FeedScreen')),
      AddPost(key: PageStorageKey('AddPost')),
      ProfileScreenWidget(key: PageStorageKey('ProfileScreen')),
    ];

    // This listener runs the fade animation whenever a tab is switched.
    ref.listen<int>(tabIndexProvider, (previous, next) {
      if (previous != next) {
        _animationController.forward(from: 0.0);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        // onHorizontalDragEnd: (DragEndDetails details) {
        //   if (details.primaryVelocity == 0) return;
        //   if (details.primaryVelocity! < 0) {
        //     ref.read(tabIndexProvider.notifier).nextTab();
        //   } else if (details.primaryVelocity! > 0) {
        //     ref.read(tabIndexProvider.notifier).previousTab();
        //   }
        // },
        child: Stack(
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
        items: appTabsData.map((tabData) {
          bool isSelected = appTabsData.indexOf(tabData) == currentTabIndex;
          return BottomNavigationBarItem(icon: Icon(isSelected ? tabData.activeIcon : tabData.defaultIcon));
        }).toList(),
      ),
    );
  }
}
