import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import if not already present
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
import 'package:mahakka/sliver_app_bar_delegate.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/image_detail_dialog.dart';
import 'package:mahakka/widgets/post_dialog.dart';
import 'package:mahakka/widgets/profile/posts_categorizer.dart';
import 'package:mahakka/widgets/profile/profile_content_grid.dart';
import 'package:mahakka/widgets/profile/profile_content_list.dart';
import 'package:mahakka/widgets/profile/profile_header.dart';
import 'package:mahakka/widgets/profile/profile_placeholders.dart';
import 'package:mahakka/widgets/profile/profile_tab_selector.dart';
import 'package:mahakka/widgets/profile/settings_widget.dart';
import 'package:mahakka/widgets/profile/youtube_controller_manager.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../intros/intro_enums.dart';
import '../intros/intro_overlay.dart';
import '../intros/intro_state_notifier.dart';
import '../provider/profile_data_model_provider.dart';
import '../widgets/profile/profile_app_bar.dart';
import 'home.dart';

class ScrollUpIntent extends Intent {}

class ScrollDownIntent extends Intent {}

class SwitchTabLeftIntent extends Intent {}

class SwitchTabRightIntent extends Intent {}

class ProfileScreenWidget extends ConsumerStatefulWidget {
  const ProfileScreenWidget({Key? key}) : super(key: key);

