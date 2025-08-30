import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/profile_providers.dart'; // New
import 'package:mahakka/sliver_app_bar_delegate.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/bch/mnemonic_backup_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../repositories/creator_repository.dart'; // Import the repository
// Import the new sub-widget files
import '../../resources/auth_method.dart';
import 'profile_app_bar.dart';
import 'profile_content_grid.dart';
import 'profile_content_list.dart';
import 'profile_dialog_helpers.dart';
import 'profile_header.dart';
import 'profile_placeholders.dart';
import 'profile_tab_selector.dart';

// Remove the old service imports and state variables
// No need for a global _logError function in Riverpod as it can be handled locally or with a logger provider

class ProfileScreenWidget extends ConsumerStatefulWidget {
  const ProfileScreenWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreenWidget> createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends ConsumerState<ProfileScreenWidget> with TickerProviderStateMixin {
  // All data fetching is now handled by Riverpod providers
  // Local state for UI and controllers
  int _viewMode = 0;
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();
  final Map<String, ValueNotifier<YoutubePlayerController?>> _ytControllerNotifiers = {};
  final ScrollController _scrollController = ScrollController();

  // Local lists to hold categorized post data
  List<MemoModelPost> _allProfilePosts = [];
  List<MemoModelPost> _imagePosts = [];
  List<MemoModelPost> _videoPosts = [];
  List<MemoModelPost> _taggedPosts = [];
  List<MemoModelPost> _topicPostsData = [];

  bool _showDefaultAvatar = false;
  bool _tempToggleAddressTypeForDialog = true;
  bool _hasBackedUpMnemonic = false;

  // Local state to hold the currently viewed profile ID
  late String _currentProfileId;

  @override
  void initState() {
    super.initState();
    // Use the logged-in user or the target ID from the navigation provider
    final loggedInUser = ref.read(userProvider);
    _currentProfileId = ref.read(profileTargetIdProvider) ?? loggedInUser?.profileIdMemoBch ?? '';
  }

  @override
  void dispose() {
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
    }
    _ytControllerNotifiers.clear();
  }

