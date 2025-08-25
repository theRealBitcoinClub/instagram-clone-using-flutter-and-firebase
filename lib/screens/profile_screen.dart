import 'package:clipboard/clipboard.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memobase/memo_accountant.dart';
import 'package:mahakka/memomodel/memo_model_creator.dart';
import 'package:mahakka/memomodel/memo_model_post.dart';
import 'package:mahakka/memomodel/memo_model_user.dart';
import 'package:mahakka/memoscraper/memo_creator_service.dart';
import 'package:mahakka/resources/auth_method.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
// import 'package:mahakka/utils/colors.dart'; // REMOVE THIS
import 'package:mahakka/widgets/profile_buttons.dart'; // Assumed themed SettingsButton
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../utils/snackbar.dart'; // Ensure this uses themed SnackBars
import '../views_taggable/widgets/qr_code_dialog.dart';
import '../widgets/textfield_input.dart'; // Ensure this is themed

// Logging placeholders (remain the same)
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileScreen - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

void _logInfo(String message) {
  print('INFO: ProfileScreen - $message');
}

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MemoModelUser? _user;
  MemoModelCreator? _creator;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _showDefaultAvatar = false;
  int _viewMode = 0; // 0: Images, 1: Videos, 2: Hashtags, 4: Topics
  final TextEditingController _profileNameCtrl = TextEditingController();
  final TextEditingController _profileTextCtrl = TextEditingController();
  final TextEditingController _imgurCtrl = TextEditingController();

  final Map<String, YoutubePlayerController> _ytControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    for (var controller in _ytControllers.values) {
      controller.dispose();
    }
    _ytControllers.clear();
    _profileNameCtrl.dispose();
    _profileTextCtrl.dispose();
    _imgurCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    // ... (Your existing data fetching logic remains the same)
    // Ensure showSnackBar calls use context that provides a themed SnackBar.
    if (!mounted) return;
    setState(() {
      _isLoading = _user == null;
      _isRefreshing = true;
    });

    try {
      final localUser = await MemoModelUser.getUser();
      if (!mounted) return;

      final initialCreator = MemoModelCreator.createDummy(id: localUser.profileIdMemoBch);

      setState(() {
        _user = localUser;
        _creator = initialCreator;
        _isLoading = false;
      });

      final results = await Future.wait([
        MemoCreatorService().fetchCreatorDetails(initialCreator, noCache: true),
        localUser.refreshBalanceDevPath145(),
        localUser.refreshBalanceTokens(),
        localUser.refreshBalanceDevPath0(),
      ]);

      if (!mounted) return;

      final refreshedCreator = results[0] as MemoModelCreator;
      final refreshBchStatus = results[1] as String;
      final refreshTokensStatus = results[2] as String;
      final refreshMemoStatus = results[3] as String;

      setState(() {
        _creator = refreshedCreator;
        _isRefreshing = false;
      });

      if (refreshBchStatus != "success" && mounted) {
        showSnackBar("You haz no BCH, please deposit if you want to publish and earn token", context);
      }

      if (refreshTokensStatus != "success" && mounted) {
        showSnackBar("You haz no Tokens, you will miss out on the discount", context);
      }

      if (refreshMemoStatus != "success" && mounted) {
        showSnackBar("You haz no Memo balance, your actions will not tip memo users", context);
      }
    } catch (e, s) {
      _logError("Error in _fetchProfileData", e, s);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        showSnackBar("Failed to load profile data. Please try again.", context);
      }
    }
  }

  Widget _buildStatColumn(ThemeData theme, String title, String count) {
    // Pass Theme
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 2.0),
          child: Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              // color: theme.colorScheme.onSurface, // Inherited by default
            ),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant, // For secondary text
          ),
        ),
      ],
    );
  }

  // No longer needed if using themed IconButtons
  // Color _activeOrNotColor(ThemeData theme, int index) =>
  //     _viewMode == index ? theme.colorScheme.primary : theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Get the current theme
    final ColorScheme colorScheme = theme.colorScheme;

    if (_isLoading) {
      return _buildLoadingScaffold(theme);
    }

    if (_user == null || _creator == null) {
      return _buildErrorScaffold(theme, colorScheme);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme, colorScheme),
      body: SafeArea(
        child: Column(
          children: [
            _buildCollapsibleProfileHeader(theme, colorScheme),
            Container(
              decoration: BoxDecoration(color: theme.colorScheme.surface),
              child: _buildTabSelector(theme),
            ),
            Expanded(child: _buildContentView(theme)), // Pass theme
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      // backgroundColor: theme.appBarTheme.backgroundColor, // From theme
      // foregroundColor: theme.appBarTheme.foregroundColor, // From theme for icons/text
      toolbarHeight: 50,
      centerTitle: false, // As per your original
      title: TextButton(
        onPressed: () {
          //TODO LAUNCH PROFILE ON MEMO WITH THAT ID
          showSnackBar("Launch memo profile URL for ${_user!.profileIdMemoBch}", context);
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero, // Remove default padding for tighter fit
          // foregroundColor: theme.appBarTheme.foregroundColor?.withOpacity(0.8) ?? colorScheme.onPrimary.withOpacity(0.8),
        ),
        child: Text(
          _user!.profileIdMemoBch,
          style: theme.textTheme.bodySmall?.copyWith(
            // Smaller text for ID
            color: (theme.appBarTheme.titleTextStyle?.color ?? colorScheme.onPrimary).withOpacity(0.7), // Subtler color
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.currency_bitcoin_rounded), // Changed icon for clarity
          tooltip: "Deposit BCH",
          // color: theme.appBarTheme.foregroundColor, // From theme
          onPressed: _showBchQRDialog,
        ),
      ],
    );
  }

  Scaffold _buildLoadingScaffold(ThemeData theme) {
    return Scaffold(
      // Add Scaffold for consistent loading screen appearance
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0, // No shadow during loading
      ),
      body: const Center(child: CircularProgressIndicator()), // Progress indicator will use theme color
    );
  }

  Scaffold _buildErrorScaffold(ThemeData theme, ColorScheme colorScheme) {
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
                "Could not load profile data.",
                style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onBackground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: _fetchProfileData,
                // Style will come from theme.elevatedButtonTheme
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Use surface color for the header background
        // Optional: add a subtle border at the bottom
        // border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          _buildTopDetailsRow(theme, colorScheme),
          _buildNameRow(theme),
          _buildProfileText(colorScheme, theme),
          Divider(color: theme.dividerColor, height: 1.0, thickness: 0.5), // Themed divider
        ],
      ),
    );
  }

  Padding _buildTabSelector(ThemeData theme) {
    return Padding(
      // Add padding around the view mode icons
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildViewModeIconButton(theme, 0, Icons.image_outlined, Icons.image_rounded),
          _buildViewModeIconButton(theme, 1, Icons.video_library_outlined, Icons.video_library_rounded),
          _buildViewModeIconButton(theme, 2, Icons.tag_outlined, Icons.tag_rounded), // Using different outline/filled
          _buildViewModeIconButton(theme, 4, Icons.topic_outlined, Icons.topic_rounded),
        ],
      ),
    );
  }

  Padding _buildProfileText(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: _creator!.profileText.trim().isNotEmpty ? 1.0 : 0.0, // Control opacity
          duration: const Duration(milliseconds: 700), // Adjust duration as needed
          child: ExpandableText(
            _creator!.profileText,
            expandText: 'show more',
            collapseText: 'show less',
            maxLines: 3,
            linkColor: colorScheme.primary, // Use primary color for link
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4), // Use themed text style
            linkStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
            prefixStyle: theme.textTheme.bodyMedium, // Ensure prefix style also matches
          ),
        ),
      ),
    );
  }

  Padding _buildNameRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedOpacity(
          opacity: _creator!.profileText.trim().isNotEmpty ? 1.0 : 0.0, // Control opacity
          duration: const Duration(milliseconds: 300), // Adjust duration as needed
          child: Text(_creator!.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTopDetailsRow(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Allow changing profile picture (e.g., show image picker)
              showSnackBar("Change profile picture (Not implemented)", context);
            },
            child: CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.surfaceVariant, // Fallback color
              backgroundImage: _showDefaultAvatar || _user!.profileImage().isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(_user!.profileImage()),
              onBackgroundImageError: _showDefaultAvatar
                  ? null
                  : (exception, stackTrace) {
                      _logError("Error loading profile image", exception, stackTrace);
                      if (mounted) {
                        setState(() => _showDefaultAvatar = true);
                      }
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
                    Expanded(child: _buildStatColumn(theme, 'BCH', _user!.balanceBchDevPath145)),
                    Expanded(child: _buildStatColumn(theme, 'Token', _user!.balanceCashtokensDevPath145)),
                    Expanded(child: _buildStatColumn(theme, 'Memo', _user!.balanceBchDevPath0Memo)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildEditProfileButton(theme), // Pass theme
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(ThemeData theme) {
    // Pass theme
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced horizontal padding
        child: SettingsButton(
          // Assuming SettingsButton is themed (uses OutlinedButton or ElevatedButton style)
          text: 'Edit Profile',
          onPressed: _onProfileSettings,
          // If SettingsButton was refactored like Approach 2 (OutlinedButton style):
          // No direct color props needed here, it picks from theme.outlinedButtonTheme
          // If SettingsButton was refactored like Approach 3 (Custom Themed):
          // You might pass a flag like `isPrimaryAction: false` if it supports it.
        ),
      ),
    );
  }

  Widget _buildViewModeIconButton(ThemeData theme, int index, IconData inactiveIcon, IconData activeIcon) {
    final bool isActive = _viewMode == index;
    return IconButton(
      iconSize: 28, // Adjusted size
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(12), // Consistent padding
      icon: Icon(
        isActive ? activeIcon : inactiveIcon,
        color: isActive ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.7),
      ),
      tooltip: _getViewModeTooltip(index),
      onPressed: () {
        if (mounted) {
          setState(() => _viewMode = index);
        }
      },
    );
  }

  String _getViewModeTooltip(int index) {
    switch (index) {
      case 0:
        return "View Images";
      case 1:
        return "View Videos";
      case 2:
        return "View Tagged Posts";
      case 4:
        return "View Topic Posts";
      default:
        return "View";
    }
  }

  Widget _buildContentView(ThemeData theme) {
    // Pass theme
    // Data lists are assumed to be populated correctly.
    // Ensure MemoModelPost instances have data or handle nulls gracefully.

    Widget emptyView(String message) {
      return Center(
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
      );
    }

    switch (_viewMode) {
      case 0: // Grid View (Images)
        final posts = MemoModelPost.imgurPosts;
        if (posts.isEmpty) return emptyView("No image posts yet.");
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Adjust for screen size if needed
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            Widget imagePlaceholder = Container(
              color: theme.colorScheme.surfaceVariant,
              child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
            );

            if (post.imgurUrl == null || post.imgurUrl!.isEmpty) {
              return imagePlaceholder;
            }

            final img = Image.network(
              post.imgurUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // ImgurUtils.errorLoadImage should ideally return a themed widget
                _logError("Error loading grid image: ${post.imgurUrl}", error, stackTrace);
                return imagePlaceholder;
              },
              loadingBuilder: (context, child, loadingProgress) {
                // ImgurUtils.loadingImage should ideally return a themed widget
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
              onDoubleTap: () =>
                  _showPostDialog(theme, post, AspectRatio(aspectRatio: 1, child: img)), // Pass theme & wrapped image
              child: AspectRatio(aspectRatio: 1, child: img), // Ensure square grid items
            );
          },
        );
      case 1: // YouTube Videos
        final posts = MemoModelPost.ytPosts;
        if (posts.isEmpty) return emptyView("No video posts yet.");
        return _buildYouTubeListView(theme, posts); // Pass theme
      case 2: // Hashtag Posts
        final posts = MemoModelPost.hashTagPosts;
        if (posts.isEmpty) return emptyView("No tagged posts yet.");
        return _buildGenericPostListView(theme, posts); // Pass theme
      case 4: // Topic Posts
        final posts = MemoModelPost.topicPosts;
        if (posts.isEmpty) return emptyView("No topic posts yet.");
        return _buildGenericPostListView(theme, posts); // Pass theme
      default:
        return emptyView("Select a view mode.");
    }
  }

  void _showPostDialog(ThemeData theme, MemoModelPost post, Widget imageWidget) {
    // Pass theme
    if (post.creator == null) {
      showSnackBar("Cannot show post details: Creator data missing.", context);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return SimpleDialog(
          // Uses theme.dialogTheme for shape, backgroundColor, titleTextStyle, contentTextStyle
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: post.creator!.profileImage().isEmpty
                    ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                    : NetworkImage(post.creator!.profileImage()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  post.creator!.name,
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
                child: ExpandableText(
                  post.text!,
                  expandText: 'show more',
                  collapseText: 'show less',
                  maxLines: 4,
                  linkColor: theme.colorScheme.primary,
                  style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium,
                  linkStyle: (theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium)?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildYouTubeListView(ThemeData theme, List<MemoModelPost> posts) {
    // Pass theme
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final ytPost = posts[index];
        if (ytPost.youtubeId == null || ytPost.youtubeId!.isEmpty) {
          return const SizedBox.shrink();
        }

        YoutubePlayerController controller = _ytControllers.putIfAbsent(
          ytPost.youtubeId!,
          () => YoutubePlayerController(
            initialVideoId: ytPost.youtubeId!,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: true, // Start muted for feed UX
              hideControls: false,
              hideThumbnail: false,
            ),
          ),
        );

        return Card(
          // margin uses theme.cardTheme.margin or default
          // elevation uses theme.cardTheme.elevation
          // shape uses theme.cardTheme.shape
          // color uses theme.cardTheme.color
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(0), // Player can be edge-to-edge in card
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: theme.colorScheme.primary, // Themed
                  progressColors: ProgressBarColors(
                    // Themed
                    playedColor: theme.colorScheme.primary,
                    handleColor: theme.colorScheme.secondary,
                    bufferedColor: theme.colorScheme.primary.withOpacity(0.4),
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                Padding(
                  // Add padding for text content below video
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
                          linkStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Divider(color: theme.dividerColor),
                      Text(
                        "Posted by: ${ytPost.creator?.name ?? 'Unknown'}",
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenericPostListView(ThemeData theme, List<MemoModelPost> posts) {
    // Pass theme
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.creator?.name ?? 'Unknown',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.created ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 8),
                ExpandableText(
                  post.text ?? 'No content.',
                  expandText: 'show more',
                  collapseText: 'show less',
                  maxLines: 5,
                  linkColor: theme.colorScheme.primary,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  linkStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onProfileSettings() {
    final ThemeData theme = Theme.of(context); // Get theme for dialog

    showDialog(
      context: context,
      builder: (ctxDialog) {
        return SimpleDialog(
          // titlePadding will be from theme.dialogTheme or default
          // shape from theme.dialogTheme
          // backgroundColor from theme.dialogTheme
          title: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: theme.dialogTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Text("PROFILE SETTINGS", style: theme.dialogTheme.titleTextStyle ?? theme.textTheme.titleLarge),
            ],
          ),
          children: [
            _buildSettingsInput(theme, Icons.badge_outlined, "Satoshi Nakamoto", TextInputType.text, _profileNameCtrl),
            _buildSettingsInput(
              theme,
              Icons.notes_outlined,
              "I am a Sci-Fi Ponk",
              TextInputType.text,
              _profileTextCtrl,
            ),
            _buildSettingsInput(
              theme,
              Icons.account_circle_outlined,
              "e.g. http://i.imgur.com/JF983F.png",
              TextInputType.url,
              _imgurCtrl,
            ),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 0, horizontal: 24),
              child: ElevatedButton(
                onPressed: () {
                  if (_hasInputData()) {
                    _saveProfile(ctxDialog);
                  }
                },
                child: Text("SAVE"),
              ),
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
              AuthChecker().logOut(context);
            }),
          ],
        );
      },
    );
  }

  Widget _buildSettingsInput(ThemeData theme, IconData icon, String hintText, type, TextEditingController ctrl) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 15),
          Expanded(
            child: TextInputField(hintText: hintText, textEditingController: ctrl, textInputType: type),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(
    ThemeData theme,
    IconData icon,
    String text,
    BuildContext dialogCtx,
    VoidCallback onSelect,
  ) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      onPressed: () {
        Navigator.of(dialogCtx).pop();
        onSelect();
      },
      child: Row(
        children: [
          Icon(icon, color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 15),
          Text(text, style: theme.textTheme.bodyLarge /*?.copyWith(color: theme.colorScheme.onSurface)*/),
        ],
      ),
    );
  }

  void _showBchQRDialog() {
    final ThemeData theme = Theme.of(context);
    if (_user == null) {
      showSnackBar("User data not available for QR code.", context);
      return;
    }
    // QrCodeDialog should be refactored to be theme-aware.
    // For now, it will inherit ambient theme.
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return QrCodeDialog(
          user: _user!,
          initialToggleState: _tempToggleAddressTypeForDialog,
          onToggle: (newState) {
            if (mounted) {
              setState(() {
                _tempToggleAddressTypeForDialog = newState;
              });
            }
          },
          // You might need to pass theme explicitly if QrCodeDialog cannot use Theme.of(context) effectively
          // theme: theme,
        );
      },
    );
  }

  bool _tempToggleAddressTypeForDialog = true; // State for QR dialog toggle

  Future<void> _copyToClipboard(String text, String successMessage) async {
    // ... (logic remains the same, showSnackBar should be themed)
    if (text.isEmpty) {
      showSnackBar("Nothing to copy.", context);
      return;
    }
    await FlutterClipboard.copyWithCallback(
      text: text,
      onSuccess: () {
        if (mounted) showSnackBar(successMessage, context);
      },
      onError: (error) {
        _logError("Copy to clipboard failed", error);
        if (mounted) showSnackBar('Copy failed. See logs for details.', context);
      },
    );
  }

  bool _hasInputData() {
    return _profileNameCtrl.text.trim().isNotEmpty ||
        _profileTextCtrl.text.trim().isNotEmpty ||
        _imgurCtrl.text.trim().isNotEmpty;
    ;
  }

  void _saveProfile(dialogCtc) async {
    var name = _profileNameCtrl.text.trim();
    if (name.isNotEmpty) await MemoAccountant(_user!).profileSetName(name);

    var text = _profileTextCtrl.text.trim();
    if (text.isNotEmpty) await MemoAccountant(_user!).profileSetText(text);

    var imgur = _imgurCtrl.text.trim();
    if (imgur.isNotEmpty) await MemoAccountant(_user!).profileSetAvatar(imgur);

    _user = await MemoModelUser.getUser();
    setState(() {
      if (dialogCtc.mounted) {
        MemoConfetti().launch(context);
        Navigator.of(dialogCtc).pop();
      }
    });
  }
}