  @override
  _ProfileScreenWidgetState createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends ConsumerState<ProfileScreenWidget> with TickerProviderStateMixin {
  final YouTubeControllerManager _ytManager = YouTubeControllerManager();
  final ScrollController _scrollController = ScrollController();
  int _viewMode = 0;
  String? _currentProfileId = "";
  Timer? _minDisplayTimer;
  bool _minDisplayTimeElapsed = false;
  bool _showIntro = true;
  final _introType = IntroType.profileScreen;

  @override
  void dispose() {
    _ytManager.dispose();
    _scrollController.dispose();
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  void _updateViewMode(int newMode) {
    Sentry.addBreadcrumb(Breadcrumb(message: "profile viewmode $newMode"));
    if (newMode != _viewMode) {
      setState(() {
        _viewMode = newMode;
      });
      // Handle video pausing
      if (newMode != 1) {
        _ytManager.pauseAll();
      }
    }
  }

  void _startMinDisplayTimer() {
    _minDisplayTimeElapsed = false;
    _minDisplayTimer?.cancel();
    _minDisplayTimer = Timer(Duration(milliseconds: 1111), () {
      if (mounted) {
        setState(() {
          _minDisplayTimeElapsed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loggedInUser = ref.watch(userProvider);
    final currentTabIndex = ref.watch(currentTabIndexProvider);
    String? targetProfileId = ref.watch(profileTargetIdProvider);
    int limit = ref.watch(profileLimitProvider);
    // ref.watch(profileBalanceProvider);
    _showIntro = ref.read(introStateNotifierProvider.notifier).shouldShow(_introType);

    context.afterLayout(refreshUI: true, () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });

    if (targetProfileId != _currentProfileId) {
      _currentProfileId = targetProfileId;
      _startMinDisplayTimer();
    }

    return Consumer(
      builder: (context, ref, child) {
        final profileDataAsync = ref.watch(profileDataNotifier);

        return profileDataAsync.when(
          data: (profileData) {
            final dataReady = !profileData.isLoading && profileData.postsLoaded;
            final hasSeenLoadingEnough = _minDisplayTimeElapsed && dataReady;

            if (!hasSeenLoadingEnough) {
              return ProfileLoadingScaffold(theme: theme, message: dataReady ? "Finishing up..." : "Loading Posts...");
            }

            return _buildProfileScreen(profileData, loggedInUser, currentTabIndex, theme, limit);
          },
          loading: () => ProfileLoadingScaffold(theme: theme, message: "Loading Profile..."),
          error: (error, stack) => ProfileErrorScaffold(
            theme: theme,
            message: "Error loading profile: $error",
            onRetry: () {
              // _startMinDisplayTimer();
              ref.invalidate(profileDataNotifier);
              ref.refresh(profileDataNotifier);
              ref.read(navigationStateProvider.notifier).navigateToOwnProfile();
            },
          ),
        );
      },
    );
  }

  double _startDragX = 0.0;
  double _currentDragX = 0.0;

  void _handleHorizontalDragStart(DragStartDetails details) {
    _startDragX = details.globalPosition.dx;
    _currentDragX = _startDragX;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _currentDragX = details.globalPosition.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final dragDistance = _currentDragX - _startDragX;
    final sensitivity = 50.0;

    if (dragDistance < -sensitivity) {
      _navigateToAdjacentTab(1);
    } else if (dragDistance > sensitivity) {
      _navigateToAdjacentTab(-1);
    }

    _startDragX = 0.0;
    _currentDragX = 0.0;
  }

  void _navigateToAdjacentTab(int direction) {
    final List<int> availableTabs = [0, 1, 2, 4]; // Your tab indices
    final currentTabIndex = availableTabs.indexOf(_viewMode);
    final newTabIndex = (currentTabIndex + direction).clamp(0, availableTabs.length - 1);
    Sentry.addBreadcrumb(Breadcrumb(message: "swipe newTabIndex $newTabIndex"));

    if (newTabIndex != currentTabIndex) {
      _updateViewMode(availableTabs[newTabIndex]);
    }
  }

  Widget _buildProfileScreen(ProfileData profileData, MemoModelUser? loggedInUser, int currentTabIndex, ThemeData theme, limit) {
    final creator = profileData.creator;
    if (creator == null) {
      return ProfileErrorScaffold(
        theme: theme,
        message: "Profile not found or an error occurred.",
        onRetry: () => ref.read(navigationStateProvider.notifier).navigateToOwnProfile(),
      );
    }
    //
    // final focusNode = ref.watch(profileFocusNodeProvider);
    // focusNode.requestFocus();

    final isOwnProfile = loggedInUser?.profileIdMemoBch == creator.id;
    ref.read(profileDataNotifier.notifier).refreshCreatorDataOnProfileLoad(currentTabIndex, creator.id, isOwnProfile, context);

    return
    // Focus(
    // focusNode: ref.read(profileFocusNodeProvider),
    // onFocusChange: (hasFocus) {
    //   print('FOCUS: Profile Screen focus changed: $hasFocus');
    // },
    // child:
    Scaffold(
      key: ValueKey("profile_scaffold_${creator.id}_$limit"),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ProfileAppBar(
        creator: creator,
        isOwnProfile: isOwnProfile,
        onShowBchQrDialog: () => _showBchQrDialog(loggedInUser, theme),
        scrollController: _scrollController,
      ),
      body: Stack(
        children: [
          FocusableActionDetector(
            autofocus: false,
            onFocusChange: (hasFocus) {
              print('FOCUS: Profile Screen focus changed: $hasFocus');
            },
            focusNode: ref.read(profileFocusNodeProvider),
            shortcuts: {
              // Scrolling
              LogicalKeySet(LogicalKeyboardKey.arrowUp): ScrollUpIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowDown): ScrollDownIntent(),
              LogicalKeySet(LogicalKeyboardKey.pageUp): ScrollUpIntent(),
              LogicalKeySet(LogicalKeyboardKey.pageDown): ScrollDownIntent(),
              // Tab switching
              LogicalKeySet(LogicalKeyboardKey.arrowLeft): SwitchTabLeftIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowRight): SwitchTabRightIntent(),
              LogicalKeySet(LogicalKeyboardKey.keyA): SwitchTabLeftIntent(), // Alternative keys
              LogicalKeySet(LogicalKeyboardKey.keyD): SwitchTabRightIntent(),
            },
            actions: {
              ScrollUpIntent: CallbackAction<ScrollUpIntent>(
                onInvoke: (ScrollUpIntent intent) {
                  _scrollController.animateTo(
                    _scrollController.offset - 90,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                  );
                  return null;
                },
              ),
              ScrollDownIntent: CallbackAction<ScrollDownIntent>(
                onInvoke: (ScrollDownIntent intent) {
                  _scrollController.animateTo(
                    _scrollController.offset + 90,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                  );
                  return null;
                },
              ),
              SwitchTabLeftIntent: CallbackAction<SwitchTabLeftIntent>(
                onInvoke: (SwitchTabLeftIntent intent) {
                  _navigateToAdjacentTab(-1);
                  return null;
                },
              ),
              SwitchTabRightIntent: CallbackAction<SwitchTabRightIntent>(
                onInvoke: (SwitchTabRightIntent intent) {
                  _navigateToAdjacentTab(1);
                  return null;
                },
              ),
            },
            child: GestureDetector(
              onHorizontalDragStart: _handleHorizontalDragStart,
              onHorizontalDragUpdate: _handleHorizontalDragUpdate,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildProfileHeader(creator, isOwnProfile, theme)),
                  _buildTabSelector(),
                  _buildContent(theme, profileData, limit),
                ],
              ),
            ),
          ),
          if (_showIntro) IntroOverlay(introType: _introType, onComplete: () {}),
        ],
      ),
      // ),
    );
  }

  Widget _buildProfileHeader(MemoModelCreator creator, bool isOwnProfile, ThemeData theme) {
    return ProfileHeader(
      creator: creator,
      isOwnProfile: isOwnProfile,
      onProfileButtonPressed: () => _showSettings(creator),
      showImageDetail: () => showCreatorImageDetail(context: context, creator: creator),
      showDefaultAvatar: false,
    );
  }

  Widget _buildTabSelector() {
    return SliverPersistentHeader(
      delegate: SliverAppBarDelegate(
        minHeight: ProfileTabSelector.height,
        maxHeight: ProfileTabSelector.height,
        child: ProfileTabSelector(
          viewMode: _viewMode,
          onViewModeChanged: _updateViewMode,
          child: Container(), // Empty container since content is in separate sliver
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildContent(ThemeData theme, ProfileData profileData, limit) {
    if (profileData.categorizer.isEmpty) {
      return _buildLoadingContent(theme);
    }
    return KeyedSubtree(
      key: ValueKey('${profileData.creator!.id}_$_viewMode$limit'),
      child: _buildSliverCategorizedView(theme, profileData.creator!, profileData.categorizer, _viewMode),
    );
  }

  Widget _buildLoadingContent(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
    );
  }

  Widget _buildSliverCategorizedView(ThemeData theme, MemoModelCreator creator, PostsCategorizer categorizer, int viewMode) {
    switch (viewMode) {
      case 0: // Images
        return ProfileContentGrid(
          posts: categorizer.imagePosts,
          onPostImageTap: (index) => _showPostDialog(categorizer.imagePosts, index),
          totalCount: categorizer.totalPosts(),
        );
      case 1: // Videos
        return ProfileContentList.youTube(
          posts: categorizer.videoPosts,
          ytControllerNotifiers: _ytManager.controllers,
          creatorName: creator.name,
          totalCount: categorizer.totalPosts(),
        );
      case 2: // Tagged (text only)
        return ProfileContentList.generic(
          posts: categorizer.taggedPosts,
          creatorName: creator.name,
          isTopicList: false,
          totalCount: categorizer.totalPosts(),
        );
      case 4: // Topics (text only)
        return ProfileContentList.generic(
          posts: categorizer.topicPosts,
          creatorName: creator.name,
          isTopicList: true,
          totalCount: categorizer.totalPosts(),
        );
      default:
        return EmptySliverContent(message: "Select a view to see posts.", theme: theme);
    }
  }

  void _showPostDialog(List<MemoModelPost> posts, int index) {
    showPostImageFullscreenWidget(context: context, theme: Theme.of(context), posts: posts, initialIndex: index);
  }

  void _showSettings(MemoModelCreator creator) {
    final loggedInUser = ref.read(userProvider);
    final isOwnProfile = loggedInUser?.profileIdMemoBch == creator.id;

    if (isOwnProfile) {
      showDialog(
        context: context,
        builder: (context) => SettingsWidget(initialTab: SettingsTab.creator),
      );
    } else {
      ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.info, "Follow/Message functionality is coming soon!");
    }
  }

  void _showBchQrDialog(MemoModelUser? loggedInUser, ThemeData theme) {
    if (loggedInUser != null) {
      showQrCodeDialog(ctx: context, user: loggedInUser);
    } else {
      ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, "User data not available for QR code.");
    }
  }
}
