import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Import your admin panel pages
import 'package:mahakka/memo/firebase/post_admin.dart';
import 'package:mahakka/memo/firebase/tag_admin.dart';
import 'package:mahakka/memo/firebase/topic_admin.dart';
import 'package:mahakka/memo/firebase/user_admin.dart';

import '../../firebase_options.dart';
import 'creator_admin.dart';

// Define the callback type that accepts two integer arguments.
typedef CountChangedCallback = void Function(int fetchedCount, int totalCount);

class MainAdminDashboard extends StatefulWidget {
  const MainAdminDashboard({super.key});

  @override
  State<MainAdminDashboard> createState() => _MainAdminDashboardState();
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(secondary: Colors.pinkAccent, onPrimary: Colors.redAccent),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 1.5),
        tabBarTheme: TabBarThemeData(labelColor: Colors.amber, unselectedLabelColor: Colors.greenAccent, indicatorColor: Colors.orange),
      ),
      home: const MainAdminDashboard(),
    );
  }
}

class _MainAdminDashboardState extends State<MainAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentFetchedCount = 0;
  int _currentTotalCount = 0;
  String _currentSectionName = 'Users';

  // Method to update both the fetched and total counts.
  void _updateCounts(int fetchedCount, int totalCount) {
    if (mounted) {
      setState(() {
        _currentFetchedCount = fetchedCount;
        _currentTotalCount = totalCount;
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

  late final List<Widget> _adminTabViews;

  @override
  void initState() {
    super.initState();

    // Pass the new _updateCounts callback to each page.
    _adminTabViews = <Widget>[
      AdminUsersListPage(onCountChanged: _updateCounts),
      AdminCreatorsListPage(onCountChanged: _updateCounts),
      AdminTopicsListPage(onCountChanged: _updateCounts),
      AdminPostsListPage(onCountChanged: _updateCounts),
      AdminTagsListPage(onCountChanged: _updateCounts),
    ];

    _tabController = TabController(length: _adminTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _updateSectionName(_tabController.index);
        // Reset counts when switching to a new tab.
        setState(() {
          _currentFetchedCount = 0;
          _currentTotalCount = 0;
        });
      }
    });
    // Initial name update for the first tab.
    _updateSectionName(_tabController.index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construct the title to show both counts.
    String appBarTitle = 'Admin - $_currentSectionName ($_currentFetchedCount / $_currentTotalCount)';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}
