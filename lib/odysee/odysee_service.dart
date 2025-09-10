// services/odysee_service.dart
import 'dart:convert';

import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

class OdyseeService {
  final String baseUrl = 'https://api.odysee.com';
  final http.Client client;

  OdyseeService({required this.client});

  Future<String> getVideoStreamUrl(String odyseeUrl) async {
    try {
      final response = await http.get(Uri.parse(odyseeUrl));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final scriptTag = document.querySelector('script[type="application/ld+json"]');

        if (scriptTag != null) {
          final jsonText = scriptTag.text;
          final jsonData = jsonDecode(jsonText);

          // Return the contentUrl which is the direct link
          var contentUrl = jsonData['contentUrl'];
          return contentUrl;
        }
      }
    } catch (e) {
      print("Error getting Odysee stream URL: $e");
    }
    return "null";
  }

  void dispose() {
    client.close();
  }
}
