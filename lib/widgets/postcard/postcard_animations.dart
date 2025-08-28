import 'package:flutter/material.dart';
import 'package:mahakka/widgets/like_animtion.dart'; // Assuming this path is correct

// Duration can be defined here or passed if it needs to be dynamic
const Duration _postcardAnimationDuration = Duration(milliseconds: 500);

// Making this a top-level function as it's a utility
AnimatedOpacity buildCircledOpacityAnimation(IconData iconData, ThemeData theme, double mediaHeight, bool isAnimating, VoidCallback onEnd) {
  Color avatarBackgroundColor = theme.colorScheme.surface;
  Color iconColorOnAvatar = theme.colorScheme.primary;
  double iconSize = mediaHeight * 0.6;
  double avatarRadius = mediaHeight * 0.5;

  return AnimatedOpacity(
    duration: _postcardAnimationDuration,
    opacity: isAnimating ? 1 : 0,
    child: LikeAnimation(
      // Ensure LikeAnimation is correctly imported and works
      isAnimating: isAnimating,
      duration: _postcardAnimationDuration,
      onEnd: onEnd,
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: avatarBackgroundColor,
        child: Icon(iconData, color: iconColorOnAvatar, size: iconSize),
      ),
    ),
  );
}

class SendingAnimation extends StatelessWidget {
  final bool isSending;
  final double mediaHeight;
  final VoidCallback onEnd;
  final ThemeData theme;

  const SendingAnimation({super.key, required this.isSending, required this.mediaHeight, required this.onEnd, required this.theme});

  @override
  Widget build(BuildContext context) {
    return buildCircledOpacityAnimation(Icons.thumb_up_alt_outlined, theme, mediaHeight, isSending, onEnd);
  }
}

class LikeSucceededAnimation extends StatelessWidget {
  final bool isAnimating;
  final double mediaHeight;
  final VoidCallback onEnd;
  final ThemeData theme;

  const LikeSucceededAnimation({super.key, required this.isAnimating, required this.mediaHeight, required this.onEnd, required this.theme});

  @override
  Widget build(BuildContext context) {
    return buildCircledOpacityAnimation(Icons.currency_bitcoin_rounded, theme, mediaHeight, isAnimating, onEnd);
  }
}
