import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/scraper/memo_creator_service.dart';
import 'package:mahakka/provider/navigation_providers.dart';
// Assuming you might have a userProvider for the logged-in user's data (optional for now)
// import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/resources/auth_method.dart'; // For authCheckerProvider
import 'package:mahakka/sliver_app_bar_delegate.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// clipboard and url_launcher might be used by dialog helpers now
// import 'package:clipboard/clipboard.dart';
// import 'package:url_launcher/url_launcher.dart';

// Import the new sub-widget files
import 'profile_app_bar.dart';
import 'profile_content_grid.dart';
import 'profile_content_list.dart';
import 'profile_dialog_helpers.dart'; // Will contain dialog logic
import 'profile_header.dart';
import 'profile_placeholders.dart'; // For loading/error UI
import 'profile_tab_selector.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileScreenWidget - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileScreenWidget extends ConsumerStatefulWidget {
  const ProfileScreenWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreenWidget> createState() => _ProfileScreenWidgetState();
}

class _ProfileScreenWidgetState extends ConsumerState<ProfileScreenWidget> with TickerProviderStateMixin {
  // Services
  final PostService _postService = PostService();
  final CreatorService _creatorService = CreatorService(); // Keep for _saveProfile
  final MemoCreatorService _memoCreatorService = MemoCreatorService(); // Keep for fetch

  // Profile Data
  MemoModelUser? _loggedInUser; // Current logged-in user (from MemoModelUser.getUser())
  MemoModelCreator? _displayedCreator; // The creator whose profile is being displayed
  String? _currentProfileIdBeingViewed; // To track the ID being loaded/viewed

  // Loading States
  bool _isLoadingProfile = true; // For initial profile data
  bool _isRefreshingProfile = false; // For profile refresh (pull-to-refresh)

  // View Mode
  int _viewMode = 0; // 0: Images, 1: Videos, 2: Tagged, 4: Topics

  // Text Controllers for Edit Profile Dialog
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();

  // YouTube Player Controllers
  // Use ValueNotifier to allow ProfileContentList to manage disposal if necessary
  final Map<String, ValueNotifier<YoutubePlayerController?>> _ytControllerNotifiers = {};

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();

  // Post Data
  Stream<List<MemoModelPost>>? _profilePostsStream;
  List<MemoModelPost> _allProfilePosts = [];
  List<MemoModelPost> _imagePosts = [];
  List<MemoModelPost> _videoPosts = [];
  List<MemoModelPost> _taggedPosts = []; // Posts with one or more tags
  List<MemoModelPost> _topicPostsData = []; // Posts associated with any topic

  bool _showDefaultAvatar = false; // State for avatar fallback
  bool _tempToggleAddressTypeForDialog = true; // For QR Dialog

  @override
  void initState() {
    super.initState();
    // Load logged-in user first, then determine which profile to fetch.
    _initializeProfileScreen();
  }

