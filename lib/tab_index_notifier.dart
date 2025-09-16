import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabIndexNotifier extends StateNotifier<int> {
  int totalTabs;

  TabIndexNotifier(this.totalTabs) : super(0); // Initial tab is 0

  void setTab(int newIndex) {
    if (newIndex >= 0 && newIndex < totalTabs) {
      state = newIndex;
    }
  }

  void nextTab() {
    state = (state + 1) % totalTabs;
  }

  void previousTab() {
    state = (state - 1 + totalTabs) % totalTabs;
  }
}
