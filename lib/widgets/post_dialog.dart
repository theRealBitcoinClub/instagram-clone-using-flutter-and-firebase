import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/cached_unified_image_widget.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';
import 'package:mahakka/widgets/unified_image_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _isOverlayVisible = true;
    // Initialize with default value, will be updated in didChangeDependencies
    _isPortrait = true;

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

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _contentAnimationController.dispose();
    _overlayAnimationController.dispose();
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
      });
      // Animate new content in
      _contentAnimationController.forward();
    });
  }

  void _closeActivity() {
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

  void _handleHeartAction() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Like functionality will be implemented later'), duration: Duration(seconds: 2)));
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
    final appBarBackgroundColor = isDarkTheme ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.9);
    final appBarIconColor = isDarkTheme ? Colors.white : Colors.black;
    final overlayColor = isDarkTheme ? Colors.black54 : Colors.white70;
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Colors.black, // Fixed black background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Gesture detector for swipe actions and double tap
            GestureDetector(
              onHorizontalDragEnd: _handleSwipe,
              onVerticalDragEnd: _handleSwipe,
              onDoubleTap: _handleDoubleTap,
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
                      child: CachedUnifiedImageWidget(
                        width: double.infinity, // Ensure full width
                        height: double.infinity,
                        border: Border.all(color: Colors.black),
                        backgroundColor: Colors.black,
                        imageUrl: post.imgurUrl ?? post.imageUrl!,
                        fitMode: ImageFitMode.contain, // Use fitWidth to fill width while maintaining aspect ratio
                      ),
                    ),
                  );
                },
              ),
            ),

            // App Bar with theme awareness - only visible in portrait
            if (_isPortrait)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: appBarBackgroundColor,
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.close, color: appBarIconColor),
                      onPressed: _closeActivity,
                    ),
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _buildTitleRow(currentPost, textColor, key: ValueKey(_currentIndex)),
                    ),
                    iconTheme: IconThemeData(color: appBarIconColor),
                    titleTextStyle: widget.theme.textTheme.titleSmall?.copyWith(color: textColor),
                  ),
                ),
              ),

            // Text overlay at bottom with animation
            if (currentPost.text != null && currentPost.text!.isNotEmpty)
              Positioned(
                bottom: _isPortrait ? 80 : 0, // Adjust position based on orientation
                left: 0,
                right: 0,
                child: _isOverlayVisible
                    ? Container(
                        key: ValueKey(_currentIndex),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: overlayColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                        ),
                        constraints: const BoxConstraints(
                          minHeight: 100, // Fixed height for exactly 5 lines
                          maxHeight: 100, // Fixed height for exactly 5 lines
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
              ),

            // Bottom Navigation Bar with theme awareness - only visible in portrait
            if (_isPortrait)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: overlayColor,
                  height: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor, size: 36), // Increased icon size
                        onPressed: _navigateToPrevious,
                        disabledColor: textColor.withOpacity(0.3),
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite_border, color: textColor, size: 36), // Increased icon size
                        onPressed: _handleHeartAction,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: textColor, size: 36), // Increased icon size
                        onPressed: _navigateToNext,
                        disabledColor: textColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
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
              "${post.createdDateTime!.toString().split('.').first}",
              style: widget.theme.textTheme.titleSmall?.copyWith(color: textColor),
            ),
          ),
          PopularityScoreWidget(score: post.popularityScore),
          const SizedBox(width: 8),
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
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
