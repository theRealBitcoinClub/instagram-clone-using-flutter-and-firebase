import 'package:flutter/material.dart';

class ProfileTabSelector extends StatelessWidget {
  final int viewMode;
  final ValueChanged<int> onViewModeChanged;

  const ProfileTabSelector({Key? key, required this.viewMode, required this.onViewModeChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface, // Match header background or use scaffoldBackground
      // padding: const EdgeInsets.symmetric(vertical: 0), // Remove padding if not desired
      height: 60, // Ensure fixed height for SliverPersistentHeader
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // Distribute space evenly
        crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons fill height
        children: [
          _buildViewModeIconButton(theme, 0, Icons.grid_on_rounded, Icons.grid_view_rounded, "Grid"), // Grid
          _buildViewModeIconButton(theme, 1, Icons.video_library_outlined, Icons.video_library_rounded, "Videos"), // Videos
          _buildViewModeIconButton(theme, 2, Icons.tag_outlined, Icons.tag_rounded, "Tagged"), // Tagged
          _buildViewModeIconButton(theme, 4, Icons.alternate_email_outlined, Icons.alternate_email_rounded, "Topics"), // Topics
        ],
      ),
    );
  }

  Widget _buildViewModeIconButton(ThemeData theme, int index, IconData inactiveIcon, IconData activeIcon, String tooltip) {
    final bool isActive = viewMode == index;
    return Expanded(
      // Make each button take equal width
      child: IconButton(
        iconSize: 26, // Slightly adjusted size
        visualDensity: VisualDensity.standard,
        // padding: EdgeInsets.zero, // Remove padding if buttons are too spaced
        icon: Icon(isActive ? activeIcon : inactiveIcon, color: isActive ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.6)),
        tooltip: tooltip,
        onPressed: () => onViewModeChanged(index),
        splashRadius: 24, // Control splash radius
      ),
    );
  }
}
