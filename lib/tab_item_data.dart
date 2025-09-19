// tab_item_data.dart
import 'package:flutter/cupertino.dart';

enum AppTab {
  feed(tabIndex: 0, visibleTab: 0, icon: CupertinoIcons.house, active: CupertinoIcons.house_fill, label: 'FEED', isVisibleOnBar: true),
  add(
    tabIndex: 1,
    visibleTab: 1,
    icon: CupertinoIcons.add_circled,
    active: CupertinoIcons.add_circled_solid,
    label: 'CREATE',
    isVisibleOnBar: true,
  ),
  profile(tabIndex: 2, visibleTab: 2, icon: CupertinoIcons.person, active: CupertinoIcons.person_fill, label: 'PROFILE', isVisibleOnBar: true),
  memo(tabIndex: 3, visibleTab: 2, icon: CupertinoIcons.globe, active: CupertinoIcons.globe, label: 'MEMO', isVisibleOnBar: false);

  final int tabIndex;
  final int visibleTab;
  final IconData icon;
  final IconData active;
  final String label;
  final bool isVisibleOnBar;

  const AppTab({
    required this.tabIndex,
    required this.visibleTab,
    required this.icon,
    required this.active,
    required this.label,
    required this.isVisibleOnBar,
  });

  // Returns the total number of tabs
  static int get totalTabs => AppTab.values.length;

  // Helper method to get a tab by index
  static AppTab? fromIndex(int index) {
    try {
      return AppTab.values.firstWhere((tab) => tab.index == index);
    } catch (e) {
      return null;
    }
  }
}
