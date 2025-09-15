// screens/memo_webview_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../provider/user_provider.dart';
import '../providers/webview_providers.dart';

// Constants for URLs
const String _httpsPrefix = 'https://';
const String _memoCashDomain = 'memo.cash';
const String _baseUrl = '$_httpsPrefix$_memoCashDomain';

class MemoWebviewScreen extends ConsumerStatefulWidget {
  const MemoWebviewScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoWebviewScreen> createState() => _MemoWebviewScreenState();
}

class _MemoWebviewScreenState extends ConsumerState<MemoWebviewScreen> {
  late WebViewController _webViewController;
  String _currentPath = '/';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialUrl();
  }

  void _loadInitialUrl() {
    // Check providers first - if either has a value, load that URL
    final tagId = ref.read(tagIdProvider);
    final topicId = ref.read(topicIdProvider);

    String initialUrl;

    if (tagId != null && tagId.isNotEmpty) {
      initialUrl = '$_baseUrl/tag/$tagId';
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tagIdProvider.notifier).state = null;
      });
    } else if (topicId != null && topicId.isNotEmpty) {
      initialUrl = '$_baseUrl/topic/$topicId';
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(topicIdProvider.notifier).state = null;
      });
    } else {
      // Default to profile if no providers have values
      final user = ref.read(userProvider)!;
      initialUrl = '$_baseUrl/profile/${user.id}';
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _updateCurrentPath(url);
          },
          onUrlChange: (change) {
            if (change.url != null) {
              _updateCurrentPath(change.url!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(initialUrl));
  }

  void _updateCurrentPath(String url) {
    final uri = Uri.parse(url);
    setState(() {
      _currentPath = uri.path.isEmpty ? '/' : uri.path;
    });
  }

  void _loadUrl(String url) {
    _webViewController.loadRequest(Uri.parse(url));
  }

  void _loadProfile() {
    // Reset both providers when any action is tapped
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    final user = ref.read(userProvider)!;
    _loadUrl('$_baseUrl/profile/${user.id}');
  }

  void _loadFeed() {
    // Reset both providers when any action is tapped
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    _loadUrl('$_baseUrl/posts/ranked');
  }

  void _loadTags() {
    final tagId = ref.read(tagIdProvider);

    // Always reset providers first
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    // If tagId was set, load that specific tag, otherwise load default tags page
    if (tagId != null && tagId.isNotEmpty) {
      _loadUrl('$_baseUrl/tag/$tagId');
    } else {
      _loadUrl('$_baseUrl/tags/recent');
    }
  }

  void _loadTopics() {
    final topicId = ref.read(topicIdProvider);

    // Always reset providers first
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    // If topicId was set, load that specific topic, otherwise load default topics page
    if (topicId != null && topicId.isNotEmpty) {
      _loadUrl('$_baseUrl/topic/$topicId');
    } else {
      _loadUrl('$_baseUrl/topics');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        // Listen to provider changes and load appropriate URLs
        ref.listen(tagIdProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _loadUrl('$_baseUrl/tag/$next');
          }
        });

        ref.listen(topicIdProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _loadUrl('$_baseUrl/topic/$next');
          }
        });

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: _loadProfile,
              child: Icon(
                CupertinoIcons.person_circle_fill,
                color: theme.iconTheme.color,
                size: 28, // Larger size for leading icon
              ),
            ),
            middle: Text(
              _currentPath,
              // style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 1.1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feed icon
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _loadFeed,
                  child: Icon(
                    CupertinoIcons.news_solid,
                    color: theme.iconTheme.color,
                    size: 28, // Larger size
                  ),
                ),
                SizedBox(width: 20),
                // Hashtag icon
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _loadTags,
                  child: Icon(
                    CupertinoIcons.tag_fill,
                    color: theme.iconTheme.color,
                    size: 28, // Larger size
                  ),
                ),
                SizedBox(width: 20),
                // Topic icon
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _loadTopics,
                  child: Icon(
                    CupertinoIcons.at,
                    color: theme.iconTheme.color,
                    size: 28, // Larger size
                  ),
                ),
              ],
            ),
            border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
