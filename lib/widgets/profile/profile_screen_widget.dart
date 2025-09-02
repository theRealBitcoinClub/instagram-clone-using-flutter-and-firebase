import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/sliver_app_bar_delegate.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/profile/posts_categorizer.dart';
import 'package:mahakka/widgets/profile/settings_widget.dart';
import 'package:mahakka/widgets/profile/youtube_controller_manager.dart';

import '../../memo/model/memo_model_user.dart';
import '../../provider/profile_providers.dart';
import '../../views_taggable/widgets/qr_code_dialog.dart';
import '../image_detail_dialog.dart';
import '../post_dialog.dart';
import 'profile_app_bar.dart';
import 'profile_content_grid.dart';
import 'profile_content_list.dart';
import 'profile_header.dart';
import 'profile_placeholders.dart';
import 'profile_tab_selector.dart';

class ProfileScreenWidget extends ConsumerStatefulWidget {
  const ProfileScreenWidget({Key? key}) : super(key: key);

  @override
  _ProfileScreenWidgetState createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends ConsumerState<ProfileScreenWidget> with TickerProviderStateMixin {
  final YouTubeControllerManager _ytManager = YouTubeControllerManager();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _viewMode = ValueNotifier(0);
  bool isRefreshingProfile = false;
  bool allowLogout = false;

  late PostsCategorizer _postsCategorizer;

  @override
  void initState() {
    super.initState();
    _viewMode.addListener(_onViewModeChanged);
    _postsCategorizer = PostsCategorizer(imagePosts: [], videoPosts: [], taggedPosts: [], topicPosts: []);
  }

  @override
  void dispose() {
    _viewMode.removeListener(_onViewModeChanged);
    _viewMode.dispose();
    _ytManager.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewModeChanged() {
    if (_viewMode.value != 1) {
      _ytManager.pauseAll();
    }
  }

  void refreshCreatorProfile(String profileId) {
    final profileProvider = ref.read(profileCreatorStateProvider.notifier);
    profileProvider.refreshUserRegisteredFlag();
    profileProvider.refreshCreatorCache(profileId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loggedInUser = ref.watch(userProvider);
    final creatorAsyncValue = ref.read(profileCreatorStateProvider);
    final postsAsyncValue = ref.watch(postsStreamProvider);
    final currentTabIndex = ref.watch(tabIndexProvider);

    return creatorAsyncValue.when(
      data: (creator) => _buildProfileScreen(creator, loggedInUser, postsAsyncValue, currentTabIndex, theme),
      loading: () => ProfileLoadingScaffold(theme: theme, message: "Loading Profile..."),
      error: (error, stack) =>
          ProfileErrorScaffold(theme: theme, message: "Error loading profile: $error", onRetry: () => ref.refresh(profileCreatorStateProvider)),
    );
  }

  Widget _buildProfileScreen(
    MemoModelCreator? creator,
    MemoModelUser? loggedInUser,
    AsyncValue<List<MemoModelPost>> postsAsyncValue,
    int currentTabIndex,
    ThemeData theme,
  ) {
    if (creator == null) {
      return ProfileErrorScaffold(
        theme: theme,
        message: "Profile not found or an error occurred.",
        onRetry: () => ref.refresh(profileCreatorStateProvider),
      );
    }

    final isOwnProfile = loggedInUser?.profileIdMemoBch == creator.id;
    _handleTabLogic(currentTabIndex, creator.id, isOwnProfile);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ProfileAppBar(creator: creator, isOwnProfile: isOwnProfile, onShowBchQrDialog: () => _showBchQrDialog(loggedInUser, theme)),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _buildProfileHeader(creator, isOwnProfile, theme)),
            _buildTabSelector(),
            _buildContent(theme, postsAsyncValue, creator),
          ],
        ),
      ),
    );
  }

  void _handleTabLogic(int currentTabIndex, String profileId, bool isOwnProfile) {
    if (currentTabIndex == 2) {
      if (!isRefreshingProfile) {
        isRefreshingProfile = true;
        refreshCreatorProfile(profileId);
        isRefreshingProfile = false;
      }
      if (isOwnProfile) {
        ref.read(profileCreatorStateProvider.notifier).startAutoRefreshBalance();
      }
    } else {
      ref.read(profileCreatorStateProvider.notifier).stopAutoRefreshBalance();
    }
  }

  Future<void> _refreshData() async {
    ref.refresh(profileCreatorStateProvider);
    ref.refresh(postsStreamProvider);
  }

  Widget _buildProfileHeader(MemoModelCreator creator, bool isOwnProfile, ThemeData theme) {
    return ProfileHeader(
      creator: creator,
      isOwnProfile: isOwnProfile,
      isRefreshingProfile: isRefreshingProfile,
      onProfileButtonPressed: () => _showSettings(creator),
      showImageDetail: () => showCreatorImageDetail(
        context: context,
        theme: theme,
        creator: creator,
        getShowDefaultAvatar: () => false,
        setShowDefaultAvatar: (_) {},
      ),
      showDefaultAvatar: false,
    );
  }

  Widget _buildTabSelector() {
    return SliverPersistentHeader(
      delegate: SliverAppBarDelegate(
        minHeight: 60,
        maxHeight: 60,
        child: ValueListenableBuilder<int>(
          valueListenable: _viewMode,
          builder: (context, viewMode, child) {
            return ProfileTabSelector(viewMode: viewMode, onViewModeChanged: (newMode) => _viewMode.value = newMode);
          },
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildContent(ThemeData theme, AsyncValue<List<MemoModelPost>> postsAsyncValue, MemoModelCreator creator) {
    return postsAsyncValue.when(
      data: (posts) => _buildPostsContent(theme, posts, creator),
      loading: () => _buildLoadingContent(theme),
      error: (error, stack) => _buildErrorContent(error, theme),
    );
  }

  Widget _buildPostsContent(ThemeData theme, List<MemoModelPost> posts, MemoModelCreator creator) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _categorizePosts(posts);
    });

    return ValueListenableBuilder<int>(
      valueListenable: _viewMode,
      builder: (context, viewMode, child) {
        return _buildSliverCategorizedView(theme, creator, viewMode);
      },
    );
  }

  Widget _buildLoadingContent(ThemeData theme) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
    );
  }

  Widget _buildErrorContent(dynamic error, ThemeData theme) {
    return EmptySliverContent(message: 'Error loading posts. ${error.toString()}', theme: theme, icon: Icons.error_outline);
  }

  Widget _buildSliverCategorizedView(ThemeData theme, MemoModelCreator creator, int viewMode) {
    switch (viewMode) {
      case 0:
        return ProfileContentGrid(posts: _postsCategorizer.imagePosts, onPostImageTap: _showPostDialog);
      case 1:
        return ProfileContentList.youTube(
          posts: _postsCategorizer.videoPosts,
          ytControllerNotifiers: _ytManager.controllers,
          creatorName: creator.name,
        );
      case 2:
        return ProfileContentList.generic(posts: _postsCategorizer.taggedPosts, creatorName: creator.name);
      case 4:
        return ProfileContentList.generic(posts: _postsCategorizer.topicPosts, creatorName: creator.name);
      default:
        return EmptySliverContent(message: "Select a view to see posts.", theme: theme);
    }
  }

  void _showPostDialog(MemoModelPost post, Widget imageWidget) {
    showPostDialog(context: context, theme: Theme.of(context), post: post, creator: post.creator, imageWidget: imageWidget);
  }

  void _categorizePosts(List<MemoModelPost> allPosts) {
    final newCategorizer = PostsCategorizer.fromPosts(allPosts);
    _ytManager.cleanupUnused(newCategorizer.videoPosts);

    if (_postsCategorizer.hasChanged(newCategorizer)) {
      setState(() {
        _postsCategorizer = newCategorizer;
      });
    }
  }

  void _showSettings(MemoModelCreator creator) {
    final loggedInUser = ref.read(userProvider);
    final isOwnProfile = loggedInUser?.profileIdMemoBch == creator.id;

    if (isOwnProfile) {
      showDialog(
        context: context,
        builder: (context) => SettingsWidget(creator: creator, loggedInUser: loggedInUser, allowLogout: allowLogout),
      );
    } else {
      showSnackBar("Follow/Message functionality is coming soon!", context);
    }
  }

  void _showBchQrDialog(MemoModelUser? loggedInUser, ThemeData theme) {
    if (loggedInUser != null) {
      showQrCodeDialog(context: context, theme: theme, user: loggedInUser);
    } else {
      showSnackBar("User data not available for QR code.", context);
    }
  }
}
