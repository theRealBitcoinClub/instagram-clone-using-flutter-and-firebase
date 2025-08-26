import 'dart:async'; // For TimeoutException

import 'package:http/http.dart' as http;

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

// Example Usage (similar to the HttpClient example):
// void main() async {
//   String validUrl = "https://www.google.com";
//   String likely404Url = "https://jsonplaceholder.typicode.com/nonexistentpath";

//   bool is404_1 = await checkUrlFor404WithHttpPackage(validUrl);
//   print('$validUrl is 404 (http package): $is404_1\n');

//   bool is404_2 = await checkUrlFor404WithHttpPackage(likely404Url);
//   print('$likely404Url is 404 (http package): $is404_2\n');
// }
