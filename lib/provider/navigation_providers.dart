import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tab_index_notifier.dart';

// Provider to hold the ID of the profile to navigate to.
// This allows PostCardHeader to set the target, and ProfileScreen to read it.
final profileTargetIdProvider = StateProvider<String?>((ref) => null);

// Your existing tabIndexProvider might be here or in home.dart or another global provider file.
// For example, if it's defined in home.dart, that's fine.
// Ensure it's accessible where needed.
// Example of how it might look if defined globally:
// final tabIndexProvider = StateNotifierProvider<TabIndexNotifier, int>((ref) {
//   return TabIndexNotifier(3); // Assuming 3 tabs
// });
// class TabIndexNotifier extends StateNotifier<int> {
//   final int totalTabs;
//   TabIndexNotifier(this.totalTabs, [int initialIndex = 0]) : super(initialIndex);
//   void setTab(int index) {
//     if (index >= 0 && index < totalTabs) state = index;
//   }
// }
final tabIndexProvider = StateNotifierProvider<TabIndexNotifier, int>((ref) {
  const totalTabs = 3; // Or get this from a config provider
  return TabIndexNotifier(totalTabs);
});
