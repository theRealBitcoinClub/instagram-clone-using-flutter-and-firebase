import 'package:clipboard/clipboard.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/memoscraper/memo_creator_service.dart'; // Assuming this service exists
import 'package:instagram_clone1/resources/auth_method.dart'; // Assuming AuthChecker is here
import 'package:instagram_clone1/utils/colors.dart'; // Your color definitions
import 'package:instagram_clone1/widgets/profile_buttons.dart'; // For SettingsButton
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../utils/imgur_utils.dart'; // Your Imgur utilities
import '../utils/snackbar.dart';
import '../views_taggable//widgets/qr_code_dialog.dart'; // Your showSnackBar utility

// Basic logging placeholders (replace with a proper logger if needed)
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

void _logInfo(String message) {
  print('INFO: $message');
}

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MemoModelUser? _user;
  MemoModelCreator? _creator; // Made nullable for initial state

  bool _isLoading = true; // Start with loading true
  bool _isRefreshing = false;
  bool _showDefaultAvatar = false;
  int _viewMode = 0;

  // For YouTube Player Controllers
  final Map<String, YoutubePlayerController> _ytControllers = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  @override
  void dispose() {
    // Dispose all YouTube controllers
    for (var controller in _ytControllers.values) {
      controller.dispose();
    }
    _ytControllers.clear();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = _user == null; // Show main loader only if no user data yet
      _isRefreshing = true;
    });

    try {
      final localUser = await MemoModelUser.getUser(); // Assuming this fetches the current user
      if (!mounted) return;

      // Initial dummy creator for faster UI response if needed
      final initialCreator = MemoModelCreator.createDummy(id: localUser.profileIdMemoBch);

      setState(() {
        _user = localUser;
        _creator = initialCreator;
        _isLoading = false; // Stop initial loading
        // _isRefreshing can remain true if we are about to fetch more
      });

      // Perform subsequent fetches, potentially in parallel
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

      // Show SnackBars after final state update
      if (refreshBchStatus != "success" && mounted) {
        showSnackBar("You haz no BCH, please deposit if you want to publish and earn token", context);
      }
      if (refreshTokensStatus != "success" && mounted) {
        showSnackBar("You haz no tokens, deposit tokens to post/like/reply with discount", context);
      }
      if (refreshMemoStatus != "success" && mounted) {
        showSnackBar("You haz no memo balance, likes/replies of OG memo posts will not send tips", context);
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

  Widget _buildStatColumn(String title, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.grey),
        ),
      ],
    );
  }

  Color _activeOrNotColor(int index) => _viewMode == index ? Colors.grey.shade800 : Colors.grey.shade500;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_user == null || _creator == null) {
      // Handle state where user or creator is null after loading (should ideally not happen if _fetchProfileData is robust)
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Could not load profile data."),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _fetchProfileData, child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: TextButton(
          onPressed: () {
            //TODO LAUNCH PROFILE ON MEMO WITH THAT ID
            showSnackBar("Launch memo profile URL or register on memo if 404 on profile", context);
          },
          child: Text(
            _user!.profileIdMemoBch,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showBchQRDialog,
            icon: const Icon(Icons.currency_exchange, color: blackColor),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          // Removed MainAxisSize.min, let it fill available space if needed, or use SingleChildScrollView
          children: [
            if (_isRefreshing) const SizedBox(height: 1, child: LinearProgressIndicator()),
            _buildProfileHeader(),
            Expanded(child: _buildContentView()), // Use Expanded for scrollable content
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    // This part is relatively static once data is loaded,
    // could be a separate widget if it gets too complex.
    return Container(
      // Consider a fixed height or make it intrinsic based on content
      // height: 265, // Original fixed height
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min, // To fit content
        children: [
          _buildTopDetailsRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(_creator!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ExpandableText(
                _creator!.profileText,
                expandText: 'show more',
                collapseText: 'show less',
                maxLines: 3,
                linkColor: Colors.blue,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const Divider(color: Colors.grey /*.shade300*/), // Simpler color
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Use spaceEvenly for better distribution
            children: [
              _buildViewModeIconButton(0, Icons.image_rounded),
              _buildViewModeIconButton(1, Icons.video_library_rounded),
              _buildViewModeIconButton(2, Icons.tag_rounded),
              _buildViewModeIconButton(4, Icons.topic),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopDetailsRow() {
    return Padding(
      padding: const EdgeInsets.all(16).copyWith(top: 8, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Allow changing profile picture
            },
            child: CircleAvatar(
              radius: 40,
              backgroundImage: _showDefaultAvatar || _user!.profileImage().isEmpty
                  ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                  : NetworkImage(_user!.profileImage()),
              onBackgroundImageError: _showDefaultAvatar
                  ? null // Avoid recursive setState if default is already shown
                  : (exception, stackTrace) {
                      _logError("Error loading profile image", exception, stackTrace);
                      if (mounted) {
                        setState(() {
                          _showDefaultAvatar = true;
                        });
                      }
                    },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('BCH', _user!.balanceBchDevPath145),
                    _buildStatColumn('Token', _user!.balanceCashtokensDevPath145),
                    _buildStatColumn('Memo', _user!.balanceBchDevPath0Memo),
                  ],
                ),
                const SizedBox(height: 8),
                _buildEditProfileButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity, // Make button take available width
      child: SettingsButton(
        // Assuming this is an OutlinedButton or similar
        onPressed: _onProfileSettings,
        backgroundColor: Colors.transparent, // These properties depend on SettingsButton implementation
        borderColor: Colors.black54,
        text: 'Edit Profile',
        textColor: Colors.black87,
      ),
    );
  }

  Widget _buildViewModeIconButton(int index, IconData icon) {
    return IconButton(
      // padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // Default padding is often fine
      iconSize: 32, // Slightly smaller
      onPressed: () {
        if (mounted) {
          setState(() {
            _viewMode = index;
          });
        }
      },
      icon: Icon(icon, color: _activeOrNotColor(index)),
    );
  }

  Widget _buildContentView() {
    final List<MemoModelPost> imgurPosts = MemoModelPost.imgurPosts;
    final List<MemoModelPost> ytPosts = MemoModelPost.ytPosts;
    final List<MemoModelPost> hashtagPosts = MemoModelPost.hashTagPosts;
    final List<MemoModelPost> topicPosts = MemoModelPost.topicPosts;

    switch (_viewMode) {
      case 0: // Grid View (Images)
        // final posts = MemoModelPost.imgurPosts; // Use your actual data
        final posts = imgurPosts; // Using placeholder
        if (posts.isEmpty) return const Center(child: Text("No image posts yet."));
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final post = posts[index];
            // Ensure imgurUrl is not null or empty before using NetworkImage
            if (post.imgurUrl == null || post.imgurUrl!.isEmpty) {
              return Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image));
            }
            final img = Image.network(
              // Use Image.network directly for simplicity
              post.imgurUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  ImgurUtils.errorLoadImage(context, error, stackTrace), // Keep your util
              loadingBuilder: (context, child, loadingProgress) =>
                  ImgurUtils.loadingImage(context, child, loadingProgress), // Keep your util
            );
            return GestureDetector(onDoubleTap: () => _showPostDialog(post, img), child: img);
          },
        );
      case 1: // YouTube Videos
        // final posts = MemoModelPost.ytPosts; // Use your actual data
        final posts = ytPosts; // Using placeholder
        if (posts.isEmpty) return const Center(child: Text("No video posts yet."));
        return _buildYouTubeListView(posts);
      case 2: // Hashtag Posts
        // final posts = MemoModelPost.hashTagPosts; // Use your actual data
        final posts = hashtagPosts; // Using placeholder
        if (posts.isEmpty) return const Center(child: Text("No tagged posts yet."));
        return _buildGenericPostListView(posts);
      case 4: // Topic Posts
        // final posts = MemoModelPost.topicPosts; // Use your actual data
        final posts = topicPosts; // Using placeholder
        if (posts.isEmpty) return const Center(child: Text("No topic posts yet."));
        return _buildGenericPostListView(posts);
      default:
        return const Center(child: Text("Select a view mode."));
    }
  }

  void _showPostDialog(MemoModelPost post, Widget imageWidget) {
    // Ensure creator is not null
    if (post.creator == null) return;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return SimpleDialog(
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16), // Image fills width
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: post.creator!.profileImage().isEmpty
                    ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                    : NetworkImage(post.creator!.profileImage()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(post.creator!.name, style: const TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: imageWidget, // Re-use the image widget
            ),
            // Inside _showPostDialog's children:
            if (post.text != null && post.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 10,
                    minWidth: 100,
                    maxWidth: 100,
                    maxHeight: 100, // Example: Allow it to grow up to 100 pixels
                    // Adjust this based on how much space you want to allow
                  ),
                  child: SingleChildScrollView(
                    // Important for scrollability if content exceeds maxHeight
                    child: ExpandableText(
                      post.text!,
                      expandText: 'show more',
                      collapseText: 'show less',
                      maxLines: 4, // This still ap
                      collapseOnTextTap: true, // plies to the collapsed state
                      linkColor: Colors.blue,
                      animation: true,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildYouTubeListView(List<MemoModelPost> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final ytPost = posts[index];
        if (ytPost.youtubeId == null || ytPost.youtubeId!.isEmpty) {
          return const SizedBox.shrink(); // Skip if no YouTube ID
        }

        YoutubePlayerController controller = _ytControllers.putIfAbsent(
          ytPost.youtubeId!,
          () => YoutubePlayerController(
            initialVideoId: ytPost.youtubeId!,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false, // User can unmute
              hideControls: false, // Show controls by default
              hideThumbnail: false, // Show thumbnail initially
              // disableDragSeek: true,
              // loop: false,
              // isLive: false,
              // forceHD: false,
              // enableCaption: true,
            ),
          ),
        );

        return Card(
          // Wrap in Card for better visual separation
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.amber,
                  progressColors: const ProgressBarColors(playedColor: Colors.amber, handleColor: Colors.amberAccent),
                  // onReady: () { _logInfo('Player is ready.'); },
                ),
                const SizedBox(height: 8),
                if (ytPost.text != null && ytPost.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: ExpandableText(
                      ytPost.text!,
                      expandText: 'show more',
                      collapseText: 'show less',
                      maxLines: 3,
                      linkColor: Colors.blue,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const Divider(),
                Text(
                  "Posted by: ${ytPost.creator?.name ?? 'Unknown'}", // Handle null creator name
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenericPostListView(List<MemoModelPost> posts) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      post.creator?.name ?? 'Unknown', // Handle null
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      post.created ?? '', // Handle null
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
                ExpandableText(
                  post.text ?? 'No content.', // Handle null
                  expandText: 'show more',
                  collapseText: 'show less',
                  maxLines: 5,
                  linkColor: Colors.blue,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onProfileSettings() {
    showDialog(
      context: context,
      builder: (ctxDialog) {
        return SimpleDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          title: const Row(children: [Icon(Icons.settings), SizedBox(width: 10), Text("PROFILE SETTINGS")]),
          children: [
            _buildSettingsOption(Icons.verified_user_outlined, "NAME", ctxDialog, () {
              showSnackBar("Set profile name (Not implemented)", context);
            }),
            _buildSettingsOption(Icons.description_outlined, "DESCRIPTION", ctxDialog, () {
              showSnackBar("Set profile description (Not implemented)", context);
            }),
            _buildSettingsOption(Icons.image_outlined, "AVATAR URL", ctxDialog, () {
              showSnackBar("Set profile IMGUR URL (Not implemented)", context);
            }),
            _buildSettingsOption(Icons.link_rounded, "TWITTER", ctxDialog, () {
              showSnackBar("Link Twitter account (Not implemented)", context);
            }),
            const Divider(),
            _buildSettingsOption(Icons.backup_outlined, "BACKUP MNEMONIC", ctxDialog, () {
              if (_user?.mnemonic != null) {
                _copyToClipboard(_user!.mnemonic, "Mnemonic copied!");
              } else {
                showSnackBar("Mnemonic not available.", context);
              }
            }),
            _buildSettingsOption(Icons.logout_outlined, "LOGOUT", ctxDialog, () {
              AuthChecker().logOut(context); // Assuming this handles navigation
            }),
          ],
        );
      },
    );
  }

  SimpleDialogOption _buildSettingsOption(IconData icon, String text, BuildContext dialogCtx, VoidCallback onSelect) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      onPressed: () {
        Navigator.of(dialogCtx).pop(); // Pop before calling onSelect
        onSelect();
      },
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 15),
          Text(text),
        ],
      ),
    );
  }

  void _showBchQRDialog() {
    // For simplicity, ProfileScreen still manages toggleAddressType.
    // To make dialog fully independent, pass a ValueNotifier or callback.
    showDialog(
      context: context,
      builder: (dialogCtx) {
        // Use a StatefulWidget for the dialog's content if it needs its own independent state.
        // For this example, we'll keep it simple and rebuild via ProfileScreen's state.
        return QrCodeDialog(
          // Using a separate StatefulWidget for the dialog
          user: _user!,
          initialToggleState: _tempToggleAddressTypeForDialog, // Pass current toggle state
          onToggle: (newState) {
            // Callback to update ProfileScreen's state if needed
            if (mounted) {
              setState(() {
                _tempToggleAddressTypeForDialog = newState;
              });
            }
          },
        );
      },
    );
  }

  // Temporary state for the QR dialog toggle to avoid immediate ProfileScreen rebuild on tap inside dialog
  bool _tempToggleAddressTypeForDialog = true;

  Future<void> _copyToClipboard(String text, String successMessage) async {
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
}
