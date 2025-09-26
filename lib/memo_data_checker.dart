import 'dart:async'; // For TimeoutException

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/memo/memo_reg_exp.dart';

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

  Future<bool> isImageValid({imageFile, url}) async {
    if (url.isEmpty || MemoRegExp.extractUrls(url).isEmpty || url.length > 256) return false;

    Completer<bool> completer = Completer<bool>();
    final Image image = imageFile != null ? Image.file(imageFile) : Image.network(url);
    print("URL: ${url} isImageValidCHECK height ${image.height} width ${image.width}");
    final ImageStream stream = image.image.resolve(const ImageConfiguration());
    print("URL: ${url} isImageValidRESOLVE height ${image.height} width ${image.width}");

    ImageStreamListener? listener;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        // The image loaded successfully
        if (!completer.isCompleted) {
          print("isImageValid height info ${image.image.height} width info ${image.image.width}");
          if (image.image.height == 81 && image.image.width == 161) {
            //THE STANDARD ERROR IMGURL
            print("INVALID IMAGE FOUND URL: ${url}");
            completer.complete(false);
          } else {
            print("VALID IMAGE FOUND URL: ${url}");
            completer.complete(true);
          }
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

final imageValidationProvider = FutureProvider.family<bool, String>((ref, imageUrl) async {
  try {
    // You could add actual image validation logic here
    // For example, check if the image exists or is accessible
    // This is just a placeholder - implement your actual validation logic
    return MemoDataChecker().isImageValid(url: imageUrl);
  } catch (e) {
    return false;
  }
});
