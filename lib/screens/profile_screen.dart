// [1]
import 'package:clipboard/clipboard.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
// Assuming you have PostService, adjust the import path
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/scraper/memo_creator_service.dart';
import 'package:mahakka/resources/auth_method.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:mahakka/widgets/profile_buttons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../sliver_app_bar_delegate.dart';
import '../utils/snackbar.dart';
import '../views_taggable/widgets/qr_code_dialog.dart';
import '../widgets/textfield_input.dart';
// Import your PostCard if you intend to reuse it for displaying posts,
// otherwise, you'll build the UI directly as in your original _buildGenericPostListView etc.
// import 'package:mahakka/widgets/post_card.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileScreen - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Services
  final PostService _postService = PostService(); // Add PostService instance

  // Profile Data
  MemoModelUser? _user;
  MemoModelCreator? _creator;

  // Loading States
  bool _isLoadingProfile = true; // For initial profile data
  bool _isRefreshingProfile = false; // For profile refresh
  // Note: Post loading state will be handled by StreamBuilder

  // View Mode
  int _viewMode = 0; // 0: Images, 1: Videos, 2: Tagged, 4: Topics

  // Text Controllers for Edit Profile Dialog
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();

  // YouTube Player Controllers
  final Map<String, YoutubePlayerController> _ytControllers = {};

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();

  // Post Data
  Stream<List<MemoModelPost>>? _profilePostsStream;
  List<MemoModelPost> _allProfilePosts = [];
  List<MemoModelPost> _imagePosts = [];
  List<MemoModelPost> _videoPosts = [];
  List<MemoModelPost> _taggedPosts = []; // Posts with one or more tags
  List<MemoModelPost> _topicPostsData = []; // Posts associated with any topic

  bool _showDefaultAvatar = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileDataAndInitPostsStream();
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
    for (var controller in _ytControllers.values) {
      controller.dispose();
    }
    _ytControllers.clear();
  }

  bool get isOwnProfile {
    if (_user == null || _creator == null) return false;
    return _user!.profileIdMemoBch == _creator!.id;
  }

  Future<void> _fetchProfileDataAndInitPostsStream() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = _user == null; // Only true initial loading
      _isRefreshingProfile = true;
    });

    try {
      final localUser = await MemoModelUser.getUser();
      if (!mounted) return;

      String profileIdOfCreatorOrUser = MemoModelUser.profileIdGet(localUser);
      MemoModelCreator? initialCreator = await CreatorService().getCreatorOnce(profileIdOfCreatorOrUser);
      //TODO the user wanted to check his own profile but the profile is new and doesnt exist on firebase
      initialCreator ??= MemoModelCreator(id: profileIdOfCreatorOrUser);

      if (!mounted) return;
      setState(() {
        _user = localUser;
        _creator = initialCreator;
        _isLoadingProfile = false; // Profile skeleton loaded
      });

      if (_creator == null) {
        _logError("Failed to load initial creator data for ID: $profileIdOfCreatorOrUser");
        if (mounted) {
          showSnackBar("Could not load profile details. Creator not found.", context);
          setState(() {
            _isRefreshingProfile = false;
          });
        }
        return;
      }

      // Initialize posts stream now that we have the creator ID
      _initializeProfilePostsStream(_creator!.id);
      if (mounted) setState(() {}); // To make StreamBuilder pick up the new stream

      _creator!.refreshAvatar(); // Assuming this is non-critical for UI render

      // Fetch further details in parallel
      final results = await Future.wait([
        MemoCreatorService().fetchCreatorDetails(_creator!, noCache: true),
        if (isOwnProfile) localUser.refreshBalanceDevPath145(),
        if (isOwnProfile) localUser.refreshBalanceTokens(),
        if (isOwnProfile) localUser.refreshBalanceDevPath0(),
      ]);

      if (!mounted) return;

      MemoModelCreator refreshedCreator = results[0] as MemoModelCreator;
      // TODO: update user details store them on firebase (if MemoCreatorService().fetchCreatorDetails also returns user updatable info)
      await CreatorService().saveCreator(refreshedCreator); // Save potentially updated creator info

      if (isOwnProfile) {
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

      setState(() {
        _creator = refreshedCreator; // Update with fully refreshed details
        _isRefreshingProfile = false;
      });
    } catch (e, s) {
      _logError("Error in _fetchProfileDataAndInitPostsStream", e, s);
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isRefreshingProfile = false;
        });
        showSnackBar("Failed to load profile data. Please try again.", context);
      }
    }
  }

  void _initializeProfilePostsStream(String creatorId) {
    if (creatorId.isEmpty) {
      _logError("Cannot initialize posts stream: Creator ID is empty.");
      setState(() {
        _profilePostsStream = Stream.value([]); // Emit empty list if no ID
      });
      return;
    }
    _logError("Initializing posts stream for creator ID: $creatorId");
    setState(() {
      // Assuming PostService has a method to get posts by creatorId
      // and order them, e.g., by createdDateTime descending
      _profilePostsStream = _postService.getPostsByCreatorIdStream(
        creatorId,
        orderByField: 'createdDateTime', // Make sure this field exists on your posts
        descending: true,
      );
    });
  }

  void _categorizePosts(List<MemoModelPost> allPosts) {
    if (!mounted) return;

    // Clear existing YT controllers before categorizing,
    // as the video posts list will be repopulated.
    _disposeYouTubeControllers();

    final newImagePosts = <MemoModelPost>[];
    final newVideoPosts = <MemoModelPost>[];
    final newTaggedPosts = <MemoModelPost>[];
    final newTopicPostsData = <MemoModelPost>[];

    for (var post in allPosts) {
      // Ensure creator data is attempted to be loaded if not present
      // This is important if your post display logic relies on post.creator.name etc.
      if (post.creator == null && post.creatorId.isNotEmpty) {
        // Asynchronously refresh. The UI for individual posts will handle loading state.
        post.creator = MemoModelCreator(id: post.creatorId);
        post.creator!.refreshCreatorFirebase();
      }

      if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) {
        newImagePosts.add(post);
      }
      if (post.youtubeId != null && post.youtubeId!.isNotEmpty) {
        newVideoPosts.add(post);
      }
      // Assuming tagIds is the correct field from Firestore
      if (post.tagIds.isNotEmpty) {
        newTaggedPosts.add(post);
      }
      // Assuming topicId is the correct field from Firestore
      if (post.topicId.isNotEmpty) {
        newTopicPostsData.add(post);
      }
    }

    setState(() {
      _allProfilePosts = allPosts; // Keep the full list
      _imagePosts = newImagePosts;
      _videoPosts = newVideoPosts;
      _taggedPosts = newTaggedPosts;
      _topicPostsData = newTopicPostsData;
    });
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

    if (_isLoadingProfile) {
      return _buildLoadingScaffold(theme, "Loading Profile...");
    }

    if (_creator == null) {
      // Changed from _user == null || _creator == null
      // This state means initial creator fetch failed or creatorId was invalid.
      return _buildErrorScaffold(theme, colorScheme, "Profile not found or failed to load.");
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme, colorScheme),
      body: SafeArea(
        child: RefreshIndicator(
          // Added RefreshIndicator
          onRefresh: _fetchProfileDataAndInitPostsStream,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildCollapsibleProfileHeader(theme, colorScheme)),
              SliverPersistentHeader(
                delegate: SliverAppBarDelegate(minHeight: 60, maxHeight: 60, child: _buildTabSelector(theme)),
                pinned: true,
              ),
              _buildSliverContentStreamView(theme), // Switched to stream-based content view
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      toolbarHeight: 40,
      centerTitle: false,
      title: TextButton(
        onPressed: () {
          if (_creator?.id != null && _creator!.id.isNotEmpty) {
            launchUrl(Uri.parse("https://memo.cash/profile/${_creator!.id}"));
          }
        },
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          _creator?.id ?? "Loading ID...",
          style: theme.textTheme.bodySmall?.copyWith(
            color: (theme.appBarTheme.titleTextStyle?.color ?? colorScheme.onPrimary).withOpacity(0.7),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        if (isOwnProfile) // Only show deposit if it's own profile
          IconButton(icon: const Icon(Icons.currency_bitcoin_rounded), tooltip: "Deposit BCH", onPressed: _showBchQRDialog),
      ],
    );
  }

  Scaffold _buildLoadingScaffold(ThemeData theme, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: theme.appBarTheme.backgroundColor, elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Scaffold _buildErrorScaffold(ThemeData theme, ColorScheme colorScheme, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Profile Error", style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onBackground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text("Retry"), onPressed: _fetchProfileDataAndInitPostsStream),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    // Ensure _creator is not null before accessing its properties
    if (_creator == null) {
      return const SizedBox.shrink(); // Or a placeholder
    }
    return Container(
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRefreshingProfile) const LinearProgressIndicator(minHeight: 2),
          _buildTopDetailsRow(theme, colorScheme),
          _buildNameRow(theme),
          _buildProfileText(colorScheme, theme),
          Divider(color: theme.dividerColor, height: 1.0, thickness: 0.5),
        ],
      ),
    );
  }

  Padding _buildTabSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildViewModeIconButton(theme, 0, Icons.image_outlined, Icons.image_rounded),
          _buildViewModeIconButton(theme, 1, Icons.video_library_outlined, Icons.video_library_rounded),
          _buildViewModeIconButton(theme, 2, Icons.tag_outlined, Icons.tag_rounded),
          _buildViewModeIconButton(theme, 4, Icons.topic_outlined, Icons.topic_rounded),
        ],
      ),
    );
  }

  Widget _buildSliverContentStreamView(ThemeData theme) {
    // This StreamBuilder will listen for posts related to the _creator.
    // Ensure _profilePostsStream is initialized when _creator data is available.
    if (_creator == null || _profilePostsStream == null) {
      // If creator isn't loaded yet, or stream isn't ready, show a loading indicator or placeholder
      // This case should ideally be minimal if _initializeProfilePostsStream is called promptly.
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: _creator == null
              ? Text("Loading creator data...", style: theme.textTheme.titleMedium)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Loading posts...", style: theme.textTheme.titleMedium),
                  ],
                ),
        ),
      );
    }
    return StreamBuilder<List<MemoModelPost>>(
      stream: _profilePostsStream,
      builder: (context, snapshot) {
        // Handle connection states and errors first, returning appropriate slivers
        if (snapshot.hasError) {
          _logError("Error in profile posts stream", snapshot.error, snapshot.stackTrace);
          return SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('Error loading posts. ${snapshot.error}')));
        }

        if (snapshot.connectionState == ConnectionState.waiting && _allProfilePosts.isEmpty) {
          return const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()));
        }

        // If we have new data from the stream
        if (snapshot.hasData) {
          // Schedule the state update for after the current build frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Check if the widget is still in the tree
              _categorizePosts(snapshot.data!); // This will call setState
            }
          });
        } else if (snapshot.connectionState != ConnectionState.waiting && !snapshot.hasData && _allProfilePosts.isNotEmpty) {
          // Stream might have emitted null or closed, and we had previous data. Clear it.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _categorizePosts([]);
            }
          });
        }

        // Always build the view with the current categorized lists.
        // _categorizePosts (called via addPostFrameCallback) will update these lists
        // and trigger a rebuild for the *next* frame.
        return _buildSliverCategorizedView(theme);
      },
    );
  }

  Widget _buildSliverCategorizedView(ThemeData theme) {
    // This method now uses the categorized lists (_imagePosts, _videoPosts, etc.)
    // which are updated by the StreamBuilder.
    Widget emptySliver(String message) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers_clear_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(message, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      );
    }

    switch (_viewMode) {
      case 0: // Grid View (Images)
        if (_imagePosts.isEmpty) return emptySliver("No image posts by this creator yet.");
        return SliverPadding(
          padding: const EdgeInsets.all(4),
          sliver: SliverGrid.builder(
            itemCount: _imagePosts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
            itemBuilder: (context, index) {
              final post = _imagePosts[index];
              Widget imagePlaceholder = Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
              );
              if (post.imgurUrl == null || post.imgurUrl!.isEmpty) return imagePlaceholder;

              final img = Image.network(
                post.imgurUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  _logError("Error loading grid image: ${post.imgurUrl}", error, stackTrace);
                  return imagePlaceholder;
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              );
              return GestureDetector(
                onDoubleTap: () => _showPostDialog(theme, post, AspectRatio(aspectRatio: 1, child: img)),
                child: AspectRatio(aspectRatio: 1, child: img),
              );
            },
          ),
        );
      case 1: // YouTube Videos
        if (_videoPosts.isEmpty) return emptySliver("No video posts by this creator yet.");
        return _buildYouTubeListView(theme, _videoPosts);
      case 2: // Tagged Posts
        if (_taggedPosts.isEmpty) return emptySliver("No posts with tags by this creator yet.");
        return _buildGenericPostListView(theme, _taggedPosts);
      case 4: // Topic Posts
        if (_topicPostsData.isEmpty) return emptySliver("No posts in topics by this creator yet.");
        return _buildGenericPostListView(theme, _topicPostsData);
      default:
        return emptySliver("Select a view mode.");
    }
  }

  // --- Methods that remain largely the same but use instance fields or themed elements ---
  // (e.g., _buildProfileText, _buildNameRow, _buildTopDetailsRow, showImageDetail,
  // _buildEditProfileButton, _buildViewModeIconButton, _getViewModeTooltip,
  // _showPostDialog, _buildYouTubeListView, _buildGenericPostListView,
  // _onProfileSettings, _buildSettingsInput, _buildSettingsOption,
  // _showBchQRDialog, _copyToClipboard, _hasInputData, _saveProfile)
  // Ensure they correctly handle _creator being potentially null before it's fully loaded,
  // or rely on data that is confirmed to be present.

  Padding _buildProfileText(ColorScheme colorScheme, ThemeData theme) {
    final profileText = _creator?.profileText ?? "";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: profileText.trim().isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 700),
          child: ExpandableText(
            profileText,
            expandText: 'show more',
            collapseText: 'show less',
            maxLines: 3,
            linkColor: colorScheme.primary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            linkStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
            prefixStyle: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  Padding _buildNameRow(ThemeData theme) {
    final creatorName = _creator?.name ?? "Loading name...";
    final creatorProfileIdShort = _creator?.profileIdShort ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: creatorName != "Loading name..." ? 1.0 : 0.7,
          duration: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Text(creatorName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (creatorProfileIdShort.isNotEmpty)
                Text(" $creatorProfileIdShort", style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 2.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopDetailsRow(ThemeData theme, ColorScheme colorScheme) {
    // Ensure _creator and _user are not null for certain parts
    final creatorProfileImg = _creator?.profileImageAvatar() ?? "";
    final balanceBch = _user?.balanceBchDevPath145 ?? "0";
    final balanceTokens = _user?.balanceCashtokensDevPath145 ?? "0";
    final balanceMemo = _user?.balanceBchDevPath0Memo ?? "0";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_creator != null) showImageDetail(colorScheme);
            },
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceVariant,
              backgroundImage: _showDefaultAvatar || creatorProfileImg.isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(creatorProfileImg),
              onBackgroundImageError: _showDefaultAvatar
                  ? null
                  : (exception, stackTrace) {
                      _logError("Error loading profile image", exception, stackTrace);
                      if (mounted) setState(() => _showDefaultAvatar = true);
                    },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: isOwnProfile
                          ? _buildStatColumn(theme, 'BCH', balanceBch)
                          : SizedBox(
                              child: Center(child: Text("Followers: ${_creator?.followerCount ?? 0}", style: theme.textTheme.bodyMedium)),
                            ),
                    ), // Example for non-own profile
                    Expanded(
                      child: isOwnProfile
                          ? _buildStatColumn(theme, 'Token', balanceTokens)
                          : SizedBox(
                              child: Center(child: Text("Last seen: ${_creator?.lastActionDate ?? 0}", style: theme.textTheme.bodyMedium)),
                            ),
                    ), // Example for non-own profile
                    Expanded(child: isOwnProfile ? _buildStatColumn(theme, 'Memo', balanceMemo) : SizedBox()),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEditProfileButton(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showImageDetail(ColorScheme colorScheme) async {
    if (_creator == null) return;
    bool hasDetail = await _creator!.refreshDetailScraper(); // Assuming this is defined in MemoModelCreator

    if (hasDetail && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(10),
            children: [
              CircleAvatar(
                radius: 130,
                backgroundColor: colorScheme.surfaceVariant,
                backgroundImage: _showDefaultAvatar || _creator!.profileImageDetail().isEmpty
                    ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                    : NetworkImage(_creator!.profileImageDetail()),
                onBackgroundImageError: _showDefaultAvatar
                    ? null
                    : (exception, stackTrace) {
                        _logError("Error loading profile image detail", exception, stackTrace);
                        if (mounted) setState(() => _showDefaultAvatar = true);
                      },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildEditProfileButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: SettingsButton(
          text: !isOwnProfile ? (false ? "Unfollow" : "Follow") : 'Edit Profile', // Example for follow/unfollow
          onPressed: _onProfileButtonPressed,
        ),
      ),
    );
  }

  void _onProfileButtonPressed() {
    if (isOwnProfile) {
      _onProfileSettings();
    } else {
      // Handle Follow/Unfollow logic
      _toggleFollowStatus();
    }
  }

  void _toggleFollowStatus() async {
    // if (_creator == null || _user == null) return;
    // // For simplicity, directly toggling a local state and calling an action.
    // // In a real app, this would involve API calls.
    // final bool currentlyFollowing = _creator!.isFollowing; // Assuming isFollowing exists on MemoModelCreator
    // print("Toggle follow for ${_creator!.id}. Currently following: $currentlyFollowing");
    //
    // // Placeholder for actual follow/unfollow logic
    // // await UserService().toggleFollow(_user!.id, _creator!.id, !currentlyFollowing);
    //
    // if (mounted) {
    //   setState(() {
    //     _creator!.isFollowing = !currentlyFollowing; // Update local state for immediate UI feedback
    //   });
    //   showSnackBar(!currentlyFollowing ? "Followed ${_creator!.name}" : "Unfollowed ${_creator!.name}", context);
    // }
  }

  Widget _buildViewModeIconButton(ThemeData theme, int index, IconData inactiveIcon, IconData activeIcon) {
    final bool isActive = _viewMode == index;
    return IconButton(
      iconSize: 28,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(12),
      icon: Icon(isActive ? activeIcon : inactiveIcon, color: isActive ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.7)),
      tooltip: _getViewModeTooltip(index),
      onPressed: () {
        if (mounted) setState(() => _viewMode = index);
      },
    );
  }

  String _getViewModeTooltip(int index) {
    switch (index) {
      case 0:
        return "Images";
      case 1:
        return "Videos";
      case 2:
        return "Tagged Posts";
      case 4:
        return "Topic Posts";
      default:
        return "Empty";
    }
  }

  void _showPostDialog(ThemeData theme, MemoModelPost post, Widget imageWidget) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return SimpleDialog(
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: _creator?.profileImageAvatar().isEmpty ?? true
                    ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                    : NetworkImage(_creator!.profileImageAvatar()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _creator?.name ?? post.creatorId, // Fallback to creatorId if name not loaded
                  style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: imageWidget),
            if (post.text != null && post.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(post.text!),
                // ExpandableText(
                //   post.text!,
                //   expandText: 'show more',
                //   collapseText: 'show less',
                //   maxLines: 4,
                //   linkColor: theme.colorScheme.primary,
                //   style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium,
                //   linkStyle: (theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium)?.copyWith(
                //     color: theme.colorScheme.primary,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildYouTubeListView(ThemeData theme, List<MemoModelPost> posts) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(childCount: posts.length, (context, index) {
        final ytPost = posts[index];
        if (ytPost.youtubeId == null || ytPost.youtubeId!.isEmpty) return const SizedBox.shrink();

        // Ensure controller is created or reconfigured if necessary
        YoutubePlayerController controller = _ytControllers.putIfAbsent(
          ytPost.id, // Use post.id as key for YT controller for uniqueness
          () => YoutubePlayerController(
            initialVideoId: ytPost.youtubeId!,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: true, hideControls: false, hideThumbnail: false),
          ),
        );
        // This simple putIfAbsent might not be enough if videoId within the same post.id changes.
        // For profile view, this is usually fine.

        // final _creatorName = ytPost.creatorSync?.name ?? ytPost.creatorId; // Fallback
        // final _creatorName = "fallback" + ytPost.creatorId;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YoutubePlayer(
                  // key: ValueKey("ytpost_" + ytPost.id),
                  controller: controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: theme.colorScheme.primary,
                  progressColors: ProgressBarColors(
                    playedColor: theme.colorScheme.primary,
                    handleColor: theme.colorScheme.secondary,
                    bufferedColor: theme.colorScheme.primary.withOpacity(0.4),
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ytPost.text != null && ytPost.text!.isNotEmpty) ...[
                        ExpandableText(
                          ytPost.text!,
                          expandText: 'show more',
                          collapseText: 'show less',
                          maxLines: 3,
                          linkColor: theme.colorScheme.primary,
                          style: theme.textTheme.bodyMedium,
                          linkStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        "Posted by: ${_creator!.name}",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      // Text("Posted by: $_creatorName", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGenericPostListView(ThemeData theme, List<MemoModelPost> posts) {
    // Assuming _creator is available in the scope of this widget, e.g., from _ProfileScreenState
    // If not, you'd need to get creator info from 'post.creator' and handle its loading state.
    // For this example, let's use the _creator from _ProfileScreenState for the header.
    // Ensure _creator is not null before accessing its properties.

    final String? creatorCreatedDate = _creator?.created;
    // if (_creator?.createdDateTime !=
    //     null) { // Assuming MemoModelCreator has createdDateTime
    //   creatorCreatedDate =
    //       DateFormat('MMM d, yyyy').format(_creator!.createdDateTime!);
    // } else if (_creator?.created != null &&
    //     _creator!.created!.isNotEmpty) { // Fallback to string if available
    //   creatorCreatedDate = _creator!.created;
    // } else {
    //   creatorCreatedDate = null;
    // }

    return SliverList(
      delegate: SliverChildBuilderDelegate(childCount: posts.length, (context, index) {
        final post = posts[index];
        final String postCreatorName = _creator!.name;
        // final String postCreatorName = "dsfdsf";
        // post.creator?.name ?? _creator?.name ?? post.creatorId; // Use post's creator first, then screen's _creator, then ID
        final String postTimestamp = "dsfdsf${post.created}";
        // post.createdDateTime != null
        //     ? DateFormat('MMM d, yyyy HH:mm').format(post.createdDateTime!) // More detailed post timestamp
        //     : (post.created ?? post.age ?? '');

        return Card(
          elevation: 2.0,
          // Add a bit of elevation for a nicer look
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          // Rounded corners
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          // Adjusted margin
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Enhanced Header ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Optional: Creator Avatar (if available and desired)
                    // if (post.creator?.profileImageAvatar().isNotEmpty ?? _creator?.profileImageAvatar().isNotEmpty ?? false)
                    //   Padding(
                    //     padding: const EdgeInsets.only(right: 12.0),
                    //     child: CircleAvatar(
                    //       radius: 20,
                    //       backgroundImage: NetworkImage(
                    //         post.creator?.profileImageAvatar() ?? _creator!.profileImageAvatar()
                    //       ),
                    //       backgroundColor: theme.colorScheme.surfaceVariant,
                    //     ),
                    //   ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            postCreatorName,
                            // Use the specific post's creator name if available
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (creatorCreatedDate != null &&
                              post.creator == null) // Show overall creator join date if post.creator isn't detailed
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                'Creator since: $creatorCreatedDate',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      postTimestamp, // Use the post's own created/age string
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11, // Slightly smaller for timestamp
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(color: theme.dividerColor.withOpacity(0.5), height: 1),
                // Thinner divider
                const SizedBox(height: 12),

                // --- Colorized Text Content ---
                ExpandableText(
                  post.text ?? " ",
                  expandText: 'show more',
                  collapseText: 'show less',
                  maxLines: 5,
                  linkColor: theme.colorScheme.primary.withOpacity(0.85), // For "show more/less"
                  style: theme.textTheme.bodyMedium?.copyWith(
                    // Default style for the main text
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9), // Slightly softer main text
                  ),
                  linkStyle: theme.textTheme.bodyMedium?.copyWith(
                    // Style for "show more/less" text
                    color: theme.colorScheme.primary.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),

                  // --- Hashtag Styling and Tap Handling ---
                  hashtagStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary, // Use secondary color for hashtags
                    fontWeight: FontWeight.w600,
                  ),
                  onHashtagTap: (String hashtag) {
                    print('Hashtag tapped: $hashtag');
                    // TODO: Implement your navigation or action for hashtag taps
                    // For example:
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => HashtagScreen(hashtag: hashtag)));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped on hashtag: $hashtag')));
                  },

                  // --- URL Styling and Tap Handling ---
                  urlStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.70), // Primary color with desired opacity
                    decoration: TextDecoration.underline,
                    decorationColor: theme.colorScheme.primary.withOpacity(0.5), // Underline color also with opacity
                  ),
                  onUrlTap: (String url) async {
                    print('URL tapped: $url');
                    Uri? uri = Uri.tryParse(url);
                    if (uri != null) {
                      // Attempt to add scheme if missing (e.g., for "www.example.com")
                      if (!uri.hasScheme && (url.startsWith('www.') || RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(url))) {
                        uri = Uri.parse('http://$url');
                      }
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          print('Could not launch $uri');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $url')));
                          }
                        }
                      } catch (e) {
                        print('Error launching URL $url: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: $url')));
                        }
                      }
                    } else {
                      print('Invalid URL: $url');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid link format: $url')));
                      }
                    }
                  },

                  // --- Prefix for Topic ID ---
                  prefixText: post.topicId.isNotEmpty ? "Topic: ${post.topicId}\n" : null,
                  prefixStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                  onPrefixTap: () {
                    print("Topic prefix tapped: ${post.topicId}");
                    // TODO: Handle topic tap if needed, e.g., navigate to a topic screen
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped on topic: ${post.topicId}')));
                  },
                ),

                // --- Optional: Display Topic ID Separately if not prefixed ---
                // if (post.topicId.isNotEmpty) ...[
                //   const SizedBox(height: 10),
                //   Row(
                //     children: [
                //       Icon(Icons.topic_outlined, size: 16, color: theme.colorScheme.tertiary.withOpacity(0.8)),
                //       const SizedBox(width: 6),
                //       Text(
                //         "Topic: ${post.topicId}",
                //         style: theme.textTheme.bodySmall?.copyWith(
                //             color: theme.colorScheme.tertiary.withOpacity(0.9),
                //             fontWeight: FontWeight.w500
                //         ),
                //       ),
                //     ],
                //   ),
                // ],
              ],
            ),
          ),
        );
      }),
    );
  }

  void _onProfileSettings() {
    final ThemeData theme = Theme.of(context);
    _profileNameCtrl.text = _creator?.name ?? '';
    _profileTextCtrl.text = _creator?.profileText ?? '';
    _imgurCtrl.text = _creator?.profileImageAvatar() ?? ''; // Or a specific field for avatar URL input

    showDialog(
      context: context,
      builder: (ctxDialog) {
        return SimpleDialog(
          title: Row(
            children: [
              Icon(Icons.settings_outlined, color: theme.dialogTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface),
              const SizedBox(width: 10),
              Text("PROFILE SETTINGS", style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge),
            ],
          ),
          children: [
            _buildSettingsInput(theme, Icons.badge_outlined, "Display Name", TextInputType.text, _profileNameCtrl),
            _buildSettingsInput(theme, Icons.notes_outlined, "Profile Bio/Text", TextInputType.multiline, _profileTextCtrl),
            _buildSettingsInput(theme, Icons.account_circle_outlined, "Avatar Image URL (e.g. Imgur)", TextInputType.url, _imgurCtrl),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
              child: ElevatedButton(onPressed: () => _saveProfile(ctxDialog), child: Text("SAVE")),
            ),
            Divider(color: theme.dividerColor, height: 20, thickness: 0.5),
            _buildSettingsOption(theme, Icons.vpn_key_outlined, "BACKUP MNEMONIC", ctxDialog, () {
              if (_user?.mnemonic != null && _user!.mnemonic.isNotEmpty) {
                _copyToClipboard(_user!.mnemonic, "Mnemonic copied!");
              } else {
                showSnackBar("Mnemonic not available.", context);
              }
            }),
            _buildSettingsOption(theme, Icons.logout, "LOGOUT", ctxDialog, () {
              AuthChecker().logOut(context); // Assuming this navigates away
            }),
          ],
        );
      },
    );
  }

  Widget _buildSettingsInput(ThemeData theme, IconData icon, String hintText, TextInputType type, TextEditingController ctrl) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Adjusted padding
      child: Row(
        children: [
          Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 15),
          Expanded(
            child: TextInputField(
              hintText: hintText,
              textEditingController: ctrl,
              textInputType: type,
              //TODO check this maxline
              // maxLines: type == TextInputType.multiline ? 3 : 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(ThemeData theme, IconData icon, String text, BuildContext dialogCtx, VoidCallback onSelect) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      onPressed: () {
        Navigator.of(dialogCtx).pop(); // Close dialog first
        onSelect(); // Then execute action
      },
      child: Row(
        children: [
          Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 15),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  bool _tempToggleAddressTypeForDialog = true;
  void _showBchQRDialog() {
    if (_user == null) {
      showSnackBar("User data not available for QR code.", context);
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return QrCodeDialog(
          user: _user!,
          initialToggleState: _tempToggleAddressTypeForDialog,
          onToggle: (newState) {
            // This setState is for the dialog's internal state if it rebuilds based on this toggle.
            // If the dialog manages its own state for the toggle, this might not be needed here.
            if (mounted) setState(() => _tempToggleAddressTypeForDialog = newState);
          },
        );
      },
    );
  }

  Future<void> _copyToClipboard(String text, String successMessage) async {
    if (text.isEmpty) {
      showSnackBar("Nothing to copy.", context);
      return;
    }
    try {
      await FlutterClipboard.copy(text);
      if (mounted) showSnackBar(successMessage, context);
    } catch (e) {
      _logError("Copy to clipboard failed", e);
      if (mounted) showSnackBar('Copy failed: $e', context);
    }
  }

  // _hasInputData removed as save is always enabled, validation/changes are checked in _saveProfile

  void _saveProfile(BuildContext dialogContext) async {
    if (_creator == null || _user == null) {
      showSnackBar("User or Creator data missing. Cannot save.", context);
      Navigator.of(dialogContext).pop();
      return;
    }

    bool changed = false;
    String newName = _profileNameCtrl.text.trim();
    String newText = _profileTextCtrl.text.trim();
    String newImgurUrl = _imgurCtrl.text.trim();

    // Update MemoModelCreator instance locally first for immediate UI reflection if desired
    // This is optional, as _fetchProfileDataAndInitPostsStream will re-fetch
    if (newName.isNotEmpty && newName != _creator!.name) {
      // await MemoAccountant(_user!).profileSetName(newName); // Call backend
      _creator!.name = newName; // Local update
      changed = true;
    }
    if (newText.isNotEmpty && newText != _creator!.profileText) {
      // await MemoAccountant(_user!).profileSetText(newText);
      _creator!.profileText = newText;
      changed = true;
    }
    if (newImgurUrl.isNotEmpty && newImgurUrl != _creator!.profileImageAvatar()) {
      //TODO check this accountant sync data in background on dialog close?
      // await MemoAccountant(_user!).profileSetAvatar(newImgurUrl);
      // _creator!.setProfileImageAvatar(newImgurUrl); // Assuming a setter or way to update this
      changed = true;
    }

    if (changed) {
      try {
        await CreatorService().saveCreator(_creator!); // Save the updated _creator to Firestore
        if (mounted) {
          MemoConfetti().launch(context);
          showSnackBar("Profile updated!", context);
          // Trigger a full refresh to get the latest from everywhere
          // and ensure consistency if backend made further changes.
          _fetchProfileDataAndInitPostsStream();
        }
      } catch (e) {
        _logError("Error saving profile via CreatorService", e);
        if (mounted) showSnackBar("Failed to save profile changes.", context);
      }
    } else {
      if (mounted) showSnackBar("No changes to save.", context);
    }
    if (Navigator.canPop(dialogContext)) {
      // Check if dialog is still open
      Navigator.of(dialogContext).pop();
    }
  }
}
