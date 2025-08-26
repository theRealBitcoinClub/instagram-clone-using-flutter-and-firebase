import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/provider/user_provider.dart'; // Ensure ProviderUser is correctly defined and provided
import 'package:mahakka/screens/add_screen.dart'; // Ensure AddPost is themed
import 'package:mahakka/screens/feed_screen.dart'; // Ensure FeedScreen is themed
import 'package:mahakka/screens/profile_screen.dart'; // Ensure ProfileScreen is themed
// import 'package:mahakka/utils/colors.dart'; // REMOVE THIS - Colors should come from theme
import 'package:provider/provider.dart';

// Assuming your ThemeProvider and app_themes.dart are accessible
// import '../theme_provider.dart';
// import '../app_themes.dart';

class NavBarCallback {
  switchToProfileTab() {}
}

class HomeSceen extends StatefulWidget {
  // Consider renaming to HomeScreen for convention
  const HomeSceen({Key? key}) : super(key: key);

  @override
  State<HomeSceen> createState() => _HomeSceenState();
}

class _HomeSceenState extends State<HomeSceen> implements NavBarCallback {
  int _page = 0;
  late PageController _pageController; // Renamed for convention

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _addData(); // Call the renamed method
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  switchToProfileTab() {
    _navigationPageSelected(2);
  }

  Future<void> _addData() async {
    // Renamed for convention and make it Future<void>
    // Ensure UserProvider is correctly set up with Provider
    // and that ProviderUser is the correct type.
    if (mounted) {
      // Check if widget is still in the tree
      ProviderUser up = Provider.of<ProviderUser>(context, listen: false);
      try {
        await up.refreshUser();
      } catch (e) {
        // Handle error if refreshUser fails, e.g., show a SnackBar
        print("Error refreshing user: $e");
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text("Failed to load user data.", style: TextStyle(color: Theme.of(context).colorScheme.onError)), backgroundColor: Theme.of(context).colorScheme.error),
          // );
        }
      }
    }
  }

  // TODO: Implement actual sign out logic or remove if not used
  // void _signOut() async {
  //   // Example:
  //   // await FirebaseAuth.instance.signOut();
  //   // Navigator.of(context).pushReplacementNamed('/login'); // Or your login screen route
  //   print("Sign out action placeholder");
  // }

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void _navigationPageSelected(int page) {
    if (page != 2) MemoModelUser.profileIdReset();
    _pageController.jumpToPage(page);
    // No need to call setState here, _onPageChanged will handle it
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Get the current theme
    final ColorScheme colorScheme = theme.colorScheme;
    // Define colors for CupertinoTabBar based on the Material theme
    // For Cupertino, active color is usually a bright, distinct color.
    // Inactive color is typically a muted grey.
    final Color cupertinoActiveColor = colorScheme.primary; // Use primary color for active items
    final Color cupertinoInactiveColor = colorScheme.onSurface.withOpacity(0.6); // Muted version of onSurface

    // Screens to be displayed in the PageView
    // Ensure these screens are also themed internally
    final List<Widget> homeScreenItems = [
      FeedScreen(navBarCallback: this),
      // const SearchScreen(), // If you have a SearchScreen
      const AddPost(), // Renamed from AddScreen to match common naming
      // TODO: Replace hardcoded UID with actual authenticated user ID
      // Example: ProfileScreen(uid: Provider.of<UserProvider>(context, listen: false).currentUser?.uid ?? 'default_fallback_uid'),
      const ProfileScreen(), // Placeholder UID
    ];

    return Scaffold(
      // The AppBar is commented out, but if you add one, ensure it uses theme.appBarTheme
      backgroundColor: theme.scaffoldBackgroundColor, // Background of the screen itself
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // To disable swipe navigation
        children: homeScreenItems,
      ),
      bottomNavigationBar: CupertinoTabBar(
        height: 70, // Keep custom height if desired
        backgroundColor:
            theme.bottomNavigationBarTheme.backgroundColor ?? // Use Material BottomNavTheme bg
            (theme.brightness == Brightness.light ? Colors.grey[100] : Colors.grey[900]), // Fallback
        activeColor: cupertinoActiveColor,
        inactiveColor: cupertinoInactiveColor,
        currentIndex: _page,
        iconSize: 30.0, // Default is 30.0, adjust as needed
        border: Border(
          // Optional: to match Material style more closely or remove default iOS border
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.5), // Use theme divider color
            width: 0.5, // Keep it subtle
          ),
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(_page == 0 ? CupertinoIcons.house_fill : CupertinoIcons.house),
            // label: 'Home', // CupertinoTabBar usually doesn't show labels by default
          ),
          // Example Search Item (if you had one)
          // BottomNavigationBarItem(
          //   icon: Icon(_page== 1 ? CupertinoIcons.search_circle_fill : CupertinoIcons.search),
          //   // label: 'Search',
          // ),
          BottomNavigationBarItem(
            // Using a Material icon here - ensure it looks consistent or use a Cupertino equivalent
            icon: Icon(
              _page == 1 ? CupertinoIcons.add_circled_solid : CupertinoIcons.add_circled,
            ), // Example for AddPost
            // label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(_page == 2 ? CupertinoIcons.person_fill : CupertinoIcons.person),
            // label: 'Profile',
          ),
        ],
        onTap: _navigationPageSelected,
      ),
    );
  }
}
