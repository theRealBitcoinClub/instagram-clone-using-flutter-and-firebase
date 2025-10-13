// lib/provider/navigation_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/add/language_selector_widget.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../provider/user_provider.dart';
import '../providers/webview_providers.dart';
import '../resources/auth_method.dart';
import '../tab_item_data.dart';

// Centralized navigation state
class NavigationState {
  final int currentTabIndex;
  final String profileTargetId; // Non-nullable
  final bool isViewingOwnProfile;

  const NavigationState({
    required this.currentTabIndex,
    this.profileTargetId = '', // Empty string instead of null
    this.isViewingOwnProfile = true,
  });

  NavigationState copyWith({
    int? currentTabIndex,
    String? profileTargetId, // Can still pass null to mean "no change"
    bool? isViewingOwnProfile,
  }) {
    return NavigationState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      profileTargetId: profileTargetId ?? this.profileTargetId, // Handles null properly
      isViewingOwnProfile: isViewingOwnProfile ?? this.isViewingOwnProfile,
    );
  }
}

// Navigation state notifier with convenience methods
class NavigationStateNotifier extends StateNotifier<NavigationState> {
  final Ref _ref;

  NavigationStateNotifier(this._ref) : super(const NavigationState(currentTabIndex: 0));

  // Add this helper method to dismiss keyboard
  // void _dismissKeyboard() {
  //   // Method 1: System channels approach (most reliable)
  //   SystemChannels.textInput.invokeMethod('TextInput.hide');
  //
  //   // Method 2: Focus scope approach (alternative)
  //   // FocusManager.instance.primaryFocus?.unfocus();
  // }

  // Main navigation method that handles all scenarios
  void _doNavigate({
    required int tabIndex,
    String? profileTargetId, // null means "no change", empty string means "reset"
    // bool isOwnProfile = true,
    WebViewShow? webViewTarget,
    String? webViewValue,
    String? snackbarMessage,
    BuildContext? context,
  }) {
    try {
      Sentry.addBreadcrumb(
        Breadcrumb.userInteraction(
          data: {
            "profileId:": profileTargetId ?? "null",
            "tabIndex:": tabIndex.toString(),
            "webViewTarget:": webViewTarget ?? "null",
            "webViewValue:": webViewValue ?? "null",
            "snackbarMessage:": snackbarMessage?.toString(),
          },
          message: snackbarMessage,
          viewId: tabIndex.toString(),
          subCategory: "navigation",
        ),
      );
    } catch (e) {}

    try {
      LanguageSelectorDialog.forceDismissKeyboard();
    } catch (e) {}
    bool isOwnProfile = profileTargetId == null || profileTargetId.isEmpty ? true : _ref.read(userProvider)!.id == profileTargetId;
    // Validate tab index
    if (tabIndex < 0 || tabIndex >= AppTab.totalTabs) return;

    // Handle webview navigation (memo tab)
    if (tabIndex == AppTab.memo.tabIndex && webViewTarget != null && webViewValue != null) {
      WebViewNavigator.navigateTo(_ref, webViewTarget, webViewValue);
    }

    // Auto-reset profile target when leaving profile tab (unless explicitly set)
    final shouldResetProfileTarget = tabIndex != AppTab.profile.tabIndex && profileTargetId == null; // Only reset if not explicitly provided

    final String actualProfileTargetId = shouldResetProfileTarget ? '' : (profileTargetId ?? state.profileTargetId);

    final bool actualIsOwnProfile = shouldResetProfileTarget ? true : isOwnProfile;

    // Update navigation state
    state = state.copyWith(currentTabIndex: tabIndex, profileTargetId: actualProfileTargetId, isViewingOwnProfile: actualIsOwnProfile);

    // Show snackbar if provided
    if (snackbarMessage != null && context != null && context.mounted) {
      _ref.read(snackbarServiceProvider).showTranslatedSnackBar(snackbarMessage, type: SnackbarType.success);
    }
  }

  // ========== CONVENIENCE METHODS ==========

  // Navigate to feed tab (resets profile target)
  void navigateToFeed() {
    _doNavigate(
      tabIndex: AppTab.feed.tabIndex,
      profileTargetId: '', // Explicitly reset profile target
    );
  }

  // Navigate to add post tab (resets profile target)
  void navigateToAddPost({BuildContext? context}) {
    _doNavigate(
      tabIndex: AppTab.add.tabIndex,
      profileTargetId: '', // Explicitly reset profile target
      snackbarMessage: "Create a new post",
      context: context,
    );
  }

  // Navigate to profile tab (own profile)
  void navigateToOwnProfile() {
    _doNavigate(tabIndex: AppTab.profile.tabIndex, profileTargetId: _ref.read(userProvider)!.id);
  }

  // Navigate to specific creator profile
  void navigateToCreatorProfile(String creatorId) {
    _doNavigate(tabIndex: AppTab.profile.tabIndex, profileTargetId: creatorId);
  }

  // Navigate to webview with tag (resets profile target)
  void navigateToTag(String tagId, {BuildContext? context}) {
    _doNavigate(
      tabIndex: AppTab.memo.tabIndex,
      profileTargetId: '', // Reset profile target
      webViewTarget: WebViewShow.tag,
      webViewValue: tagId,
      snackbarMessage: "Viewing posts with tag: $tagId",
      context: context,
    );
  }

  // Navigate to webview with topic (resets profile target)
  void navigateToTopic(String topicId, {BuildContext? context}) {
    _doNavigate(
      tabIndex: AppTab.memo.tabIndex,
      profileTargetId: '', // Reset profile target
      webViewTarget: WebViewShow.topic,
      webViewValue: topicId,
      snackbarMessage: "Viewing topic: $topicId",
      context: context,
    );
  }

  // Navigate to webview with URL (resets profile target)
  void navigateToUrl(String url, {BuildContext? context}) {
    _doNavigate(
      tabIndex: AppTab.memo.tabIndex,
      profileTargetId: '', // Reset profile target
      webViewTarget: WebViewShow.url,
      webViewValue: url,
      snackbarMessage: "Opening URL",
      context: context,
    );
  }

  // Logout and navigate to feed
  void logoutAndNavigateToFeed() {
    _ref.read(authCheckerProvider).logOut();
    navigateToFeed(); // This includes profile target reset
  }

  // Back navigation (used in WillPopScope)
  void navigateBackToFeed() {
    navigateToFeed(); // This includes profile target reset
  }
}

// ========== PROVIDERS ==========

final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>((ref) => NavigationStateNotifier(ref));

// Convenience providers for accessing specific state
final currentTabIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationStateProvider).currentTabIndex;
});

final profileTargetIdProvider = Provider<String>((ref) {
  return ref.watch(navigationStateProvider).profileTargetId;
});

final isOwnProfileProvider = Provider<bool>((ref) {
  return ref.watch(navigationStateProvider).isViewingOwnProfile;
});