  bool get isOwnProfile {
    final loggedInUser = ref.read(userProvider);
    return loggedInUser?.profileIdMemoBch == _currentProfileId;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final loggedInUser = ref.watch(userProvider);

    // Watch the creator and posts providers for the current profile ID
    final creatorAsyncValue = ref.watch(creatorStateProvider(_currentProfileId));
    final postsAsyncValue = ref.watch(postsStreamProvider(_currentProfileId));

    // Listen to changes in the navigation provider to switch profiles
    ref.listen<String?>(profileTargetIdProvider, (previousId, newId) {
      if (newId != null && newId != _currentProfileId) {
        setState(() {
          _currentProfileId = newId;
          _allProfilePosts = []; // Clear old data to show loading state
          _disposeYouTubeControllers();
        });
      }
    });

    // Use .when() on the AsyncValue to build the UI based on the state
    return creatorAsyncValue.when(
      data: (creator) {
        if (creator == null) {
          return ProfileErrorScaffold(
            theme: theme,
            colorScheme: colorScheme,
            message: "Profile not found or an error occurred.",
            onRetry: () => ref.refresh(creatorStateProvider(_currentProfileId)),
          );
        }
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: ProfileAppBar(
            creator: creator,
            isOwnProfile: isOwnProfile,
            onShowBchQrDialog: () {
              if (loggedInUser != null) {
                showBchQRDialog(
                  context: context,
                  theme: theme,
                  user: loggedInUser,
                  getTempToggleState: () => _tempToggleAddressTypeForDialog,
                  setTempToggleState: (val) => setState(() => _tempToggleAddressTypeForDialog = val),
                );
              } else {
                showSnackBar("User data not available for QR code.", context);
              }
            },
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.refresh(creatorStateProvider(_currentProfileId));
              ref.refresh(postsStreamProvider(_currentProfileId));
            },
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeader(
                    creator: creator,
                    loggedInUser: loggedInUser,
                    isOwnProfile: isOwnProfile,
                    isRefreshingProfile: creatorAsyncValue.isLoading,
                    onProfileButtonPressed: () => _onProfileButtonPressed(creator),
                    showImageDetail: () => showCreatorImageDetail(
                      context,
                      theme,
                      creator,
                      () => _showDefaultAvatar,
                      (val) => setState(() => _showDefaultAvatar = val),
                    ),
                    buildStatColumn: _buildStatColumn,
                    showDefaultAvatar: _showDefaultAvatar,
                  ),
                ),
                SliverPersistentHeader(
                  delegate: SliverAppBarDelegate(
                    minHeight: 60,
                    maxHeight: 60,
                    child: ProfileTabSelector(viewMode: _viewMode, onViewModeChanged: (newMode) => setState(() => _viewMode = newMode)),
                  ),
                  pinned: true,
                ),
                _buildSliverContentStreamView(theme, postsAsyncValue),
              ],
            ),
          ),
        );
      },
      loading: () => ProfileLoadingScaffold(theme: theme, message: "Loading Profile..."),
      error: (error, stack) => ProfileErrorScaffold(
        theme: theme,
        colorScheme: colorScheme,
        message: "Error loading profile: $error",
        onRetry: () => ref.refresh(creatorStateProvider(_currentProfileId)),
      ),
    );
  }

  // This method now takes the posts AsyncValue as an argument
  Widget _buildSliverContentStreamView(ThemeData theme, AsyncValue<List<MemoModelPost>> postsAsyncValue) {
    return postsAsyncValue.when(
      data: (posts) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _categorizePosts(posts);
        });
        return _buildSliverCategorizedView(theme);
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

  Widget _buildSliverCategorizedView(ThemeData theme) {
    switch (_viewMode) {
      case 0: // Grid View (Images)
        return ProfileContentGrid(
          posts: _imagePosts,
          onPostImageTap: (post, imageWidget) =>
              showPostDialog(context: context, theme: theme, post: post, creator: null, imageWidget: imageWidget),
        );
      case 1: // YouTube Videos
        return ProfileContentList.youTube(posts: _videoPosts, ytControllerNotifiers: _ytControllerNotifiers, creatorName: "Creator");
      case 2: // Tagged Posts
        return ProfileContentList.generic(posts: _taggedPosts, creatorName: "Creator");
      case 4: // Topic Posts
        return ProfileContentList.generic(posts: _topicPostsData, creatorName: "Creator");
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

    // Only update if lists have actually changed to prevent unnecessary rebuilds
    if (_allProfilePosts.length != allPosts.length) {
      setState(() {
        _allProfilePosts = allPosts;
        _imagePosts = newImagePosts;
        _videoPosts = newVideoPosts;
        _taggedPosts = newTaggedPosts;
        _topicPostsData = newTopicPostsData;
      });
    }
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
    if (isOwnProfile) {
      showProfileSettingsDialog(
        context: context,
        theme: Theme.of(context),
        creator: creator,
        loggedInUser: loggedInUser,
        profileNameCtrl: _profileNameCtrl..text = creator.name ?? '',
        profileTextCtrl: _profileTextCtrl..text = creator.profileText ?? '',
        imgurCtrl: _imgurCtrl..text = creator.profileImageAvatar() ?? '',
        isLogoutEnabled: _hasBackedUpMnemonic,
        onSave: () => _saveProfile(creator),
        onBackupMnemonic: () {
          showDialog(
            context: context,
            builder: (ctx) => MnemonicBackupWidget(
              mnemonic: loggedInUser!.mnemonic,
              onVerificationComplete: () => setState(() => _hasBackedUpMnemonic = true),
            ),
          );
        },
        onLogout: () {
          ref.read(authCheckerProvider).logOut();
          ref.read(profileTargetIdProvider.notifier).state = null;
          ref.read(tabIndexProvider.notifier).setTab(0);
        },
      );
    } else {
      showSnackBar("Follow/Message functionality is coming soon!", context);
    }
  }

  void _saveProfile(MemoModelCreator creator) async {
    final creatorRepo = ref.read(creatorRepositoryProvider);
    bool changed = false;
    String newName = _profileNameCtrl.text.trim();
    String newText = _profileTextCtrl.text.trim();
    String newImgurUrl = _imgurCtrl.text.trim();

    if (newName.isNotEmpty && newName != creator.name) {
      creator.name = newName;
      changed = true;
    }
    if (newText != creator.profileText) {
      creator.profileText = newText;
      changed = true;
    }
    // Logic for updating the avatar
    if (newImgurUrl != creator.profileImageAvatar() && newImgurUrl.isNotEmpty) {
      // Assuming your MemoModelCreator has a way to update this
      // e.g., creator.profileImgurUrl = newImgurUrl;
      // You'll need to adapt this part based on your model's implementation.
      changed = true;
    }

    // Call the repository to save the changes
    if (changed) {
      await creatorRepo.saveCreator(creator);
      if (mounted) {
        showSnackBar("Profile updated!", context);
        MemoConfetti().launch(context);
        // Refresh the provider to show the updated data
        ref.refresh(creatorStateProvider(creator.id));
      }
    } else {
      if (mounted) showSnackBar("No changes to save.", context);
    }
  }
}
