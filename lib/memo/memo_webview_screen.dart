// screens/memo_webview_screen.dart
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/tab_item_data.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../provider/user_provider.dart';
import '../providers/webview_providers.dart';
import 'css_injector.dart';

// Add this provider to your webview_providers.dart or navigation_providers.dart
// final targetUrlProvider = StateProvider<String?>((ref) => null);

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
  bool _isCustomUrl = false;
  bool _shouldInjectCss = true; // Track whether CSS should be injected for current URL
  bool _hasInternetConnection = true; // Track internet connection status

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  // Method to check internet connection
  Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _hasInternetConnection = false;
        });
        return;
      }

      // Additional check with HTTP request to Google
      context.afterBuild(() async {
        _hasInternetConnection = await _testInternetConnection();
      }, refreshUI: true);

      // setState(() {
      //   _hasInternetConnection = response;
      // });
    } catch (e) {
      setState(() {
        _hasInternetConnection = false;
      });
    }
  }

  // Test internet connection by making a HEAD request to Google
  Future<bool> _testInternetConnection() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.headUrl(Uri.parse('https://www.google.com'));
      final response = await request.close();

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Helper method to determine the initial URL
  String _getInitialUrl() {
    final tagId = ref.read(tagIdProvider);
    final topicId = ref.read(topicIdProvider);
    final targetUrl = ref.read(targetUrlProvider);

    // Priority 1: Custom target URL
    if (targetUrl != null && targetUrl.isNotEmpty) {
      _isCustomUrl = true;
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(targetUrlProvider.notifier).state = null;
      });
      return targetUrl;
    }
    // Priority 2: Tag ID
    else if (tagId != null && tagId.isNotEmpty) {
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tagIdProvider.notifier).state = null;
      });
      return '$_baseUrl/t/$tagId?p=new';
    }
    // Priority 3: Topic ID
    else if (topicId != null && topicId.isNotEmpty) {
      // Reset provider after reading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(topicIdProvider.notifier).state = null;
      });
      return '$_baseUrl/topic/$topicId';
    }
    // Default: Login page
    else {
      return '$_baseUrl/login';
    }
  }

  void _updateCurrentPath(String url) {
    final uri = Uri.parse(url);
    setState(() {
      _currentPath = uri.path.isEmpty ? '/' : uri.path;
    });
  }

  void _loadUrl(String url) {
    if (!_hasInternetConnection) {
      _checkInternetConnection(); // Re-check connection
      return;
    }

    // Determine if CSS should be injected for this URL
    final bool shouldInject =
        !url.contains('/logout') &&
        !_isCustomUrl &&
        !url.contains('target-specific-page') && // Add other URLs that shouldn't have CSS
        url.startsWith(_baseUrl);

    setState(() {
      _displayInAppBar = "$url requested ...";
      context.showSnackBar(_displayInAppBar, type: SnackbarType.success);
      _isLoading = true;
      _cssInjected = false;
      _shouldInjectCss = shouldInject;
    });

    // Use loadUrl() from InAppWebViewController
    _webViewController.loadUrl(urlRequest: URLRequest(url: WebUri.uri(Uri.parse(url))));
  }

  void _loadProfile() {
    ref.read(targetUrlProvider.notifier).state = null;
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    final user = ref.read(userProvider)!;
    _loadUrl('$_baseUrl/profile/${user.id}');
  }

  void _loadFeed() {
    ref.read(targetUrlProvider.notifier).state = null;
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    _loadUrl('$_baseUrl/login');
  }

  void _loadTags() {
    final tagId = ref.read(tagIdProvider);

    ref.read(targetUrlProvider.notifier).state = null;
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

    ref.read(targetUrlProvider.notifier).state = null;
    ref.read(tagIdProvider.notifier).state = null;
    ref.read(topicIdProvider.notifier).state = null;

    if (topicId != null && topicId.isNotEmpty) {
      _loadUrl('$_baseUrl/topic/$topicId');
    } else {
      _loadUrl('$_baseUrl/topics');
    }
  }

  Future<void> _injectCSS() async {
    final result = await CssInjector.injectCSS(webViewController: _webViewController, context: context, isDarkTheme: _isDarkTheme);

    setState(() {
      _cssInjected = result;
    });
  }

  // Method to retry internet connection
  Future<void> _retryConnection() async {
    setState(() {
      _isLoading = true;
    });

    await _checkInternetConnection();

    if (_hasInternetConnection) {
      // Reload the current page or initial URL
      _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext buildCtx) {
    final theme = Theme.of(buildCtx);
    _isDarkTheme = theme.brightness == Brightness.dark;

    return Consumer(
      builder: (consumerCtx, ref, child) {
        // Listen to provider changes and load appropriate URLs
        ref.listen(targetUrlProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _isCustomUrl = true;
            _loadUrl(next);
          }
        });

        ref.listen(tagIdProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _isCustomUrl = false;
            _loadUrl('$_baseUrl/t/$next?p=new');
          }
        });

        ref.listen(topicIdProvider, (previous, next) {
          if (next != null && next.isNotEmpty) {
            _isCustomUrl = false;
            _loadUrl('$_baseUrl/topic/$next');
          }
        });

        return Scaffold(
          appBar: _isCustomUrl
              ? null
              : AppBar(
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
                  ],
                ),
          body: SafeArea(
            child: Stack(
              children: [
                // Internet connection error overlay
                if (!_hasInternetConnection)
                  Positioned.fill(
                    child: Container(
                      color: theme.scaffoldBackgroundColor.withOpacity(0.95),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, size: 64, color: theme.colorScheme.error),
                              const SizedBox(height: 20),
                              Text(
                                'No Internet Connection',
                                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Please check your internet connection and try again.',
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Make sure your Wi-Fi or mobile data is enabled and working properly.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: _retryConnection,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry Connection'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  // Open device settings
                                  // Note: You might need a package like 'app_settings' for this
                                  // app_settings.AppSettings.openAppSettings();
                                },
                                child: Text('Open Phone Settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // WebView content (only visible when there's internet connection)
                if (_hasInternetConnection)
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
                            if (ref.read(currentTabIndexProvider) == AppTab.memo.tabIndex)
                              showSnackBar(_displayInAppBar, buildCtx, type: SnackbarType.info);
                            _updateCurrentPath(url.toString());
                          });
                        }
                      },
                      onLoadStop: (controller, url) async {
                        // Only inject CSS if it should be injected for this URL
                        if (_shouldInjectCss) {
                          await _injectCSS();
                        } else {
                          // If CSS shouldn't be injected, mark as complete immediately
                          setState(() {
                            _cssInjected = true;
                          });
                        }

                        setState(() {
                          // if (ref.read(tabIndexProvider) == AppTab.memo.tabIndex)
                          // showSnackBar("Enjoy the content!", context, type: SnackbarType.success);
                          _updateCurrentPath(url.toString());
                          // Only hide loading if CSS injection is complete
                          _isLoading = !_cssInjected;
                        });
                      },
                    ),
                  ),

                // Loading overlay that covers the whole WebView container
                if (_isLoading && _hasInternetConnection)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(consumerCtx).brightness == Brightness.dark
                          ? Colors.black.withOpacity(222 / 255) // Black with 222 alpha for dark mode
                          : Colors.white.withOpacity(222 / 255), // White with 222 alpha for light mode
                    ),
                  ),

                // Your loading indicator (positioned above the overlay)
                if (_isLoading && _hasInternetConnection)
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
