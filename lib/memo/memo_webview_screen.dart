// screens/memo_webview_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // Use InAppWebViewController
  late InAppWebViewController _webViewController;
  String _currentPath = '/';
  bool _isLoading = true;
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    // No need to load URL in initState anymore, it's done directly in the widget.
  }

  // Helper method to determine the initial URL
  String _getInitialUrl() {
    final tagId = ref.read(tagIdProvider);
    final topicId = ref.read(topicIdProvider);

    if (tagId != null && tagId.isNotEmpty) {
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tagIdProvider.notifier).state = null;
      });
      return '$_baseUrl/tag/$tagId';
    } else if (topicId != null && topicId.isNotEmpty) {
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(topicIdProvider.notifier).state = null;
      });
      return '$_baseUrl/topic/$topicId';
    } else {
      // Default to profile if no providers have values
      final user = ref.read(userProvider)!;
      return '$_baseUrl/profile/${user.id}';
    }
  }

  void _updateCurrentPath(String url) {
    final uri = Uri.parse(url);
    setState(() {
      _currentPath = uri.path.isEmpty ? '/' : uri.path;
    });
  }

  void _loadUrl(String url) {
    // Use loadUrl() from InAppWebViewController
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri.uri(Uri.parse(url))));
  }

  void _loadProfile() {
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    final user = ref.read(userProvider)!;
    _loadUrl('$_baseUrl/profile/${user.id}');
  }

  void _loadFeed() {
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    _loadUrl('$_baseUrl/posts/ranked');
  }

  void _loadTags() {
    final tagId = ref.read(tagIdProvider);

    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    if (tagId != null && tagId.isNotEmpty) {
      _loadUrl('$_baseUrl/tag/$tagId');
    } else {
      _loadUrl('$_baseUrl/tags/recent');
    }
  }

  void _loadTopics() {
    final topicId = ref.read(topicIdProvider);

    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    if (topicId != null && topicId.isNotEmpty) {
      _loadUrl('$_baseUrl/topic/$topicId');
    } else {
      _loadUrl('$_baseUrl/topics');
    }
  }

  Future<void> _injectCSS() async {
    final theme = Theme.of(context);
    _isDarkTheme = theme.brightness == Brightness.dark;

    String css =
        '''
      <style>
        /* Hide navigation and other unwanted elements */
        .navbar,
        .footer,
        #mobile-app-banner,
        .alert-banner,
        .posts-nav,
        .posts-nav-dropdown,
        .side-header-spacer,
        .row:not(.post):not([class*="col-"]),
        .android-link,
        .ios-link,
        #mobile-app-banner {
          display: none !important;
        }

        /* Remove default body padding/margin */
        body {
          margin: 0 !important;
          padding: 0 !important;
          overflow-x: hidden !important;
        }

        /* Theme-aware styling */
        body {
          background: ${_isDarkTheme ? '#121212' : '#f8f8f8'} !important;
          color: ${_isDarkTheme ? '#d2d2d2' : '#000'} !important;
        }

        /* Post styling - make posts more prominent */
        .post {
          background: ${_isDarkTheme ? '#1e1e1e' : '#fff'} !important;
          border-color: ${_isDarkTheme ? '#333' : '#e8e8e8'} !important;
          border-radius: 8px !important;
          margin: 12px 0 !important;
          padding: 16px !important;
          box-shadow: 0 2px 4px ${_isDarkTheme ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)'} !important;
        }

        .post.post-odd {
          background: ${_isDarkTheme ? '#2a2a2a' : '#f8f8f8'} !important;
        }

        /* Text colors */
        .post .name {
          color: ${_isDarkTheme ? '#e0e0e0' : '#555'} !important;
          font-weight: bold !important;
        }

        .post .name .profile {
          color: ${_isDarkTheme ? '#d2d2d2' : '#333'} !important;
        }

        /* Links */
        a {
          color: ${_isDarkTheme ? '#6eb332' : '#487521'} !important;
        }

        a.normal {
          color: ${_isDarkTheme ? '#e0e0e0' : '#444'} !important;
        }

        /* Input fields */
        .form-control {
          color: ${_isDarkTheme ? '#e0e0e0' : 'inherit'} !important;
          background: ${_isDarkTheme ? '#2d2d2d' : '#fff'} !important;
          border-color: ${_isDarkTheme ? '#444' : '#ccc'} !important;
        }

        /* Remove any fixed positioning that might cause issues */
        #site-wrapper.active,
        #site-wrapper-cover.active {
          position: relative !important;
          overflow: visible !important;
          height: auto !important;
        }

        /* Ensure content takes full width */
        .container {
          width: 100% !important;
          max-width: 100% !important;
          padding: 0 8px !important;
          margin-top: 0 !important;
        }

        /* Force portrait-only layout */
        @media (orientation: landscape) {
          body {
            transform: rotate(0deg) !important;
            width: 100vw !important;
            height: 100vh !important;
            overflow: hidden !important;
          }
        }

        /* Mobile responsiveness */
        @media (max-width: 767px) {
          .post {
            margin: 8px 0 !important;
            border-radius: 0 !important;
            padding: 12px !important;
          }
          
          .container {
            padding: 0 4px !important;
          }
        }
      </style>
    ''';

    // InAppWebView uses evaluateJavascript()
    await _webViewController.evaluateJavascript(
      source:
          '''
      (function() {
        // First inject CSS
        var style = document.createElement('style');
        style.innerHTML = `$css`;
        document.head.appendChild(style);
        
        // Remove unwanted elements
        var elementsToRemove = [
          '.navbar',
          '.footer',
          '#mobile-app-banner',
          '.alert-banner',
          '.posts-nav',
          '.posts-nav-dropdown',
          '.side-header-spacer',
          '.android-link',
          '.ios-link'
        ];
        
        elementsToRemove.forEach(function(selector) {
          var elements = document.querySelectorAll(selector);
          elements.forEach(function(el) {
            el.remove();
          });
        });
        
        // Remove rows that don't contain posts
        var rows = document.querySelectorAll('.row');
        rows.forEach(function(row) {
          var hasPost = row.querySelector('.post');
          var hasCol = row.querySelector('[class*="col-"]');
          if (!hasPost && !hasCol) {
            row.remove();
          }
        });
        
        // Force body to use theme colors
        document.body.style.backgroundColor = '${_isDarkTheme ? '#121212' : '#f8f8f8'}';
        document.body.style.color = '${_isDarkTheme ? '#d2d2d2' : '#000'}';
        
        // Add dark class if needed
        if (${_isDarkTheme}) {
          document.body.classList.add('dark');
        } else {
          document.body.classList.remove('dark');
        }
        
        // Calculate height of removed elements and scroll down
        setTimeout(function() {
          // Scroll to the top of the post content
          var firstPost = document.querySelector('.post');
          if (firstPost) {
            firstPost.scrollIntoView({behavior: 'smooth'});
          }
          
          // Alternatively, scroll by estimated height of removed elements
          window.scrollBy(0, 120);
        }, 300);
      })();
    ''',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _isDarkTheme = theme.brightness == Brightness.dark;

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
              child: Icon(CupertinoIcons.person_circle_fill, color: theme.iconTheme.color, size: 28),
            ),
            middle: Text(_currentPath, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _loadFeed,
                  child: Icon(CupertinoIcons.news_solid, color: theme.iconTheme.color, size: 28),
                ),
                SizedBox(width: 20),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _loadTags,
                  child: Icon(CupertinoIcons.tag_fill, color: theme.iconTheme.color, size: 28),
                ),
                SizedBox(width: 20),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: _loadTopics,
                  child: Icon(CupertinoIcons.at, color: theme.iconTheme.color, size: 28),
                ),
              ],
            ),
            border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5), width: 0.5)),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Use InAppWebView widget
                InAppWebView(
                  // Set initial URL here
                  initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(_getInitialUrl()))),
                  // Set options for the webview
                  initialOptions: InAppWebViewGroupOptions(crossPlatform: InAppWebViewOptions(javaScriptEnabled: true)),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    if (url != null) {
                      setState(() {
                        _isLoading = true;
                        _updateCurrentPath(url.toString());
                      });
                    }
                  },
                  onLoadStop: (controller, url) {
                    setState(() {
                      _isLoading = false;
                    });
                    _injectCSS();
                  },
                ),
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
