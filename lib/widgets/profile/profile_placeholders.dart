import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';

// Helper for logging errors consistently if needed within these placeholder widgets
void _logPlaceholderError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfilePlaceholders - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileLoadingScaffold extends StatelessWidget {
  final ThemeData theme;
  final String message;

  const ProfileLoadingScaffold({Key? key, required this.theme, this.message = "Loading..."}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBarBurnMahakkaTheme(),
      body: Center(child: AvifImage(image: AssetAvifImage("assets/images/icon_round_loading_256.avif"), height: 200, width: 200)),
    );
  }
}

class ProfileErrorScaffold extends StatelessWidget {
  final ThemeData theme;
  final String message;
  final VoidCallback? onRetry; // Make onRetry nullable

  const ProfileErrorScaffold({Key? key, required this.theme, this.message = "An error occurred.", this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Profile Error", style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.errorContainer.withOpacity(0.1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 60),
              const SizedBox(height: 20),
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onErrorContainer.withOpacity(0.9)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (onRetry != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry"),
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget for empty content within a sliver list
class EmptySliverContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final ThemeData theme;

  const EmptySliverContent({
    Key? key,
    required this.message,
    this.icon = Icons.layers_clear_outlined, // Default icon
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
