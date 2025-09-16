// tab_item_data.dart
import 'package:flutter/cupertino.dart';

enum AppTab {
  feed(tabIndex: 0, icon: CupertinoIcons.house, active: CupertinoIcons.house_fill, label: 'Feed'),
  add(tabIndex: 1, icon: CupertinoIcons.add_circled, active: CupertinoIcons.add_circled_solid, label: 'Add'),
  profile(tabIndex: 2, icon: CupertinoIcons.person, active: CupertinoIcons.person_fill, label: 'Profile'),
  memo(tabIndex: 3, icon: CupertinoIcons.globe, active: CupertinoIcons.globe, label: 'Memo');

  final int tabIndex;
  final IconData icon;
  final IconData active;
  final String label;

  const AppTab({required this.tabIndex, required this.icon, required this.active, required this.label});

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

// You can keep this class if you still need it for other purposes,
// but now all the data is contained within the enum itself
// class TabItemData {
//   final AppTab tab;
//   final IconData icon;
//   final IconData active;
//   final String label;
//
//   TabItemData({required this.tab, required this.icon, required this.active, required this.label});
// }

// Optional: If you still want a list for easy iteration
// final List<AppTab> appTabs = AppTab.values;
