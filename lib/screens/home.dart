import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/add_screen.dart'; // Ensure AddPost is themed
import 'package:mahakka/screens/feed_screen.dart'; // Ensure FeedScreen is themed
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/widgets/profile/profile_screen_widget.dart';

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

  // @override
  // void initState() {
  //   super.initState();
  //   final initialIndex = ref.read(tabIndexProvider); // Read initial index
  //   _pageController = PageController(initialPage: initialIndex);
  //   _tabController = TabController(length: _totalTabs, vsync: this, initialIndex: initialIndex);
  //
  //   // Listener to update Riverpod state when PageController changes (e.g., due to swipe)
  //   _pageController.addListener(() {
  //     final currentPage = _pageController.page?.round();
  //     if (currentPage != null && currentPage != ref.read(tabIndexProvider)) {
  //       ref.read(tabIndexProvider.notifier).setTab(currentPage);
  //     }
  //   });
  //
  //   // Listener to update Riverpod state when TabController changes (e.g., due to tap on TabBar)
  //   _tabController.addListener(() {
  //     if (_tabController.indexIsChanging || _tabController.index != ref.read(tabIndexProvider)) {
  //       // Check indexIsChanging to avoid issues during programmatic animations
  //       if (_tabController.index != ref.read(tabIndexProvider)) {
  //         ref.read(tabIndexProvider.notifier).setTab(_tabController.index);
  //       }
  //     }
  //   });
  //   ref.read(backgroundScraperManagerProvider);
  // }
  //
  // @override
  // void dispose() {
  //   _pageController.dispose();
  //   _tabController.dispose();
  //   _scaffoldFocusNode.dispose();
  //   super.dispose();
  // }

  void _navigateToNextTab() {
    ref.read(tabIndexProvider.notifier).nextTab();
  }

  void _navigateToPreviousTab() {
    ref.read(tabIndexProvider.notifier).previousTab();
  }

  @override
  // Widget build(BuildContext context) {
  //   // Watch the current tab index from the provider.
  //   final currentTabIndex = ref.watch(tabIndexProvider);
  //   final ThemeData theme = Theme.of(context);
  //   final ColorScheme colorScheme = theme.colorScheme;
  //   final Color cupertinoActiveColor = colorScheme.primary;
  //   final Color cupertinoInactiveColor = colorScheme.onSurface.withOpacity(0.6);
  //
  //   // The list of screens should be defined outside the build method if possible,
  //   // but it's fine here as they don't depend on a changing state.
  //   final List<Widget> homeScreenItems = [
  //     // Use Keys to help Flutter identify and preserve the state of each widget.
  //     // This is good practice when dealing with lists of widgets.
  //     FeedScreen(key: PageStorageKey('FeedScreen')),
  //     AddPost(key: PageStorageKey('AddPost')),
  //     ProfileScreen(key: PageStorageKey('ProfileScreen')),
  //   ];
  //
  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     body: IndexedStack(
  //       index: currentTabIndex, // This will display the widget at this index.
  //       children: homeScreenItems,
  //     ),
  //     bottomNavigationBar: CupertinoTabBar(
  //       height: 70,
  //       backgroundColor:
  //           theme.bottomNavigationBarTheme.backgroundColor ?? (theme.brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]),
  //       activeColor: cupertinoActiveColor,
  //       inactiveColor: cupertinoInactiveColor,
  //       currentIndex: currentTabIndex,
  //       onTap: (index) => ref.read(tabIndexProvider.notifier).setTab(index),
  //       iconSize: 30.0,
  //       border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
  //       items: appTabsData.map((tabData) {
  //         bool isSelected = appTabsData.indexOf(tabData) == currentTabIndex;
  //         return BottomNavigationBarItem(icon: Icon(isSelected ? tabData.activeIcon : tabData.defaultIcon));
  //       }).toList(),
  //     ),
  //   );
  // }
  @override
  // Widget build(BuildContext context) {
  //   final currentTabIndex = ref.watch(tabIndexProvider);
  //   final ThemeData theme = Theme.of(context);
  //   final ColorScheme colorScheme = theme.colorScheme;
  //   final Color cupertinoActiveColor = colorScheme.primary;
  //   final Color cupertinoInactiveColor = colorScheme.onSurface.withOpacity(0.6);
  //
  //   // The list of screens should be defined with unique keys.
  //   // This is crucial for AnimatedSwitcher to identify different widgets.
  //   final List<Widget> homeScreenItems = [
  //     FeedScreen(key: ValueKey('FeedScreen')),
  //     AddPost(key: ValueKey('AddPost')),
  //     ProfileScreen(key: ValueKey('ProfileScreen')),
  //   ];
  //
  //   return Scaffold(
  //     backgroundColor: theme.scaffoldBackgroundColor,
  //     body: GestureDetector(
  //       onHorizontalDragEnd: (DragEndDetails details) {
  //         if (details.primaryVelocity == 0) return;
  //         if (details.primaryVelocity! < 0) {
  //           ref.read(tabIndexProvider.notifier).nextTab();
  //         } else if (details.primaryVelocity! > 0) {
  //           ref.read(tabIndexProvider.notifier).previousTab();
  //         }
  //       },
  //       child: AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 300),
  //         // Use a fade transition for a smooth animation between screens.
  //         transitionBuilder: (Widget child, Animation<double> animation) {
  //           return FadeTransition(opacity: animation, child: child);
  //         },
  //         child: homeScreenItems[currentTabIndex],
  //       ),
  //     ),
  //     bottomNavigationBar: CupertinoTabBar(
  //       height: 70,
  //       backgroundColor:
  //           theme.bottomNavigationBarTheme.backgroundColor ?? (theme.brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]),
  //       activeColor: cupertinoActiveColor,
  //       inactiveColor: cupertinoInactiveColor,
  //       currentIndex: currentTabIndex,
  //       onTap: (index) => ref.read(tabIndexProvider.notifier).setTab(index),
  //       iconSize: 30.0,
  //       border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
  //       items: appTabsData.map((tabData) {
  //         bool isSelected = appTabsData.indexOf(tabData) == currentTabIndex;
  //         return BottomNavigationBarItem(icon: Icon(isSelected ? tabData.activeIcon : tabData.defaultIcon));
  //       }).toList(),
  //     ),
  //   );
  // }
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
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity == 0) return;
          if (details.primaryVelocity! < 0) {
            ref.read(tabIndexProvider.notifier).nextTab();
          } else if (details.primaryVelocity! > 0) {
            ref.read(tabIndexProvider.notifier).previousTab();
          }
        },
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
