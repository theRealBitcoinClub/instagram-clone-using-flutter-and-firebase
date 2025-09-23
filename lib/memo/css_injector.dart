// utils/css_injector.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class CssInjector {
  static Future<bool> injectCSS({
    required InAppWebViewController webViewController,
    required BuildContext context,
    required bool isDarkTheme,
  }) async {
    // Define theme colors
    final backgroundColor = isDarkTheme ? '#121212' : '#f8f8f8';
    final textColor = isDarkTheme ? '#d2d2d2' : '#000';
    final postBackground = isDarkTheme ? '#1e1e1e' : '#fff';
    final postOddBackground = isDarkTheme ? '#2a2a2a' : '#f8f8f8';
    final borderColor = isDarkTheme ? '#333' : '#e8e8e8';
    final nameColor = isDarkTheme ? '#e0e0e0' : '#555';
    final profileColor = isDarkTheme ? '#d2d2d2' : '#333';
    final linkColor = isDarkTheme ? '#6eb332' : '#487521';
    final normalLinkColor = isDarkTheme ? '#e0e0e0' : '#444';
    final mutedTextColor = isDarkTheme ? '#a0a0a0' : '#666';
    final inputBackground = isDarkTheme ? '#2d2d2d' : '#fff';
    final inputBorderColor = isDarkTheme ? '#444' : '#ccc';
    final buttonBackground = isDarkTheme ? '#2d2d2d' : '#f0f0f0';
    final buttonHoverBackground = isDarkTheme ? '#3d3d3d' : '#e0e0f0';
    final shadowColor = isDarkTheme ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.1)';

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
      await webViewController.evaluateJavascript(
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
          if ($isDarkTheme) {
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
              el.style.backgroundColor = '$isDarkTheme' ? '$backgroundColor' : '$postBackground';
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

      return true;
    } catch (e) {
      // If injection fails, return false
      return false;
    }
  }
}
