import 'dart:async'; // For TimeoutException

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class MemoDataChecker {
  // Utility function using the 'http' package
  Future<bool> checkUrlReturns404(String urlString) async {
    try {
      Uri uri = Uri.parse(urlString);
      // You can use http.get() for simple GET or http.head() if you only need status
      // http.head() is often more efficient if you don't need the body.
      final response = await http.head(uri).timeout(const Duration(seconds: 3));
      // Or: final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        print('URL $urlString returned 404 Not Found (http package).');
        return true; // Indicates 404 was received
      } else {
        print('URL $urlString returned status code: ${response.statusCode} (http package).');
        return false; // Not a 404
      }
    } on http.ClientException catch (e) {
      // More specific exception from the http package
      // This can cover various network issues like SocketException, HandshakeException etc.
      print('Client error checking URL $urlString (http package): $e');
      return false;
    } on TimeoutException catch (e) {
      print('Timeout error checking URL $urlString (http package): $e');
      return false;
    } on FormatException catch (e) {
      print('Invalid URL format for $urlString (http package): $e');
      return false;
    } catch (e) {
      print('Unexpected error checking URL $urlString (http package): $e');
      return false;
    }
  }

  Future<bool> isImageValid(String url) async {
    Completer<bool> completer = Completer<bool>();
    final Image image = Image.network(url);
    print("URL: ${url} isImageValid height ${image.height} width ${image.width}");
    final ImageStream stream = image.image.resolve(const ImageConfiguration());

    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        // The image loaded successfully
        if (!completer.isCompleted) {
          print("isImageValid height info ${image.image.height} width info ${image.image.width}");
          if (image.image.height == 81 && image.image.width == 161) //THE STANDARD ERROR IMGURL
            completer.complete(false);
          else
            completer.complete(true);
        }
        stream.removeListener(listener!);
      },
      onError: (Object exception, StackTrace? stackTrace) {
        // An error occurred during image loading
        if (!completer.isCompleted) {
          print("ERROR isImageValid");
          completer.complete(false);
        }
        stream.removeListener(listener!);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}
