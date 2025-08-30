import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import your admin panel pages
import 'package:mahakka/memo/firebase/post_admin.dart';
import 'package:mahakka/memo/firebase/tag_admin.dart';
import 'package:mahakka/memo/firebase/topic_admin.dart';
import 'package:mahakka/memo/firebase/user_admin.dart';

import '../../firebase_options.dart';
import 'creator_admin.dart'; // Adjust path

// You can keep your main.dart separate or merge this into it.
// For this example, I'll assume your main.dart will launch MainAdminDashboard.

class MainAdminDashboard extends StatefulWidget {
  const MainAdminDashboard({super.key});

  @override
  State<MainAdminDashboard> createState() => _MainAdminDashboardState();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    // Add ProviderScope here
    const ProviderScope(child: AdminApp()),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Or your preferred admin theme color
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(
          secondary: Colors.pinkAccent,
          onPrimary: Colors.redAccent, // Good for text/icons on primary color AppBar
        ),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 1.5),
        tabBarTheme: TabBarThemeData(
          // Optional: Centralized TabBar styling
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.greenAccent,
          indicatorColor: Colors.orange,
          // indicator: UnderlineTabIndicator( // More customization
          // borderSide: BorderSide(color: Colors.white, width: 2.0),
          // ),
        ),
      ),
      home: const MainAdminDashboard(), // Launch the main dashboard
    );
  }
}

// Define the callback type
typedef CountCallback = void Function(int count);

class _MainAdminDashboardState extends State<MainAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentCount = 0; // State variable to hold the count
  String _currentSectionName = 'Users'; // Default section name

  // Method to update the count and trigger a rebuild
  void _updateCount(int count) {
    if (mounted) {
      // Ensure the widget is still in the tree
      setState(() {
        _currentCount = count;
      });
    }
  }

  void _updateSectionName(int index) {
    if (mounted) {
      setState(() {
        _currentSectionName = _adminTabs[index].text ?? 'Items';
      });
    }
  }

  final List<Tab> _adminTabs = const <Tab>[
    Tab(icon: Icon(Icons.account_circle_outlined), text: 'Users'),
    Tab(icon: Icon(Icons.people_alt_outlined), text: 'Creators'),
    Tab(icon: Icon(Icons.topic_outlined), text: 'Topics'),
    Tab(icon: Icon(Icons.article_outlined), text: 'Posts'),
    Tab(icon: Icon(Icons.sell_outlined), text: 'Tags'),
  ];

  late final List<Widget> _adminTabViews; // Declare here

  @override
  void initState() {
    super.initState();

    // Initialize _adminTabViews here, passing the callback
    _adminTabViews = <Widget>[
      AdminUsersListPage(onCountChanged: _updateCount),
      AdminCreatorsListPage(onCountChanged: _updateCount),
      AdminTopicsListPage(onCountChanged: _updateCount),
      AdminPostsListPage(onCountChanged: _updateCount),
      AdminTagsListPage(onCountChanged: _updateCount),
    ];

    _tabController = TabController(length: _adminTabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // When tab changes, reset count visually or wait for new page to report
        _updateSectionName(_tabController.index);
        // _updateCount(0); // Optional: Reset count immediately on tab change
        // The new page's StreamBuilder will soon report its count
      } else {
        // This handles the initial load and when a tab is settled on
        _updateSectionName(_tabController.index);
      }
    });
    // Initial name update
    _updateSectionName(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(() {}); // Clean up listener
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construct the title dynamically
    String appBarTitle = 'Admin - $_currentSectionName ($_currentCount)';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle), // Dynamic title
        bottom: TabBar(
          controller: _tabController,
          tabs: _adminTabs,
          isScrollable: false,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
        ),
      ),
      body: TabBarView(controller: _tabController, children: _adminTabViews),
    );
  }
}
