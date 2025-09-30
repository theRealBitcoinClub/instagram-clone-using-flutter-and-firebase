import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/provider/profile_providers.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/navigation_providers.dart';
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

import '../intros/intro_enums.dart';
import '../intros/intro_overlay.dart';
import '../intros/intro_state_notifier.dart';
import '../widgets/profile/profile_app_bar.dart';

class ProfileScreenWidget extends ConsumerStatefulWidget {
  const ProfileScreenWidget({Key? key}) : super(key: key);

  @override
  _ProfileScreenWidgetState createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends ConsumerState<ProfileScreenWidget> with TickerProviderStateMixin {
  final YouTubeControllerManager _ytManager = YouTubeControllerManager();
  final ScrollController _scrollController = ScrollController();
  int _viewMode = 0;
  bool _isRefreshingProfile = false;
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
    _minDisplayTimer = Timer(Duration(seconds: 3), () {
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
        final profileDataAsync = ref.watch(profileDataProvider);

        return profileDataAsync.when(
          data: (profileData) {
            final dataReady = !profileData.isLoading && profileData.postsLoaded;
            final hasSeenLoadingEnough = _minDisplayTimeElapsed && dataReady;

            if (!hasSeenLoadingEnough) {
              return ProfileLoadingScaffold(theme: theme, message: dataReady ? "Finishing up..." : "Loading Posts...");
            }

            return _buildProfileScreen(profileData, loggedInUser, currentTabIndex, theme);
          },
          loading: () => ProfileLoadingScaffold(theme: theme, message: "Loading Profile..."),
          error: (error, stack) => ProfileErrorScaffold(
            theme: theme,
            message: "Error loading profile: $error",
            onRetry: () {
              _startMinDisplayTimer();
              ref.invalidate(profileDataProvider);
              ref.refresh(profileDataProvider);
              ref.read(navigationStateProvider.notifier).navigateToOwnProfile();
            },
          ),
        );
      },
    );
  }

  Future<void> _refreshData() async {
    try {
      await ref.refresh(profileDataProvider.future);
    } catch (e) {
      print("Error refreshing profile data: $e");
    }
  }

  void _safeRefresh() {
    Future.microtask(() {
      ref.refresh(profileDataProvider);
    });
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
    final sensitivity = 50.0; // Minimum drag distance to trigger tab change

    if (dragDistance < -sensitivity) {
      // Swiped left - go to next tab
      _navigateToAdjacentTab(1);
    } else if (dragDistance > sensitivity) {
      // Swiped right - go to previous tab
      _navigateToAdjacentTab(-1);
    }

    // Reset drag values
    _startDragX = 0.0;
    _currentDragX = 0.0;
  }

  void _navigateToAdjacentTab(int direction) {
    final List<int> availableTabs = [0, 1, 2, 4]; // Your tab indices
    final currentTabIndex = availableTabs.indexOf(_viewMode);
    final newTabIndex = (currentTabIndex + direction).clamp(0, availableTabs.length - 1);

    if (newTabIndex != currentTabIndex) {
      _updateViewMode(availableTabs[newTabIndex]);
    }
  }

  Widget _buildProfileScreen(ProfileData profileData, MemoModelUser? loggedInUser, int currentTabIndex, ThemeData theme) {
    final creator = profileData.creator;
    if (creator == null) {
      return ProfileErrorScaffold(theme: theme, message: "Profile not found or an error occurred.", onRetry: () => _safeRefresh);
    }

    final isOwnProfile = loggedInUser?.profileIdMemoBch == creator.id;

    // context.afterBuild(refreshUI: true, () {
    ref.read(profileDataProvider.notifier).refreshProfileDataAndStartBalanceTimer(currentTabIndex, creator.id, isOwnProfile, context);
    // _updateViewMode(1);
    // });

    return Scaffold(
      key: ValueKey("profile_scaffold_${creator.id}"),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ProfileAppBar(
        creator: creator,
        isOwnProfile: isOwnProfile,
        onShowBchQrDialog: () => _showBchQrDialog(loggedInUser, theme),
        scrollController: _scrollController,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onHorizontalDragStart: _handleHorizontalDragStart,
            onHorizontalDragUpdate: _handleHorizontalDragUpdate,
            onHorizontalDragEnd: _handleHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: _buildProfileHeader(creator, isOwnProfile, theme)),
                  _buildTabSelector(),
                  _buildContent(theme, profileData),
                ],
              ),
            ),
          ),
          if (_showIntro) IntroOverlay(introType: _introType, onComplete: () {}),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(MemoModelCreator creator, bool isOwnProfile, ThemeData theme) {
    return ProfileHeader(
      creator: creator,
      isOwnProfile: isOwnProfile,
      isRefreshingProfile: _isRefreshingProfile,
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

  Widget _buildContent(ThemeData theme, ProfileData profileData) {
    if (profileData.categorizer.isEmpty) {
      return _buildLoadingContent(theme);
    }
    return KeyedSubtree(
      key: ValueKey('${profileData.creator!.id}_$_viewMode'),
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
        return ProfileContentGrid(posts: categorizer.imagePosts, onPostImageTap: (index) => _showPostDialog(categorizer.imagePosts, index));
      case 1: // Videos
        return ProfileContentList.youTube(
          posts: categorizer.videoPosts,
          ytControllerNotifiers: _ytManager.controllers,
          creatorName: creator.name,
        );
      case 2: // Tagged (text only)
        return ProfileContentList.generic(posts: categorizer.taggedPosts, creatorName: creator.name);
      case 4: // Topics (text only)
        return ProfileContentList.generic(posts: categorizer.topicPosts, creatorName: creator.name);
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
      showSnackBar(type: SnackbarType.info, "Follow/Message functionality is coming soon!", context);
    }
  }

  void _showBchQrDialog(MemoModelUser? loggedInUser, ThemeData theme) {
    if (loggedInUser != null) {
      showQrCodeDialog(ctx: context, user: loggedInUser);
    } else {
      showSnackBar(type: SnackbarType.error, "User data not available for QR code.", context);
    }
  }
}
