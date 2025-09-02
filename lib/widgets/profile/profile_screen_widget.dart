import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/sliver_app_bar_delegate.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/bch/mnemonic_backup_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../memo/model/memo_model_user.dart';
import '../../provider/profile_providers.dart';
import '../../repositories/creator_repository.dart';
import '../../resources/auth_method.dart';
import 'profile_app_bar.dart';
import 'profile_content_grid.dart';
import 'profile_content_list.dart';
import 'profile_dialog_helpers.dart';
import 'profile_header.dart';
import 'profile_placeholders.dart';
import 'profile_tab_selector.dart';

class ProfileScreenWidget extends ConsumerStatefulWidget {
  const ProfileScreenWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreenWidget> createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends ConsumerState<ProfileScreenWidget> with TickerProviderStateMixin {
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();
  final Map<String, ValueNotifier<YoutubePlayerController?>> _ytControllerNotifiers = {};
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<int> _viewMode = ValueNotifier(0);

  // Derived data - should not be stateful
  List<MemoModelPost> _imagePosts = [];
  List<MemoModelPost> _videoPosts = [];
  List<MemoModelPost> _taggedPosts = [];
  List<MemoModelPost> _topicPostsData = [];

  DateTime _lastCacheUpdate = DateTime.now().subtract(const Duration(seconds: 16));
  bool _isUpdatingCache = false;

  @override
  void initState() {
    super.initState();
    _viewMode.addListener(_onViewModeChanged);
  }

  @override
  void dispose() {
    _viewMode.removeListener(_onViewModeChanged);
    _viewMode.dispose();
    _disposeYouTubeControllers();
    _profileNameCtrl.dispose();
    _profileTextCtrl.dispose();
    _imgurCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _disposeYouTubeControllers() {
    for (var notifier in _ytControllerNotifiers.values) {
      notifier.value?.pause();
      notifier.value?.dispose();
      notifier.value = null;
      notifier.dispose();
    }
    _ytControllerNotifiers.clear();
  }

  void _onViewModeChanged() {
    // Pause all YouTube videos when changing view mode away from YouTube
    if (_viewMode.value != 1) {
      for (var notifier in _ytControllerNotifiers.values) {
        notifier.value?.pause();
      }
    }
  }

  void _cleanupUnusedYouTubeControllers(List<MemoModelPost> currentVideoPosts) {
    final currentVideoIds = currentVideoPosts.map((post) => post.id).whereType<String>().toSet();
    final controllersToRemove = _ytControllerNotifiers.keys.where((id) => !currentVideoIds.contains(id)).toList();

    for (var id in controllersToRemove) {
      final notifier = _ytControllerNotifiers.remove(id);
      notifier?.value?.pause();
      notifier?.value?.dispose();
      notifier?.dispose();
    }
  }

  void updateCacheIfAllowed(WidgetRef ref, String profileId) {
    final now = DateTime.now();
    if (_isUpdatingCache || now.difference(_lastCacheUpdate).inSeconds < 15) {
      return;
    }

    _lastCacheUpdate = now;
    _isUpdatingCache = true;

    final creatorRepo = ref.read(creatorRepositoryProvider);
    creatorRepo.refreshCreatorCache(profileId, () => _isUpdatingCache = false, () => _isUpdatingCache = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final loggedInUser = ref.watch(userProvider);
    final creatorAsyncValue = ref.read(creatorStateProvider);
    final postsAsyncValue = ref.watch(postsStreamProvider);
    final currentTabIndex = ref.watch(tabIndexProvider);

    // Use the creator data directly since we're reading it (not watching)
    if (creatorAsyncValue is AsyncData<MemoModelCreator?>) {
      final creator = creatorAsyncValue.value;
      if (creator == null) {
        return ProfileErrorScaffold(
          theme: theme,
          message: "Profile not found or an error occurred.",
          onRetry: () => ref.refresh(creatorStateProvider),
        );
      }

      final currentProfileId = creator.id;
      final isOwnProfile = loggedInUser?.profileIdMemoBch == currentProfileId;

      // Handle cache updates and balance refresh only when needed
      _handleTabSpecificLogic(currentTabIndex, currentProfileId, ref);

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: ProfileAppBar(creator: creator, isOwnProfile: isOwnProfile, onShowBchQrDialog: () => _showBchQrDialog(loggedInUser, theme)),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.refresh(creatorStateProvider);
            ref.refresh(postsStreamProvider);
          },
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildProfileHeader(creator, loggedInUser, isOwnProfile, creatorAsyncValue.isLoading, theme)),
              SliverPersistentHeader(
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
              ),
              _buildSliverContent(theme, postsAsyncValue, creator),
            ],
          ),
        ),
      );
    } else if (creatorAsyncValue is AsyncLoading) {
      return ProfileLoadingScaffold(theme: theme, message: "Loading Profile...");
    } else if (creatorAsyncValue is AsyncError) {
      return ProfileErrorScaffold(
        theme: theme,
        message: "Error loading profile: ${creatorAsyncValue.error}",
        onRetry: () => ref.refresh(creatorStateProvider),
      );
    }

    // Fallback
    return ProfileLoadingScaffold(theme: theme, message: "Loading Profile...");
  }

  void _handleTabSpecificLogic(int currentTabIndex, String currentProfileId, WidgetRef ref) {
    if (currentTabIndex == 2) {
      updateCacheIfAllowed(ref, currentProfileId);
      ref.read(creatorStateProvider.notifier).startAutoRefreshBalance();
    } else {
      ref.read(creatorStateProvider.notifier).stopAutoRefreshBalance();
    }
  }

  Widget _buildProfileHeader(MemoModelCreator creator, MemoModelUser? loggedInUser, bool isOwnProfile, bool isLoading, ThemeData theme) {
    return ProfileHeader(
      creator: creator,
      loggedInUser: loggedInUser,
      isOwnProfile: isOwnProfile,
      isRefreshingProfile: isLoading,
      onProfileButtonPressed: () => _onProfileButtonPressed(creator),
      showImageDetail: () => showCreatorImageDetail(context, theme, creator, () => false, (_) {}),
      buildStatColumn: _buildStatColumn,
      showDefaultAvatar: false,
    );
  }

  Widget _buildSliverContent(ThemeData theme, AsyncValue<List<MemoModelPost>> postsAsyncValue, MemoModelCreator creator) {
    return postsAsyncValue.when(
      data: (posts) {
        // Categorize posts only when data actually changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _categorizePosts(posts);
        });

        return ValueListenableBuilder<int>(
          valueListenable: _viewMode,
          builder: (context, viewMode, child) {
            return _buildSliverCategorizedView(theme, creator, viewMode);
          },
        );
      },
      loading: () {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
        );
      },
      error: (error, stack) {
        return EmptySliverContent(message: 'Error loading posts. ${error.toString()}', theme: theme, icon: Icons.error_outline);
      },
    );
  }

  Widget _buildSliverCategorizedView(ThemeData theme, MemoModelCreator creator, int viewMode) {
    switch (viewMode) {
      case 0: // Grid View (Images)
        return ProfileContentGrid(
          posts: _imagePosts,
          onPostImageTap: (post, imageWidget) =>
              showPostDialog(context: context, theme: theme, post: post, creator: null, imageWidget: imageWidget),
        );
      case 1: // YouTube Videos
        return ProfileContentList.youTube(posts: _videoPosts, ytControllerNotifiers: _ytControllerNotifiers, creatorName: creator.name);
      case 2: // Tagged Posts
        return ProfileContentList.generic(posts: _taggedPosts, creatorName: creator.name);
      case 4: // Topic Posts
        return ProfileContentList.generic(posts: _topicPostsData, creatorName: creator.name);
      default:
        return EmptySliverContent(message: "Select a view to see posts.", theme: theme);
    }
  }

  void _categorizePosts(List<MemoModelPost> allPosts) {
    final newImagePosts = <MemoModelPost>[];
    final newVideoPosts = <MemoModelPost>[];
    final newTaggedPosts = <MemoModelPost>[];
    final newTopicPostsData = <MemoModelPost>[];

    for (var post in allPosts) {
      if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) newImagePosts.add(post);
      if (post.youtubeId != null && post.youtubeId!.isNotEmpty) newVideoPosts.add(post);
      if (post.tagIds.isNotEmpty) newTaggedPosts.add(post);
      if (post.topicId.isNotEmpty) newTopicPostsData.add(post);
    }

    // Clean up YouTube controllers for posts that are no longer in the video list
    _cleanupUnusedYouTubeControllers(newVideoPosts);

    // Only update if lists actually changed
    if (_listsChanged(newImagePosts, newVideoPosts, newTaggedPosts, newTopicPostsData)) {
      setState(() {
        _imagePosts = newImagePosts;
        _videoPosts = newVideoPosts;
        _taggedPosts = newTaggedPosts;
        _topicPostsData = newTopicPostsData;
      });
    }
  }

  bool _listsChanged(
    List<MemoModelPost> newImagePosts,
    List<MemoModelPost> newVideoPosts,
    List<MemoModelPost> newTaggedPosts,
    List<MemoModelPost> newTopicPostsData,
  ) {
    return !_listEquals(newImagePosts, _imagePosts) ||
        !_listEquals(newVideoPosts, _videoPosts) ||
        !_listEquals(newTaggedPosts, _taggedPosts) ||
        !_listEquals(newTopicPostsData, _topicPostsData);
  }

  bool _listEquals(List<MemoModelPost> list1, List<MemoModelPost> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  Widget _buildStatColumn(ThemeData theme, String title, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 2.0),
          child: Text(count, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _onProfileButtonPressed(MemoModelCreator creator) {
    final loggedInUser = ref.read(userProvider);
    final isOwnProfile = loggedInUser?.profileIdMemoBch == creator.id;

    if (isOwnProfile) {
      showProfileSettingsDialog(
        context: context,
        theme: Theme.of(context),
        creator: creator,
        loggedInUser: loggedInUser,
        profileNameCtrl: _profileNameCtrl,
        profileTextCtrl: _profileTextCtrl,
        imgurCtrl: _imgurCtrl,
        isLogoutEnabled: true,
        onSave: () => _saveProfile(creator),
        onBackupMnemonic: () => _showMnemonicBackupDialog(loggedInUser),
        onLogout: () => _logout(ref),
      );
    } else {
      showSnackBar("Follow/Message functionality is coming soon!", context);
    }
  }

  void _showBchQrDialog(MemoModelUser? loggedInUser, ThemeData theme) {
    if (loggedInUser != null) {
      showQrCodeDialog(context: context, theme: theme, user: loggedInUser, getTempToggleState: () => true, setTempToggleState: (_) {});
    } else {
      showSnackBar("User data not available for QR code.", context);
    }
  }

  void _showMnemonicBackupDialog(MemoModelUser? loggedInUser) {
    if (loggedInUser != null) {
      showDialog(
        context: context,
        builder: (ctx) => MnemonicBackupWidget(mnemonic: loggedInUser.mnemonic, onVerificationComplete: () {}),
      );
    }
  }

  void _logout(WidgetRef ref) {
    ref.read(authCheckerProvider).logOut();
    ref.read(profileTargetIdProvider.notifier).state = null;
    ref.read(tabIndexProvider.notifier).setTab(0);
  }

  void _saveProfile(MemoModelCreator creator) async {
    final creatorRepo = ref.read(creatorRepositoryProvider);
    final user = ref.read(userProvider);
    if (user == null) return;

    final newName = _profileNameCtrl.text.trim();
    final newText = _profileTextCtrl.text.trim();
    final newImgurUrl = _imgurCtrl.text.trim();

    final updates = <String, Future<String>>{};
    bool changesMade = false;

    if (newName.isNotEmpty && newName != creator.name) {
      updates['name'] = await creatorRepo.profileSetName(newName, user);
      changesMade = true;
    }
    if (newText != creator.profileText) {
      updates['text'] = await creatorRepo.profileSetText(newText, user);
      changesMade = true;
    }
    if (newImgurUrl.isNotEmpty && newImgurUrl != creator.profileImgurUrl) {
      updates['avatar'] = await creatorRepo.profileSetAvatar(newImgurUrl, user);
      changesMade = true;
    }

    if (!changesMade) {
      showSnackBar("No changes to save. 🤔", context);
      return;
    }

    try {
      final results = await Future.wait(
        updates.entries.map((entry) async {
          final result = await entry.value;
          return MapEntry(entry.key, result);
        }),
      );

      final successfulUpdates = results.where((e) => e.value == "success").map((e) => e.key).toList();
      final failedUpdates = results.where((e) => e.value != "success").map((e) => '${e.key}: ${e.value}').toList();

      if (failedUpdates.isNotEmpty) {
        final failMessage = failedUpdates.join(', ');
        final successMessage = successfulUpdates.isNotEmpty ? ' | Successfully updated: ${successfulUpdates.join(', ')}' : '';
        showSnackBar("Update failed for: $failMessage$successMessage", context);
      } else {
        showSnackBar("Profile updated successfully! ✨", context);
        MemoConfetti().launch(context);
        ref.read(creatorStateProvider.notifier).refreshBalances();
      }
    } catch (e) {
      showSnackBar("Profile update failed: $e", context);
    }
  }
}
