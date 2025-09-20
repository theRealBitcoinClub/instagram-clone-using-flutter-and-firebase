// providers/avatar_refresh_coordinator.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final avatarRefreshStateProvider = StateNotifierProvider<AvatarRefreshNotifier, Map<String, bool>>((ref) {
  return AvatarRefreshNotifier();
});

class AvatarRefreshNotifier extends StateNotifier<Map<String, bool>> {
  AvatarRefreshNotifier() : super({});

  bool isRefreshing(String creatorId) => state[creatorId] ?? false;

  void setRefreshing(String creatorId, bool refreshing) {
    state = {...state, creatorId: refreshing};
  }

  void completeRefresh(String creatorId) {
    state = {...state, creatorId: false};
  }
}
