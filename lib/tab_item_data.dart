// tab_item_data.dart
import 'package:flutter/cupertino.dart';

enum AppTab { feed, add, profile, memo } // Added memo tab

final List<TabItemData> appTabsData = [
  TabItemData(tab: AppTab.feed, defaultIcon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: 'Feed'),
  TabItemData(tab: AppTab.add, defaultIcon: CupertinoIcons.add_circled, activeIcon: CupertinoIcons.add_circled_solid, label: 'Add'),
  TabItemData(tab: AppTab.profile, defaultIcon: CupertinoIcons.person, activeIcon: CupertinoIcons.person_fill, label: 'Profile'),
  TabItemData(tab: AppTab.memo, defaultIcon: CupertinoIcons.globe, activeIcon: CupertinoIcons.globe, label: 'Memo'), // Added memo tab
];

class TabItemData {
  final AppTab tab;
  final IconData defaultIcon;
  final IconData activeIcon;
  final String label;

  TabItemData({required this.tab, required this.defaultIcon, required this.activeIcon, required this.label});
}
