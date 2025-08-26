import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Import your admin panel pages
import 'package:mahakka/memo/firebase/post_admin.dart';
import 'package:mahakka/memo/firebase/tag_admin.dart';
import 'package:mahakka/memo/firebase/topic_admin.dart';

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
  runApp(const AdminApp());
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
          onPrimary: Colors.white, // Good for text/icons on primary color AppBar
        ),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 1.5),
        tabBarTheme: TabBarThemeData(
          // Optional: Centralized TabBar styling
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          // indicator: UnderlineTabIndicator( // More customization
          // borderSide: BorderSide(color: Colors.white, width: 2.0),
          // ),
        ),
      ),
      home: const MainAdminDashboard(), // Launch the main dashboard
    );
  }
}

class _MainAdminDashboardState extends State<MainAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _adminTabs = const <Tab>[
    Tab(icon: Icon(Icons.people_alt_outlined), text: 'Creators'),
    Tab(icon: Icon(Icons.topic_outlined), text: 'Topics'),
    Tab(icon: Icon(Icons.article_outlined), text: 'Posts'),
    Tab(icon: Icon(Icons.sell_outlined), text: 'Tags'),
  ];

  final List<Widget> _adminTabViews = const <Widget>[
    AdminCreatorsListPage(),
    AdminTopicsListPage(),
    AdminPostsListPage(),
    AdminTagsListPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _adminTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _adminTabs,
          isScrollable: false, // Set to true if you have many tabs that don't fit
          indicatorColor: Theme.of(context).colorScheme.onPrimary, // Color of the underline
          labelColor: Theme.of(context).colorScheme.onPrimary, // Color of the active tab's text/icon
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7), // Color of inactive tabs
        ),
      ),
      body: TabBarView(controller: _tabController, children: _adminTabViews),
    );
  }
}
