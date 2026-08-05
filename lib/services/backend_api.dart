import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApi {
  BackendApi._();

  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> researchProject(
    String title, {
    String desiredOutputType = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projects/research'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'desired_output_type': desiredOutputType,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected backend response shape.');
  }
}