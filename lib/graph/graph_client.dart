import 'dart:convert';

import 'package:http/http.dart' as http;

class GraphQLClient {
  static const String _baseUrl = 'https://graph.cash/graphql';

  final http.Client _client;

  GraphQLClient({http.Client? client}) : _client = client ?? http.Client();

  Future<GraphQLResponse> query(String query, {Map<String, dynamic>? variables}) async {
    try {
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'query': query, 'variables': variables ?? {}}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return GraphQLResponse.fromJson(jsonResponse);
      } else {
        throw GraphQLException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw GraphQLException('Network error: $e');
    }
  }

  void close() {
    _client.close();
  }
}

class GraphQLResponse {
  final Map<String, dynamic>? data;
  final List<dynamic>? errors;

  GraphQLResponse({this.data, this.errors});

  factory GraphQLResponse.fromJson(Map<String, dynamic> json) {
    return GraphQLResponse(data: json['data'], errors: json['errors']);
  }

  bool get hasErrors => errors != null && errors!.isNotEmpty;
}

class GraphQLException implements Exception {
  final String message;

  GraphQLException(this.message);

  @override
  String toString() => 'GraphQLException: $message';
}
