import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/add_screen.dart'; // Ensure AddPost is themed
import 'package:mahakka/screens/feed_screen.dart'; // Ensure FeedScreen is themed
import 'package:mahakka/tab_item_data.dart';

import '../provider/navigation_providers.dart';
import '../provider/scraper_provider.dart';
import '../widgets/profile/profile_screen_new.dart';

class HomeSceen extends ConsumerStatefulWidget {
  // Consider renaming to HomeScreen for convention
  const HomeSceen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeSceen> createState() => _HomeSceenState();
}

class _HomeSceenState extends ConsumerState<HomeSceen> with TickerProviderStateMixin {
  late PageController _pageController; // Renamed for convention
  late TabController _tabController;
  final FocusNode _scaffoldFocusNode = FocusNode();
  final int _totalTabs = 3; // Keep this for bounds and controller lengths

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(tabIndexProvider); // Read initial index
    _pageController = PageController(initialPage: initialIndex);
    _tabController = TabController(length: _totalTabs, vsync: this, initialIndex: initialIndex);

    // Listener to update Riverpod state when PageController changes (e.g., due to swipe)
    _pageController.addListener(() {
      final currentPage = _pageController.page?.round();
      if (currentPage != null && currentPage != ref.read(tabIndexProvider)) {
        ref.read(tabIndexProvider.notifier).setTab(currentPage);
      }
    });

    // Listener to update Riverpod state when TabController changes (e.g., due to tap on TabBar)
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.index != ref.read(tabIndexProvider)) {
        // Check indexIsChanging to avoid issues during programmatic animations
        if (_tabController.index != ref.read(tabIndexProvider)) {
          ref.read(tabIndexProvider.notifier).setTab(_tabController.index);
        }
      }
    });
    ref.read(backgroundScraperManagerProvider);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _scaffoldFocusNode.dispose();
    super.dispose();
  }

  void _navigateToNextTab() {
    ref.read(tabIndexProvider.notifier).nextTab();
  }

  void _navigateToPreviousTab() {
    ref.read(tabIndexProvider.notifier).previousTab();
  }

  @override
  Widget build(BuildContext context) {
    // Listener to update PageController when Riverpod state changes
    ref.listen<int>(tabIndexProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(next, duration: const Duration(milliseconds: 300), curve: Curves.ease);
      }
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });
    final currentTabIndex = ref.watch(tabIndexProvider);
    final ThemeData theme = Theme.of(context); // Get the current theme
    final ColorScheme colorScheme = theme.colorScheme;
    final Color cupertinoActiveColor = colorScheme.primary; // Use primary color for active items
    final Color cupertinoInactiveColor = colorScheme.onSurface.withOpacity(0.6); // Muted version of onSurface

    final List<Widget> homeScreenItems = [FeedScreen(), const AddPost(), const ProfileScreen()];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Background of the screen itself
      body: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity == 0) return;
          if (details.primaryVelocity! < 0) {
            _navigateToNextTab();
          } else if (details.primaryVelocity! > 0) {
            _navigateToPreviousTab();
          }
        },
        child: PageView(
          controller: _pageController,
          // onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(), // To disable swipe navigation
          children: homeScreenItems,
        ),
      ),
      bottomNavigationBar: CupertinoTabBar(
        height: 70, // Keep custom height if desired
        backgroundColor:
            theme.bottomNavigationBarTheme.backgroundColor ?? // Use Material BottomNavTheme bg
            (theme.brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]), // Fallback
        activeColor: cupertinoActiveColor,
        inactiveColor: cupertinoInactiveColor,
        currentIndex: currentTabIndex, // Use index from Riverpod
        onTap: (index) => ref.read(tabIndexProvider.notifier).setTab(index),
        iconSize: 30.0, // Default is 30.0, adjust as needed
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.5), // Use theme divider color
            width: 0.5, // Keep it subtle
          ),
        ),
        items: appTabsData.map((tabData) {
          // bool isSelected = currentAppTab == tabData.tab; // If using AppTab state
          bool isSelected = appTabsData.indexOf(tabData) == currentTabIndex; // Or by index
          return BottomNavigationBarItem(
            icon: Icon(isSelected ? tabData.activeIcon : tabData.defaultIcon),
            // label: tabData.label,
          );
        }).toList(),
      ),
    );
  }
}
