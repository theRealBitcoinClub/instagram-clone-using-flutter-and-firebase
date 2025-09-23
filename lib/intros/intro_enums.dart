import 'package:flutter/material.dart';

// intro_enums.dart
enum IntroType {
  mainApp({IntroStep.main_theme, IntroStep.main_create, IntroStep.main_profile}),
  feedScreen({IntroStep.discoverContent, IntroStep.interactPosts}),
  addScreen({IntroStep.createPost, IntroStep.addMedia}),
  profileScreen({IntroStep.editProfile, IntroStep.viewStats}),
  webviewScreen({IntroStep.navigateWeb, IntroStep.bookmarkContent}),
  postCard({IntroStep.likePost, IntroStep.sharePost});

  final Set<IntroStep> steps;
  const IntroType(this.steps);
}

class IntroStep {
  // Main App Steps
  static const main_theme = IntroStep._(
    'themeSelection',
    IntroContent(
      initText: "Customize Your Experience",
      snackbarText: "Perfect! You can change themes anytime",
      triggeredText: "A dark theme can save a lot of battery!",
      target: IntroTarget.topRight,
    ),
  );

  static const main_create = IntroStep._(
    'createContent',
    IntroContent(
      initText: "Share Inspiring Ideas",
      snackbarText: "Great! You found the creation hub",
      triggeredText: "Select a media type at the top to share content",
      target: IntroTarget.bottomCenter,
    ),
  );

  static const main_profile = IntroStep._(
    'profileAccess',
    IntroContent(
      initText: "Profile & Settings",
      snackbarText: "Backup your mnemonic, make sure funds are SAFU",
      triggeredText: "Backup your mnemonic, set profile data, or change tip settings with the settings button up north!",
      target: IntroTarget.bottomRight,
    ),
  );

  // Feed Screen Steps
  static const discoverContent = IntroStep._(
    'discoverContent',
    IntroContent(
      initText: "Discover Amazing Content",
      snackbarText: "Awesome! You're exploring the feed",
      triggeredText: "Scroll through posts from creators worldwide",
      target: IntroTarget.bottomCenter,
    ),
  );

  static const interactPosts = IntroStep._(
    'interactPosts',
    IntroContent(
      initText: "Engage with Posts",
      snackbarText: "Nice! You're interacting with content",
      triggeredText: "Like, comment, and share posts you enjoy",
      target: IntroTarget.topRight,
    ),
  );

  // Add Screen Steps
  static const createPost = IntroStep._(
    'createPost',
    IntroContent(
      initText: "Create Your First Post",
      snackbarText: "Ready to share! Compose your message",
      triggeredText: "Add text, images, or links to create engaging posts",
      target: IntroTarget.bottomCenter,
    ),
  );

  static const addMedia = IntroStep._(
    'addMedia',
    IntroContent(
      initText: "Enhance with Media",
      snackbarText: "Media makes posts stand out!",
      triggeredText: "Add photos or videos to make your content more engaging",
      target: IntroTarget.topRight,
    ),
  );

  // Profile Screen Steps
  static const editProfile = IntroStep._(
    'editProfile',
    IntroContent(
      initText: "Personalize Your Profile",
      snackbarText: "Make it yours! Customize your profile",
      triggeredText: "Update your bio, avatar, and profile settings",
      target: IntroTarget.topRight,
    ),
  );

  static const viewStats = IntroStep._(
    'viewStats',
    IntroContent(
      initText: "Track Your Progress",
      snackbarText: "See your impact! Check your stats",
      triggeredText: "Monitor your followers, likes, and engagement metrics",
      target: IntroTarget.bottomCenter,
    ),
  );

  // Webview Screen Steps
  static const navigateWeb = IntroStep._(
    'navigateWeb',
    IntroContent(
      initText: "Browse Web Content",
      snackbarText: "Web access enabled! Browse freely",
      triggeredText: "Navigate websites and view external content seamlessly",
      target: IntroTarget.topRight,
    ),
  );

  static const bookmarkContent = IntroStep._(
    'bookmarkContent',
    IntroContent(
      initText: "Save for Later",
      snackbarText: "Bookmarking saves your favorites!",
      triggeredText: "Save interesting content to revisit anytime",
      target: IntroTarget.bottomRight,
    ),
  );

  // Post Card Steps
  static const likePost = IntroStep._(
    'likePost',
    IntroContent(
      initText: "Show Appreciation",
      snackbarText: "Likes encourage creators!",
      triggeredText: "Tap the like button to support content you enjoy",
      target: IntroTarget.topRight,
    ),
  );

  static const sharePost = IntroStep._(
    'sharePost',
    IntroContent(
      initText: "Spread the Word",
      snackbarText: "Sharing is caring!",
      triggeredText: "Share posts with others to help content reach more people",
      target: IntroTarget.bottomRight,
    ),
  );

  final String id;
  final IntroContent content;
  const IntroStep._(this.id, this.content);

  @override
  String toString() => id;
}

class IntroContent {
  final String initText;
  final String snackbarText;
  final String triggeredText;
  final IntroTarget target;

  const IntroContent({required this.initText, required this.snackbarText, required this.triggeredText, required this.target});
}

class IntroTarget {
  final Offset position;
  final double rotation;
  final double width;
  final double height;

  const IntroTarget({required this.position, required this.rotation, this.width = 50, this.height = 50});

  // Predefined targets
  static const topRight = IntroTarget(position: Offset(0.84, 0.05), rotation: 0.3);

  static const bottomCenter = IntroTarget(position: Offset(0.45, 0.75), rotation: 3.10);

  static const bottomRight = IntroTarget(position: const Offset(0.76, 0.75), rotation: 3.0);

  Offset getAbsolutePosition(Size screenSize) {
    return Offset(position.dx * screenSize.width, position.dy * screenSize.height);
  }
}
