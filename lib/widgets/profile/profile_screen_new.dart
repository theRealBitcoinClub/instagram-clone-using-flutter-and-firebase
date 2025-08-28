import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import the new main widget for the profile screen
import 'package:mahakka/widgets/profile/profile_screen_widget.dart'; // Adjust path if needed

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This widget now primarily delegates to ProfileScreenWidget
    return const ProfileScreenWidget();
  }
}
