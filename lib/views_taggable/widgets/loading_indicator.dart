import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Import Material for Theme access

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Access the Material theme
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme colorScheme = theme.colorScheme;

    // For CupertinoActivityIndicator, the color is generally dictated by the
    // CupertinoTheme's brightness or by an ancestor CupertinoTheme widget.
    // However, if you want it to roughly match your Material theme's primary color,
    // you might wrap it in a CupertinoTheme with specific primaryColor,
    // though this can be a bit heavy for just an indicator.
    // A simpler approach for visual consistency within a Material app is to
    // use Material's CircularProgressIndicator if strict Cupertino look isn't required.

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // So the Row doesn't expand unnecessarily
      children: [
        Text(
          "Loading...", // Added ellipsis for better UX
          style: textTheme.titleMedium?.copyWith(
            // Use a standard text style
            color: colorScheme.onSurfaceVariant, // A slightly muted color for loading text
          ),
        ),
        const SizedBox(width: 12), // Adjusted spacing
        // Option 1: Keep CupertinoActivityIndicator (less themable by Material Theme)
        CupertinoActivityIndicator(
          radius: 12, // Slightly larger for better visibility
          // The color of CupertinoActivityIndicator is more platform-defined
          // or can be influenced by an ancestor CupertinoTheme.
          // It doesn't have a direct 'color' property to set from Material's ColorScheme.
        ),
        // Option 2: Use Material's CircularProgressIndicator for better Material theming
        // If you prefer this, comment out CupertinoActivityIndicator and uncomment below:
        /*
        SizedBox(
          width: 24, // Consistent size with CupertinoActivityIndicator radius 12
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5, // Adjust thickness
            // color property will be inherited from theme.progressIndicatorTheme.color
            // or you can set it explicitly:
            // color: colorScheme.primary,
          ),
        ),
        */
      ],
    );
  }
}