  Future<void> _initializeProfileScreen() async {
    _loggedInUser = await MemoModelUser.getUser(); // Your existing way to get logged-in user
    if (mounted) {
      setState(() {}); // Update UI with _loggedInUser availability

      final initialTargetId = ref.read(profileTargetIdProvider);
      final String profileIdToLoad = initialTargetId ?? _loggedInUser?.profileIdMemoBch ?? "";

      if (profileIdToLoad.isNotEmpty) {
        _fetchProfileDataAndInitPostsStream(profileIdToLoad);
      } else {
        // This case should ideally not happen if a user is logged in or a target is set.
        _logError("ProfileScreen Init: Cannot determine profile to load.");
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
            _displayedCreator = null; // Will trigger error scaffold
          });
        }
      }
    }
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
    // This now iterates over ValueNotifiers and disposes their controllers
    for (var notifier in _ytControllerNotifiers.values) {
      notifier.value?.pause();
      notifier.value?.dispose();
      notifier.value = null; // Clear the controller from notifier
    }
    _ytControllerNotifiers.clear(); // Clear the map
  }

  bool get isOwnProfile {
    if (_loggedInUser == null || _displayedCreator == null) return false;
    // Your original logic for determining own profile
    return _loggedInUser!.profileIdMemoBch == _displayedCreator!.id;
  }

  // Kept your original logic for _fetchProfileDataAndInitPostsStream as much as possible
  Future<void> _fetchProfileDataAndInitPostsStream(String profileIdToLoad) async {
    if (!mounted || profileIdToLoad.isEmpty) {
      if (profileIdToLoad.isEmpty) _logError("Fetch Profile: Attempted with empty profileIdToLoad.");
      return;
    }

    // Prevent re-fetch if already loading this exact ID and not a refresh action
    if (profileIdToLoad == _currentProfileIdBeingViewed && !_isRefreshingProfile && _isLoadingProfile) {
      _logError("Fetch Profile: Already in progress for $profileIdToLoad.");
      return;
    }
    _logError("Fetch Profile: Starting for $profileIdToLoad. Current view: $_currentProfileIdBeingViewed");

    setState(() {
      // Set isLoadingProfile true only if it's a new profile or if _displayedCreator is null
      _isLoadingProfile = _displayedCreator == null || _displayedCreator!.id != profileIdToLoad;
      _isRefreshingProfile = true; // Mark as refreshing since a fetch operation is starting

      if (_isLoadingProfile) {
        // Full reset for a new profile
        _currentProfileIdBeingViewed = profileIdToLoad; // Update the ID being viewed
        _allProfilePosts = [];
        _imagePosts = [];
        _videoPosts = [];
        _taggedPosts = [];
        _topicPostsData = [];
        _profilePostsStream = null;
        _showDefaultAvatar = false;
        _disposeYouTubeControllers(); // Dispose controllers from previous profile
      }
    });

    try {
      // _loggedInUser should be loaded by _initializeProfileScreen or subsequent state updates
      _loggedInUser ??= await MemoModelUser.getUser();
      if (!mounted) return;

      // Your original logic for getting creator
      MemoModelCreator? initialCreator = await _creatorService.getCreatorOnce(profileIdToLoad);
      initialCreator ??= MemoModelCreator(id: profileIdToLoad); // Fallback as in original

      if (!mounted) return;
      setState(() {
        _displayedCreator = initialCreator;
        _isLoadingProfile = false; // Skeleton is loaded
      });

      if (_displayedCreator == null || _displayedCreator!.id.isEmpty) {
        _logError("Failed to load initial creator data for ID: $profileIdToLoad");
        if (mounted) {
          showSnackBar("Could not load profile details. Creator not found.", context);
          setState(() {
            _isRefreshingProfile = false;
            _displayedCreator = null;
          });
        }
        return;
      }

      // Initialize posts stream now that we have the creator ID
      _initializeProfilePostsStream(_displayedCreator!.id);
      if (mounted) setState(() {}); // To make StreamBuilder pick up the new stream

      _displayedCreator!.refreshAvatar(); // Assuming this is non-critical for UI render

      // Fetch further details in parallel - your original Future.wait logic
      final results = await Future.wait([
        _memoCreatorService.fetchCreatorDetails(_displayedCreator!, noCache: true),
        if (isOwnProfile && _loggedInUser != null) _loggedInUser!.refreshBalanceDevPath145(),
        if (isOwnProfile && _loggedInUser != null) _loggedInUser!.refreshBalanceTokens(),
        if (isOwnProfile && _loggedInUser != null) _loggedInUser!.refreshBalanceDevPath0(),
      ]);

      if (!mounted) return;

      MemoModelCreator refreshedCreator = results[0] as MemoModelCreator;
      // TODO: update user details store them on firebase (if MemoCreatorService().fetchCreatorDetails also returns user updatable info)
      await _creatorService.saveCreator(refreshedCreator); // Save potentially updated creator info

      if (isOwnProfile) {
        // Your original snackbar logic for balance checks
        if (results.length > 1) {
          // Ensure results are present
          String refreshBchStatus = results[1] as String;
          String refreshTokensStatus = results[2] as String;
          String refreshMemoStatus = results[3] as String;
          if (refreshBchStatus != "success" && mounted) {
            showSnackBar("You haz no BCH...", context);
          }
          if (refreshTokensStatus != "success" && mounted) {
            showSnackBar("You haz no Tokens...", context);
          }
          if (refreshMemoStatus != "success" && mounted) {
            showSnackBar("You haz no Memo balance...", context);
          }
        }
      }

      setState(() {
        _displayedCreator = refreshedCreator; // Update with fully refreshed details
        _isRefreshingProfile = false;
      });
    } catch (e, s) {
      _logError("Error in _fetchProfileDataAndInitPostsStream for $profileIdToLoad", e, s);
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isRefreshingProfile = false;
          // If creator fetch failed badly, set to null to show error scaffold
          if (_displayedCreator?.id != profileIdToLoad) _displayedCreator = null;
        });
        showSnackBar("Failed to load profile data. Please try again.", context);
      }
    }
  }

  void _initializeProfilePostsStream(String creatorId) {
    if (creatorId.isEmpty) {
      _logError("Cannot initialize posts stream: Creator ID is empty.");
      if (mounted) setState(() => _profilePostsStream = Stream.value([]));
      return;
    }
    _logError("Initializing posts stream for creator ID: $creatorId");
    if (mounted) {
      setState(() {
        _profilePostsStream = _postService.getPostsByCreatorIdStream(creatorId);
      });
    }
  }

  void _categorizePosts(List<MemoModelPost> allPosts) {
    if (!mounted) return;

    // _disposeYouTubeControllers(); // Consider if this is needed here or managed by ProfileContentList

    final newImagePosts = <MemoModelPost>[];
    final newVideoPosts = <MemoModelPost>[];
    final newTaggedPosts = <MemoModelPost>[];
    final newTopicPostsData = <MemoModelPost>[];

    for (var post in allPosts) {
      // Your original categorization logic
      if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) newImagePosts.add(post);
      if (post.youtubeId != null && post.youtubeId!.isNotEmpty) newVideoPosts.add(post);
      if (post.tagIds.isNotEmpty) newTaggedPosts.add(post);
      if (post.topicId.isNotEmpty) newTopicPostsData.add(post);
    }

    // Only update if lists have actually changed to prevent unnecessary rebuilds
    bool changed =
        _allProfilePosts.length != allPosts.length ||
        !listEquals(_imagePosts, newImagePosts) ||
        !listEquals(_videoPosts, newVideoPosts) ||
        !listEquals(_taggedPosts, newTaggedPosts) ||
        !listEquals(_topicPostsData, newTopicPostsData);

    if (changed) {
      setState(() {
        _allProfilePosts = allPosts;
        _imagePosts = newImagePosts;
        _videoPosts = newVideoPosts;
        _taggedPosts = newTaggedPosts;
        _topicPostsData = newTopicPostsData;
      });
    }
  }

  // Helper for listEquals
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false; // This works for simple types, for objects use == override or custom compare
    }
    return true;
  }

  Widget _buildStatColumn(ThemeData theme, String title, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 2.0),
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // Listen to changes in profileTargetIdProvider to switch profiles
    ref.listen<String?>(profileTargetIdProvider, (previousTargetId, newTargetId) {
      final String? effectiveTargetId = newTargetId ?? _loggedInUser?.profileIdMemoBch;
      if (effectiveTargetId != null && effectiveTargetId.isNotEmpty && effectiveTargetId != _currentProfileIdBeingViewed) {
        _fetchProfileDataAndInitPostsStream(effectiveTargetId);
      } else if (newTargetId == null && _loggedInUser != null && _loggedInUser!.profileIdMemoBch != _currentProfileIdBeingViewed) {
        // Explicitly go to own profile if target becomes null and we are not already there
        _fetchProfileDataAndInitPostsStream(_loggedInUser!.profileIdMemoBch);
      }
    });

    // If still loading the very first time and no displayedCreator yet
    if (_isLoadingProfile && _displayedCreator == null) {
      return ProfileLoadingScaffold(theme: theme, message: "Loading Profile...");
    }

    // If fetching failed and we have no displayedCreator
    if (_displayedCreator == null || _displayedCreator!.id.isEmpty) {
      return ProfileErrorScaffold(
        theme: theme,
        colorScheme: colorScheme,
        message: "Profile not found or an error occurred.",
        onRetry: () {
          // Attempt to re-initialize the profile screen's data fetching
          _initializeProfileScreen();
        },
      );
    }
    // At this point, _displayedCreator is guaranteed to be non-null.
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ProfileAppBar(
        creator: _displayedCreator,
        isOwnProfile: isOwnProfile,
        onShowBchQrDialog: () {
          if (_loggedInUser != null) {
            showBchQRDialog(
              // From profile_dialog_helpers.dart
              context: context,
              theme: theme,
              user: _loggedInUser!,
              getTempToggleState: () => _tempToggleAddressTypeForDialog,
              setTempToggleState: (val) => setState(() => _tempToggleAddressTypeForDialog = val),
            );
          } else {
            showSnackBar("User data not available for QR code.", context);
          }
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchProfileDataAndInitPostsStream(_displayedCreator!.id),
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  creator: _displayedCreator!,
                  loggedInUser: _loggedInUser,
                  isOwnProfile: isOwnProfile,
                  isRefreshingProfile: _isRefreshingProfile,
                  onProfileButtonPressed: _onProfileButtonPressed,
                  showImageDetail: () => showCreatorImageDetail(
                    context,
                    theme,
                    _displayedCreator!,
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
                  child: ProfileTabSelector(
                    viewMode: _viewMode,
                    onViewModeChanged: (newMode) {
                      if (mounted) setState(() => _viewMode = newMode);
                    },
                  ),
                ),
                pinned: true,
              ),
              _buildSliverContentStreamView(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContentStreamView(ThemeData theme) {
    if (_displayedCreator == null || _profilePostsStream == null) {
      // This case should be rare if _isLoadingProfile and _isRefreshingProfile are handled correctly
      // in the main build method.
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: (_isLoadingProfile || _isRefreshingProfile)
              ? const CircularProgressIndicator()
              : Text("Loading content...", style: theme.textTheme.titleMedium),
        ),
      );
    }
    return StreamBuilder<List<MemoModelPost>>(
      stream: _profilePostsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logError("Error in profile posts stream", snapshot.error, snapshot.stackTrace);
          return EmptySliverContent(message: 'Error loading posts. ${snapshot.error}', theme: theme, icon: Icons.error_outline);
        }

        if (snapshot.connectionState == ConnectionState.waiting && _allProfilePosts.isEmpty) {
          // Show loading only if it's the absolute first load for this stream.
          return const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _categorizePosts(snapshot.data!);
          });
        } else if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasData && _allProfilePosts.isNotEmpty) {
          // Stream ended or emitted null, and we had data, so clear it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _categorizePosts([]);
          });
        }
        // Always build with the current categorized lists.
        // _categorizePosts (called via addPostFrameCallback) will update these lists
        // and trigger a rebuild for the *next* frame if data actually changed.
        return _buildSliverCategorizedView(theme);
      },
    );
  }

  Widget _buildSliverCategorizedView(ThemeData theme) {
    switch (_viewMode) {
      case 0: // Grid View (Images)
        return ProfileContentGrid(
          posts: _imagePosts,
          onPostImageTap: (post, imageWidget) => showPostDialog(
            context: context,
            theme: theme,
            post: post,
            creator: _displayedCreator,
            // Pass the currently displayed creator
            imageWidget: imageWidget,
          ),
        );
      case 1: // YouTube Videos
        return ProfileContentList.youTube(
          posts: _videoPosts,
          ytControllerNotifiers: _ytControllerNotifiers,
          creatorName: _displayedCreator?.name ?? "Creator",
        );
      case 2: // Tagged Posts
        return ProfileContentList.generic(posts: _taggedPosts, creatorName: _displayedCreator?.name ?? "Creator");
      case 4: // Topic Posts
        return ProfileContentList.generic(posts: _topicPostsData, creatorName: _displayedCreator?.name ?? "Creator");
      default:
        return EmptySliverContent(message: "Select a view to see posts.", theme: theme);
    }
  }

  // --- Action Callbacks ---
  void _onProfileButtonPressed() {
    if (_displayedCreator == null) return;

    if (isOwnProfile) {
      // Use the helper from profile_dialog_helpers.dart
      showProfileSettingsDialog(
        context: context,
        theme: Theme.of(context),
        creator: _displayedCreator!,
        loggedInUser: _loggedInUser,
        profileNameCtrl: _profileNameCtrl,
        profileTextCtrl: _profileTextCtrl,
        imgurCtrl: _imgurCtrl,
        onSave: _saveProfile,
        // Pass the state method for saving
        onLogout: () {
          // Original logout logic
          final authChecker = ref.read(authCheckerProvider);
          authChecker
              .logOut()
              .then((result) {
                if (result == "success" && mounted) {
                  // Navigation to AuthPage is usually handled by a top-level listener on auth state
                  // Forcing a clear of target here:
                  ref.read(profileTargetIdProvider.notifier).state = null;
                } else if (mounted) {
                  showSnackBar("Logout failed: $result", context);
                }
              })
              .catchError((e) {
                if (mounted) showSnackBar("Logout error: $e", context);
              });
        },
        onBackupMnemonic: () {
          // Original backup logic
          if (_loggedInUser?.mnemonic != null && _loggedInUser!.mnemonic.isNotEmpty) {
            copyToClipboard(_loggedInUser!.mnemonic, "Mnemonic copied!", context);
          } else {
            showSnackBar("Mnemonic not available.", context);
          }
        },
      );
    } else {
      // Placeholder for Follow/Message functionality
      showSnackBar("Follow/Message functionality is coming soon!", context);
    }
  }

  // _saveProfile logic as per your original, called by the dialog
  void _saveProfile() async {
    // Removed dialogContext parameter
    if (_displayedCreator == null || _loggedInUser == null || !isOwnProfile) {
      // Added !isOwnProfile
      showSnackBar("User or Creator data missing, or not authorized. Cannot save.", context);
      return; // Return early
    }

    bool changed = false;
    String newName = _profileNameCtrl.text.trim();
    String newText = _profileTextCtrl.text.trim();
    String newImgurUrl = _imgurCtrl.text.trim();

    // Create a mutable copy or update directly if your model allows
    // For this example, assuming direct update is fine and will be saved.
    // The key is that _displayedCreator is the source of truth for current values.

    if (newName.isNotEmpty && newName != _displayedCreator!.name) {
      // await MemoAccountant(_loggedInUser!).profileSetName(newName); // Your original backend call
      _displayedCreator!.name = newName; // Local update for UI, will be saved by CreatorService
      changed = true;
    }
    if (newText != _displayedCreator!.profileText) {
      // Check includes setting empty text
      // await MemoAccountant(_loggedInUser!).profileSetText(newText);
      _displayedCreator!.profileText = newText;
      changed = true;
    }
    if (newImgurUrl != _displayedCreator!.profileImageAvatar()) {
      // Check includes setting empty URL
      //TODO check this accountant sync data in background on dialog close?
      // await MemoAccountant(_loggedInUser!).profileSetAvatar(newImgurUrl);
      // _displayedCreator!.setProfileImageAvatar(newImgurUrl); // Assuming a setter or way to update this
      // For simplicity, if profileImageAvatar is a direct field or you have a map:
      // _displayedCreator!.profileImgurUrl = newImgurUrl; // Adjust if field name is different
      changed = true;
    }

    if (changed) {
      if (mounted) setState(() => _isRefreshingProfile = true); // Show loading
      try {
        await _creatorService.saveCreator(_displayedCreator!); // Save the updated _displayedCreator
        if (mounted) {
          MemoConfetti().launch(context);
          showSnackBar("Profile updated!", context);
          // Trigger a full refresh to get the latest from everywhere
          // and ensure consistency if backend made further changes.
          _fetchProfileDataAndInitPostsStream(_displayedCreator!.id); // This already sets _isRefreshingProfile = false
        }
      } catch (e, s) {
        _logError("Error saving profile via CreatorService", e, s);
        if (mounted) {
          showSnackBar("Failed to save profile changes.", context);
          setState(() => _isRefreshingProfile = false); // Stop loading on error
        }
      }
    } else {
      if (mounted) {
        showSnackBar("No changes to save.", context);
        // Ensure loading indicator stops if no changes were made and save wasn't attempted.
        // However, saveProfile is typically called after user interaction, so dialog closes itself.
        // If saveProfile was called programmatically and might not have changes, then:
        // setState(() => _isRefreshingProfile = false);
      }
    }
    // Dialog that called this will handle its own dismissal.
  }
}
