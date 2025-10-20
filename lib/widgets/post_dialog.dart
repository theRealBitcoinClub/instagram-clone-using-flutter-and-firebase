import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';
import 'package:mahakka/widgets/unified_image_widget.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenPostActivity extends StatefulWidget {
  final List<MemoModelPost> posts;
  final int initialIndex;
  final ThemeData theme;
  const FullScreenPostActivity({Key? key, required this.posts, required this.initialIndex, required this.theme}) : super(key: key);

  @override
  State<FullScreenPostActivity> createState() => _FullScreenPostActivityState();
}

class _FullScreenPostActivityState extends State<FullScreenPostActivity> with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _contentAnimationController;
  late bool _isOverlayVisible;
  late bool _isPortrait;
  late AnimationController _overlayAnimationController;
  late Animation<double> _overlayOpacityAnimation;
  late bool _isFullscreen;
  late Timer _fullscreenHintTimer;
  late bool _showFullscreenHint;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _isOverlayVisible = true;
    _isPortrait = true;
    _isFullscreen = false;
    _showFullscreenHint = false;
    _initFullScreenHintTimer();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _contentAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _overlayAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _overlayOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _overlayAnimationController, curve: Curves.easeInOut));

    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update orientation after the widget is mounted and has access to MediaQuery
    final newOrientation = MediaQuery.of(context).orientation;
    final newIsPortrait = newOrientation == Orientation.portrait;

    if (_isPortrait != newIsPortrait) {
      setState(() {
        _isPortrait = newIsPortrait;
      });
    }
  }

  void _toggleFullscreen() {
    if (_isFullscreen) {
      // Exit fullscreen - go back to portrait
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      setState(() {
        _isFullscreen = false;
        _showFullscreenHint = false;
      });
      _fullscreenHintTimer.cancel();
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        // DeviceOrientation.portraitUp,
        // DeviceOrientation.portraitDown,
      ]);
      setState(() {
        _isFullscreen = true;
        _showFullscreenHint = true;
      });

      _showFullscreenHintWithTimer();
    }
  }

  void _showFullscreenHintWithTimer() {
    _fullscreenHintTimer.cancel(); // Cancel any existing timer
    _initFullScreenHintTimer();
  }

  void _initFullScreenHintTimer() {
    _fullscreenHintTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showFullscreenHint = false;
        });
      }
    });
  }

  void _handleLongPress() {
    if (_isFullscreen) {
      _toggleFullscreen();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _contentAnimationController.dispose();
    _overlayAnimationController.dispose();
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _fullscreenHintTimer.cancel();
    super.dispose();
  }

  void _navigateToPrevious() {
    if (_currentIndex > 0) {
      _pageController.animateToPage(_currentIndex - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _navigateToNext() {
    if (_currentIndex < widget.posts.length - 1) {
      _pageController.animateToPage(_currentIndex + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _onPageChanged(int index) {
    // Animate content out quickly
    _contentAnimationController.reverse().then((_) {
      setState(() {
        _currentIndex = index;
        // Reset overlay visibility when changing posts
        _isOverlayVisible = true;
        _overlayAnimationController.reverse();

        // Show fullscreen hint again after swipe if in fullscreen mode
        // if (_isFullscreen) {
        //   _showFullscreenHint = true;
        //   _showFullscreenHintWithTimer();
        // }
      });
      // Animate new content in
      _contentAnimationController.forward();
    });
  }

  void _closeActivity() {
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      // Swipe right or bottom
      _navigateToPrevious();
    } else if (details.primaryVelocity! < 0) {
      // Swipe left or top
      _navigateToNext();
    }
  }

  void _handleShareAction() {
    SharePlus.instance.share(ShareParams(text: widget.posts[_currentIndex].mediaUrl));
  }

  void _handleDoubleTap() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
      if (_isOverlayVisible) {
        _overlayAnimationController.reverse();
      } else {
        _overlayAnimationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPost = widget.posts[_currentIndex];
    final isDarkTheme = widget.theme.brightness == Brightness.dark;

    // Theme-aware colors for app bar and overlay
    final appBarBackgroundColor = isDarkTheme ? Colors.black.withAlpha(222) : Colors.white.withAlpha(222);
    final appBarIconColor = isDarkTheme ? Colors.white : Colors.black;
    final overlayColor = isDarkTheme ? Colors.black.withAlpha(198) : Colors.white.withAlpha(198);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final hintOverlayColor = isDarkTheme ? Colors.black.withAlpha(198) : Colors.white.withAlpha(198);

    return Scaffold(
      backgroundColor: Colors.black, // Fixed black background
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Gesture detector for swipe actions, double tap, and long press
              GestureDetector(
                onHorizontalDragEnd: _handleSwipe,
                onVerticalDragEnd: _handleSwipe,
                onDoubleTap: _handleDoubleTap,
                onLongPress: _handleLongPress,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: widget.posts.length,
                  itemBuilder: (context, index) {
                    final post = widget.posts[index];
                    return Container(
                      color: Colors.black, // Fixed black background for image container
                      width: double.infinity, // Ensure full width
                      height: double.infinity,
                      child: Center(
                        child: UnifiedImageWidget(
                          backgroundColor: Colors.black,
                          border: Border.all(color: Colors.black),
                          imageUrl: post.imgurUrl ?? post.imageUrl ?? IpfsConfig.preferredNode + post.ipfsCid!,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // App Bar with theme awareness - only visible in portrait or when not in fullscreen
              if (_isPortrait || !_isFullscreen) buildAppBar(appBarBackgroundColor, appBarIconColor, currentPost, textColor),
              if (currentPost.text != null && currentPost.text!.isNotEmpty && (_isPortrait || !_isFullscreen))
                buildPostTextDescription(overlayColor, currentPost, textColor),
              if (_isPortrait || !_isFullscreen) buildBottomNavBar(appBarBackgroundColor, textColor),
              if (_showFullscreenHint && _isFullscreen) buildHintLongPressExit(hintOverlayColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Positioned buildAppBar(Color appBarBackgroundColor, Color appBarIconColor, MemoModelPost currentPost, Color textColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: appBarBackgroundColor,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 50,
          leading: IconButton(
            icon: Icon(size: 30, Icons.close, color: appBarIconColor),
            onPressed: _closeActivity,
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildTitleRow(currentPost, textColor, key: ValueKey(_currentIndex)),
          ),
          actions: [
            IconButton(
              icon: Icon(size: 30, _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen, color: appBarIconColor),
              onPressed: _toggleFullscreen,
            ),
          ],
          iconTheme: IconThemeData(color: appBarIconColor),
          titleTextStyle: widget.theme.textTheme.titleSmall?.copyWith(color: textColor),
        ),
      ),
    );
  }

  Positioned buildPostTextDescription(Color overlayColor, MemoModelPost currentPost, Color textColor) {
    return Positioned(
      bottom: _isPortrait ? 60 : 0, // Adjust position based on orientation
      left: 0,
      right: 0,
      child: _isOverlayVisible
          ? Container(
              key: ValueKey(_currentIndex),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: overlayColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              constraints: const BoxConstraints(
                minHeight: 80, // Fixed height for exactly 5 lines
                maxHeight: 80, // Fixed height for exactly 5 lines
              ),
              width: double.infinity, // Stretch full width
              child: FadeTransition(
                opacity: _overlayOpacityAnimation,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    currentPost.text!,
                    style: widget.theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.2, // Line height for better spacing
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 5, // Exactly 5 lines
                    overflow: TextOverflow.ellipsis, // Ellipsis for overflow
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }

  Positioned buildBottomNavBar(Color appBarBackgroundColor, Color textColor) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: appBarBackgroundColor,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_circle_left_outlined, color: textColor, size: 34), // Increased icon size
              onPressed: _navigateToPrevious,
              disabledColor: textColor.withOpacity(0.3),
            ),
            IconButton(
              icon: Icon(Icons.share_outlined, color: textColor, size: 34), // Increased icon size
              onPressed: _handleShareAction,
            ),
            IconButton(
              icon: Icon(Icons.arrow_circle_right_outlined, color: textColor, size: 34), // Increased icon size
              onPressed: _navigateToNext,
              disabledColor: textColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Positioned buildHintLongPressExit(Color hintOverlayColor, Color textColor) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: hintOverlayColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 20, color: textColor),
            const SizedBox(width: 8),
            Text(
              'Long press to exit',
              style: widget.theme.textTheme.bodyLarge?.copyWith(color: textColor, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleRow(MemoModelPost post, Color textColor, {Key? key}) {
    return Container(
      key: key,
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${post.creator == null ? post.creatorId.substring(0, 8) : post.creator!.name}",
              style: widget.theme.textTheme.titleMedium?.copyWith(color: textColor),
            ),
          ),
          PopularityScoreWidget(initialScore: post.popularityScore, textStyle: widget.theme.textTheme.titleSmall),
          Text(" sats, "),
          const SizedBox(width: 6),
          Text("${post.age} ago", style: widget.theme.textTheme.titleSmall?.copyWith(color: textColor)),
        ],
      ),
    );
  }
}

// Helper function to show the fullscreen post activity
void showPostImageFullscreenWidget({
  required BuildContext context,
  required ThemeData theme,
  required List<MemoModelPost> posts,
  required int initialIndex,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return FullScreenPostActivity(posts: posts, initialIndex: initialIndex, theme: theme);
      },
      // transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //   return FadeTransition(opacity: animation, child: child);
      // },
      // transitionDuration: const Duration(milliseconds: 100),
    ),
  );
}
