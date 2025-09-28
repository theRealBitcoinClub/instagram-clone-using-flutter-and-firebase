import 'dart:async';

import 'package:flutter/material.dart';

class ProfileTabSelector extends StatefulWidget {
  final int viewMode;
  final ValueChanged<int> onViewModeChanged;
  final Widget child;
  static const double height = 50;

  const ProfileTabSelector({Key? key, required this.viewMode, required this.onViewModeChanged, required this.child}) : super(key: key);

  @override
  State<ProfileTabSelector> createState() => _ProfileTabSelectorState();
}

class _ProfileTabSelectorState extends State<ProfileTabSelector> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAnimating = false;
  Timer? _animationTimer;

  final List<Map<String, dynamic>> _tabs = [
    {'index': 0, 'inactiveIcon': Icons.grid_on_rounded, 'activeIcon': Icons.grid_view_rounded, 'tooltip': "Images"},
    {'index': 1, 'inactiveIcon': Icons.video_library_outlined, 'activeIcon': Icons.video_library_rounded, 'tooltip': "Videos"},
    {'index': 2, 'inactiveIcon': Icons.tag_outlined, 'activeIcon': Icons.tag_rounded, 'tooltip': "Tagged"},
    {'index': 4, 'inactiveIcon': Icons.alternate_email_outlined, 'activeIcon': Icons.alternate_email_rounded, 'tooltip': "Topics"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: _getTabIndex(widget.viewMode));
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(ProfileTabSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMode != widget.viewMode && _getTabIndex(widget.viewMode) != _tabController.index) {
      _animateToTab(_getTabIndex(widget.viewMode));
    }
  }

  int _getTabIndex(int viewMode) {
    return _tabs.indexWhere((tab) => tab['index'] == viewMode);
  }

  int _getViewMode(int tabIndex) {
    return _tabs[tabIndex]['index'] as int;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Animation is in progress
      _isAnimating = true;
      _resetAnimationTimer();
    } else {
      // Animation completed
      _isAnimating = false;
      _animationTimer?.cancel();
      final newViewMode = _getViewMode(_tabController.index);
      if (newViewMode != widget.viewMode) {
        widget.onViewModeChanged(newViewMode);
      }
    }
  }

  void _resetAnimationTimer() {
    _animationTimer?.cancel();
    _animationTimer = Timer(Duration(milliseconds: 300), () {
      // If animation takes longer than expected, mark as not animating
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  void _animateToTab(int targetIndex) {
    // If we're already at the target index, no need to animate
    if (_tabController.index == targetIndex) return;

    // If currently animating, jump directly to target for fast taps
    if (_isAnimating) {
      _tabController.index = targetIndex;
      return;
    }

    _tabController.animateTo(targetIndex, duration: Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        // Tab selector buttons
        Container(
          color: theme.colorScheme.primary,
          height: ProfileTabSelector.height,
          child: TabBar(
            padding: EdgeInsets.zero,
            dividerHeight: 0,
            controller: _tabController,
            indicator: BoxDecoration(color: Colors.black.withAlpha(45)),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: theme.colorScheme.onPrimary,
            unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha(169),
            onTap: (index) {
              // Handle tab tap directly to ensure immediate response
              final newViewMode = _getViewMode(index);
              if (newViewMode != widget.viewMode) {
                widget.onViewModeChanged(newViewMode);
              }
            },
            tabs: _tabs.map((tab) {
              return Tab(icon: Icon(widget.viewMode == tab['index'] ? tab['activeIcon'] : tab['inactiveIcon'], size: 28));
            }).toList(),
          ),
        ),

        Expanded(child: widget.child),
      ],
    );
  }
}
