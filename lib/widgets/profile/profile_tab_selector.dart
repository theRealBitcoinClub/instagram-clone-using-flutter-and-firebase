import 'dart:async';

import 'package:flutter/material.dart';

class ProfileTabSelector extends StatefulWidget {
  final int viewMode;
  final onViewModeChanged;
  final Widget child;
  static const double height = 50;

  const ProfileTabSelector({Key? key, required this.viewMode, required this.onViewModeChanged, required this.child}) : super(key: key);

  @override
  State<ProfileTabSelector> createState() => _ProfileTabSelectorState();
}

class _TabData {
  final int index;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String tooltip;

  const _TabData({required this.index, required this.inactiveIcon, required this.activeIcon, required this.tooltip});
}

class _ProfileTabSelectorState extends State<ProfileTabSelector> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isAnimating = false;
  Timer? _animationTimer;

  static const List<_TabData> _tabs = [
    _TabData(index: 0, inactiveIcon: Icons.grid_on_rounded, activeIcon: Icons.grid_view_rounded, tooltip: "Images"),
    _TabData(index: 1, inactiveIcon: Icons.video_library_outlined, activeIcon: Icons.video_library_rounded, tooltip: "Videos"),
    _TabData(index: 2, inactiveIcon: Icons.tag_outlined, activeIcon: Icons.tag_rounded, tooltip: "Tagged"),
    _TabData(index: 4, inactiveIcon: Icons.alternate_email_outlined, activeIcon: Icons.alternate_email_rounded, tooltip: "Topics"),
  ];

  // Pre-built const tab widgets for all possible states
  static const List<Widget> _inactiveTabs = [
    Tab(key: ValueKey('tab_0_inactive'), icon: Icon(Icons.grid_on_rounded, size: 28)),
    Tab(key: ValueKey('tab_1_inactive'), icon: Icon(Icons.video_library_outlined, size: 28)),
    Tab(key: ValueKey('tab_2_inactive'), icon: Icon(Icons.tag_outlined, size: 28)),
    Tab(key: ValueKey('tab_4_inactive'), icon: Icon(Icons.alternate_email_outlined, size: 28)),
  ];

  static const List<Widget> _activeTabs = [
    Tab(key: ValueKey('tab_0_active'), icon: Icon(Icons.grid_view_rounded, size: 28)),
    Tab(key: ValueKey('tab_1_active'), icon: Icon(Icons.video_library_rounded, size: 28)),
    Tab(key: ValueKey('tab_2_active'), icon: Icon(Icons.tag_rounded, size: 28)),
    Tab(key: ValueKey('tab_4_active'), icon: Icon(Icons.alternate_email_rounded, size: 28)),
  ];

  // Cache for current tabs to avoid rebuilding the list
  List<Widget>? _cachedCurrentTabs;
  int? _cachedViewMode;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: _getTabIndex(widget.viewMode));
    _tabController.addListener(_onTabChanged);
  }

  List<Widget> _buildCurrentTabs() {
    // Return cached tabs if view mode hasn't changed
    if (_cachedViewMode == widget.viewMode && _cachedCurrentTabs != null) {
      return _cachedCurrentTabs!;
    }

    // Direct array construction without generate
    final currentTabs = <Widget>[];
    for (int i = 0; i < _tabs.length; i++) {
      final tab = _tabs[i];
      final isActive = widget.viewMode == tab.index;
      currentTabs.add(isActive ? _activeTabs[i] : _inactiveTabs[i]);
    }

    _cachedViewMode = widget.viewMode;
    _cachedCurrentTabs = currentTabs;
    return currentTabs;
  }

  @override
  void didUpdateWidget(ProfileTabSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear cache if view mode changed
    if (oldWidget.viewMode != widget.viewMode) {
      _cachedCurrentTabs = null;
      _cachedViewMode = null;

      // Only animate if the tab index actually changed
      final newTabIndex = _getTabIndex(widget.viewMode);
      if (newTabIndex != _tabController.index) {
        _animateToTab(newTabIndex);
      }
    }
  }

  int _getTabIndex(int viewMode) {
    for (int i = 0; i < _tabs.length; i++) {
      if (_tabs[i].index == viewMode) return i;
    }
    return 0;
  }

  int _getViewMode(int tabIndex) {
    return _tabs[tabIndex].index;
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _isAnimating = false;
      _animationTimer?.cancel();
      final newViewMode = _getViewMode(_tabController.index);
      if (newViewMode != widget.viewMode) {
        widget.onViewModeChanged(newViewMode);
      }
    }
  }

  void _animateToTab(int targetIndex) {
    if (_tabController.index == targetIndex) return;

    if (_isAnimating) {
      _tabController.index = targetIndex;
      return;
    }

    _isAnimating = true;
    _tabController.animateTo(targetIndex, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _handleTabTap(int index) {
    final newViewMode = _getViewMode(index);
    if (newViewMode != widget.viewMode) {
      widget.onViewModeChanged(newViewMode);
    }
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary,
      height: ProfileTabSelector.height,
      child: TabBar(
        padding: EdgeInsets.zero,
        dividerHeight: 0,
        controller: _tabController,
        indicator: const BoxDecoration(color: Colors.black54),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha(169),
        onTap: _handleTabTap,
        tabs: _buildCurrentTabs(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildTabBar(theme),
        Expanded(child: widget.child),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }
}
