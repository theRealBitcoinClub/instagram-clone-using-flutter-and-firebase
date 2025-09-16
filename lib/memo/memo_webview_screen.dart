// screens/memo_webview_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/navigation_providers.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/utils/snackbar.dart';

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
  bool _cssInjected = false; // Track if CSS has been injected
  String _displayInAppBar = "";

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
      return '$_baseUrl/t/$tagId?p=new';
    } else if (topicId != null && topicId.isNotEmpty) {
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(topicIdProvider.notifier).state = null;
      });
      return '$_baseUrl/topic/$topicId';
    } else {
      return '$_baseUrl/login';
      // _loadFeed();
      // Default to profile if no providers have values
      // final user = ref.read(userProvider)!;
      // return '$_baseUrl/profile/${user.id}';
    }
  }

  void _updateCurrentPath(String url) {
    final uri = Uri.parse(url);
    setState(() {
      _currentPath = uri.path.isEmpty ? '/' : uri.path;
    });
  }

  void _loadUrl(String url) {
    // Reset CSS injection state when loading a new URL
    setState(() {
      _displayInAppBar = "$url requested ...";
      showSnackBar(_displayInAppBar, context, type: SnackbarType.success);
      _isLoading = true;
      _cssInjected = false;
    });

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

    _loadUrl('$_baseUrl/login');
  }

  void _loadTags() {
    final tagId = ref.read(tagIdProvider);

    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    if (tagId != null && tagId.isNotEmpty) {
      _loadUrl('$_baseUrl/t/$tagId/?p=new');
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
    // final theme = Theme.of(context);
    final theme = Theme.of(context);
    _isDarkTheme = theme.brightness == Brightness.dark;

    // Define theme colors
    // final backgroundColor = _isDarkTheme ? '#121212' : '#f8f8f8';
    final backgroundColor = _isDarkTheme ? '#121212' : '#f8f8f8';
    final textColor = _isDarkTheme ? '#d2d2d2' : '#000';
    final postBackground = _isDarkTheme ? '#1e1e1e' : '#fff';
    final postOddBackground = _isDarkTheme ? '#2a2a2a' : '#f8f8f8';
    final borderColor = _isDarkTheme ? '#333' : '#e8e8e8';
    final nameColor = _isDarkTheme ? '#e0e0e0' : '#555';
    final profileColor = _isDarkTheme ? '#d2d2d2' : '#333';
    final linkColor = _isDarkTheme ? '#6eb332' : '#487521';
    final normalLinkColor = _isDarkTheme ? '#e0e0e0' : '#444';
    final mutedTextColor = _isDarkTheme ? '#a0a0a0' : '#666';
    final inputBackground = _isDarkTheme ? '#2d2d2d' : '#fff';
    final inputBorderColor = _isDarkTheme ? '#444' : '#ccc';
    final buttonBackground = _isDarkTheme ? '#2d2d2d' : '#f0f0f0';
    final buttonHoverBackground = _isDarkTheme ? '#3d3d3d' : '#e0e0f0';
    final shadowColor = _isDarkTheme ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)';

    String css =
        '''
      <style>
      
        /* Hide navigation and other unwanted elements */
        .reputation-tooltip,
        .pagination-center,
        .load-more-wrapper,
        .center,
        .form-new-topic-message,
        .block-explorer,
        .actions,
        .pagination-right,
        .topics-index-head,
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

        /* Global styles */
        * {
          box-sizing: border-box !important;
        }
        
        body {
          margin: 0 !important;
          padding: 0 !important;
          overflow-x: hidden !important;
          background: $backgroundColor !important;
          color: $textColor !important;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif !important;
        }

        /* Container adjustments */
        .container {
          width: 100% !important;
          max-width: 100% !important;
          padding: 0 12px !important;
          margin-top: 0 !important;
        }

        /* Post styling */
        .post {
          background: $postBackground !important;
          border: 1px solid $borderColor !important;
          border-radius: 12px !important;
          margin: 16px 0 !important;
          padding: 16px !important;
          box-shadow: 0 2px 8px $shadowColor !important;
        }

        .post.post-odd {
          background: $postOddBackground !important;
        }

        /* Post header elements */
        .post .name .post-header {
          color: $nameColor !important;
          font-weight: bold !important;
          font-size: 16px !important;
          margin-bottom: 4px !important;
        }

        .post .name .profile {
          color: $profileColor !important;
          text-decoration: none !important;
        }

        .post .text-muted {
          color: $mutedTextColor !important;
          font-size: 14px !important;
        }

        /* Post content */
        .post .content .message {
          color: $textColor !important;
          font-size: 16px !important;
          line-height: 1.5 !important;
          margin: 12px 0 !important;
          word-break: break-word !important;
        }

        .post .content p {
          margin: 8px 0 !important;
        }

        /* Links */
        a {
          color: $linkColor !important;
          text-decoration: none !important;
        }

        a:hover {
          text-decoration: underline !important;
        }

        a.normal {
          color: $normalLinkColor !important;
        }

        /* Buttons and interactive elements */
        .btn {
          background: $buttonBackground !important;
          color: $textColor !important;
          border: 1px solid $inputBorderColor !important;
          border-radius: 4px !important;
          padding: 6px 12px !important;
        }

        .btn:hover {
          background: $buttonHoverBackground !important;
        }

        /* Input fields */
        .form-control {
          color: $textColor !important;
          background: $inputBackground !important;
          border: 1px solid $inputBorderColor !important;
          border-radius: 4px !important;
          padding: 8px 12px !important;
        }

        /* Remove any fixed positioning that might cause issues */
        #site-wrapper.active,
        #site-wrapper-cover.active {
          position: relative !important;
          overflow: visible !important;
          height: auto !important;
        }

        /* Additional post elements */
        .post .actions {
          border-top: 1px solid $borderColor !important;
          padding-top: 12px !important;
          margin-top: 12px !important;
        }

        .post .actions a {
          margin-right: 16px !important;
          font-size: 14px !important;
        }

        .post .media {
          margin: 12px 0 !important;
          border-radius: 8px !important;
          overflow: hidden !important;
        }

        .post .badge {
          background: $buttonBackground !important;
          color: $textColor !important;
          border: 1px solid $inputBorderColor !important;
          border-radius: 4px !important;
          padding: 2px 6px !important;
          font-size: 11px !important;
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
            margin-top: 5px 0 !important;
            border-radius: 0 !important;
            padding: 2px !important;
            box-shadow: none !important;
          }
          
          .container {
            padding: 0 8px !important;
          }
          
          .post, .content {
            font-size: 11px !important;
          }
          
        
          #all-posts {
              max-height: max-content;
          }
        
        }
        
        #all-posts {
            max-height: max-content;
        }
        
        .message, .post-header, .name, .message-feed-item, .mini-profile-name {
          background: $postBackground !important;
        }
        
        /*.message .post-header .name .message-feed-item {
          background: #ccc !important;
        }*/
      </style>
    ''';

    try {
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
            '.pagination-center',
            '.load-more-wrapper',
            '.center',
            '.form-new-topic-message',
            '.block-explorer',
            '.actions',
            '.pagination-right',
            '.topics-index-head',
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
          document.body.style.backgroundColor = '$backgroundColor';
          document.body.style.color = '$textColor';
          
          // Add dark class if needed
          if ($_isDarkTheme) {
            document.body.classList.add('dark');
          } else {
            document.body.classList.remove('dark');
          }
          
          // Additional theme-specific adjustments
          var allElements = document.querySelectorAll('*');
          allElements.forEach(function(el) {
            // Fix any remaining background colors
            var bgColor = window.getComputedStyle(el).backgroundColor;
            if (bgColor === 'rgb(248, 248, 248)' || bgColor === 'rgba(0, 0, 0, 0)') {
              el.style.backgroundColor = '$_isDarkTheme' ? '$backgroundColor' : '$postBackground';
            }
            
            // Fix any remaining text colors
            var txtColor = window.getComputedStyle(el).color;
            if (txtColor === 'rgb(0, 0, 0)' || txtColor === 'rgb(51, 51, 51)') {
              el.style.color = '$textColor';
            }
          });
          
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

      // Mark CSS as injected and hide loading indicator
      setState(() {
        _cssInjected = true;
      });
    } catch (e) {
      // If injection fails, still mark as injected to avoid infinite loading
      setState(() {
        _cssInjected = true;
      });
    }
  }

  @override
  Widget build(BuildContext buildCtx) {
    final theme = Theme.of(buildCtx);
    _isDarkTheme = theme.brightness == Brightness.dark;

    return Consumer(
      builder: (consumerCtx, ref, child) {
        // Listen to provider changes and load appropriate URLs
        ref.listen(tagIdProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _loadUrl('$_baseUrl/t/$next?p=new');
          }
        });

        ref.listen(topicIdProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _loadUrl('$_baseUrl/topic/$next');
          }
        });

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 50,
            centerTitle: false,
            titleSpacing: NavigationToolbar.kMiddleSpacing,

            // _loadUrl('$_baseUrl/logout')
            leading: IconButton(
              icon: const Icon(size: 30, Icons.account_circle_outlined),
              tooltip: "Feed",
              onPressed: () {
                _loadFeed();
              },
            ),
            // leading: IconButton(icon: const Icon(size: 30, Icons.person_outline), tooltip: "My Profile", onPressed: _loadProfile),
            title: !_isLoading
                ? Row(
                    children: [
                      GestureDetector(onTap: _loadFeed, child: Text("LOGIN")),
                      Spacer(),
                      GestureDetector(onTap: _loadLogout, child: Text("LOGOUT")),
                    ],
                  )
                : Text(
                    _displayInAppBar,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: (theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface).withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
            actions: [
              IconButton(
                icon: const Icon(size: 27, Icons.logout_rounded),
                tooltip: "Logout",
                onPressed: () {
                  _loadLogout();
                },
              ),
              // IconButton(icon: const Icon(size: 26, Icons.tag_outlined), tooltip: "Tags", onPressed: _loadTags),
              // IconButton(icon: const Icon(size: 26, Icons.alternate_email_rounded), tooltip: "Topics", onPressed: _loadTopics),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // Add a container that constraints the WebView
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(consumerCtx).size.width),
                  child: InAppWebView(
                    // Your existing WebView configuration
                    initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(_getInitialUrl()))),
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        javaScriptEnabled: true,
                        // Disable horizontal scrolling in WebView
                        disableHorizontalScroll: true,
                      ),
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      if (url != null) {
                        setState(() {
                          _isLoading = true;
                          _cssInjected = false; // Reset CSS injection state
                          _displayInAppBar = url.toString() + " is loading ...";
                          if (ref.read(tabIndexProvider) == AppTab.memo.tabIndex)
                            showSnackBar(_displayInAppBar, buildCtx, type: SnackbarType.info);
                          _updateCurrentPath(url.toString());
                        });
                      }
                    },
                    onLoadStop: (controller, url) async {
                      // Wait for CSS injection to complete before hiding loading indicator
                      await _injectCSS();
                      setState(() {
                        if (ref.read(tabIndexProvider) == AppTab.memo.tabIndex) showSnackBar("Enjoy the content!", context, type: SnackbarType.success);
                        _updateCurrentPath(url.toString());
                        // Only hide loading if CSS injection is complete
                        _isLoading = !_cssInjected;
                      });
                    },
                  ),
                ),

                // Loading overlay that covers the whole WebView container
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(consumerCtx).brightness == Brightness.dark
                          ? Colors.black.withOpacity(222 / 255) // Black with 222 alpha for dark mode
                          : Colors.white.withOpacity(222 / 255), // White with 222 alpha for light mode
                    ),
                  ),

                // Your loading indicator (positioned above the overlay)
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

  void _loadLogout() {
    _loadUrl('$_baseUrl/logout');
  }
}
