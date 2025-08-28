import 'package:flutter_riverpod/flutter_riverpod.dart';

class TabIndexNotifier extends StateNotifier<int> {
  TabIndexNotifier(this._totalTabs) : super(0); // Initial tab is 0

  final int _totalTabs;

  void setTab(int newIndex) {
    if (newIndex >= 0 && newIndex < _totalTabs) {
      state = newIndex;
    }
  }

  void nextTab() {
    state = (state + 1) % _totalTabs;
  }

  void previousTab() {
    state = (state - 1 + _totalTabs) % _totalTabs;
  }
}
