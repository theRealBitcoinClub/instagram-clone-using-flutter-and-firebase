import 'package:http/http.dart' as http;

class YouTubeVideoChecker {
  /// Checks if a YouTube video exists and is available
  /// Returns true if video is available, false if removed or unavailable
  static Future<bool> isVideoAvailable(String videoId) async {
    try {
      // Method 1: Check using YouTube oembed API (more reliable)
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
      final response = await http.get(Uri.parse(oembedUrl));

      // If oembed returns 200, video exists and is embeddable
      if (response.statusCode == 200) {
        return true;
      }

      // Method 2: Fallback - check video page directly
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final videoResponse = await http.head(Uri.parse(videoUrl));

      // YouTube returns 200 for available videos, 404 for removed videos
      return videoResponse.statusCode == 200;
    } catch (e) {
      // If any error occurs, assume video might be unavailable
      return false;
    }
  }

  /// Checks if a video is available and provides detailed status information
  static Future<YouTubeVideoStatus> checkVideoStatus(String videoId) async {
    try {
      // Check oembed first (most reliable for embed availability)
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
      final oembedResponse = await http.get(Uri.parse(oembedUrl));

      if (oembedResponse.statusCode == 200) {
        return YouTubeVideoStatus.available();
      }

      if (oembedResponse.statusCode == 404) {
        return YouTubeVideoStatus.removed();
      }

      // Check video page directly
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final videoResponse = await http.head(Uri.parse(videoUrl));

      if (videoResponse.statusCode == 200) {
        // Video exists but might have embedding restrictions
        return YouTubeVideoStatus.restricted();
      } else if (videoResponse.statusCode == 404) {
        return YouTubeVideoStatus.removed();
      } else {
        return YouTubeVideoStatus.unknown();
      }
    } catch (e) {
      return YouTubeVideoStatus.error(e.toString());
    }
  }
}

class YouTubeVideoStatus {
  final bool isAvailable;
  final bool isRemoved;
  final bool hasRestrictions;
  final String? error;
  final String? details;

  YouTubeVideoStatus({required this.isAvailable, required this.isRemoved, required this.hasRestrictions, this.error, this.details});

  factory YouTubeVideoStatus.available() =>
      YouTubeVideoStatus(isAvailable: true, isRemoved: false, hasRestrictions: false, details: 'Video is available and embeddable');

  factory YouTubeVideoStatus.removed() =>
      YouTubeVideoStatus(isAvailable: false, isRemoved: true, hasRestrictions: false, details: 'Video has been removed from YouTube');

  factory YouTubeVideoStatus.restricted() =>
      YouTubeVideoStatus(isAvailable: false, isRemoved: false, hasRestrictions: true, details: 'Video exists but has embedding restrictions');

  factory YouTubeVideoStatus.unknown() =>
      YouTubeVideoStatus(isAvailable: false, isRemoved: false, hasRestrictions: false, details: 'Unable to determine video status');

  factory YouTubeVideoStatus.error(String errorMessage) => YouTubeVideoStatus(
    isAvailable: false,
    isRemoved: false,
    hasRestrictions: false,
    error: errorMessage,
    details: 'Error checking video status',
  );

  @override
  String toString() {
    if (isAvailable) return 'Available';
    if (isRemoved) return 'Removed';
    if (hasRestrictions) return 'Restricted';
    if (error != null) return 'Error: $error';
    return 'Unknown';
  }
}
