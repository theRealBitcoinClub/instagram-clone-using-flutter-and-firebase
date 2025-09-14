import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final youtubeVideoAvailabilityChecker = FutureProvider.family<bool, String>((ref, videoId) async {
  try {
    // You could add actual image validation logic here
    // For example, check if the image exists or is accessible
    // This is just a placeholder - implement your actual validation logic
    return YouTubeVideoChecker().isVideoAvailable(videoId);
  } catch (e) {
    return false;
  }
});

class YouTubeVideoChecker {
  Future<bool> isVideoAvailable(String videoId) async {
    try {
      // Method 1: Check using YouTube oembed API (more reliable)
      final oembedUrl = 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json';
      final response = await http.get(Uri.parse(oembedUrl));
      // Check if response contains "Not Found" (case insensitive)
      final responseBody = response.body.toLowerCase();
      if (responseBody.contains('not found') ||
          responseBody.contains('this video isn\'t available') ||
          responseBody.contains('video unavailable')) {
        return false;
      }

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
