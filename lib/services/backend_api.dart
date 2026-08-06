import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class BackendApi {
  BackendApi._();

  static const String baseUrl = 'https://scholarflow-i4bq.onrender.com';

  static String _connectionHint(Object error) {
    if (error is SocketException) {
      return 'Backend not reachable at $baseUrl. Please verify the Render service is live.';
    }
    return error.toString();
  }

  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on SocketException catch (error) {
      throw Exception(_connectionHint(error));
    } on http.ClientException catch (error) {
      throw Exception(_connectionHint(error));
    }
  }

  static Future<Map<String, dynamic>> createProjectAndResearch(
    String title, {
    int? ownerId,
    String description = '',
    String status = 'active',
    String? startDate,
    String? deadline,
    List<String> collaborators = const [],
    String desiredOutputType = '',
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'status': status,
      'desired_output_type': desiredOutputType,
      'collaborators': collaborators,
    };
    if (startDate != null) {
      payload['start_date'] = startDate;
    }
    if (deadline != null) {
      payload['deadline'] = deadline;
    }
    if (ownerId != null) {
      payload['owner_id'] = ownerId;
    }

    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/projects/research'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ),
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

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String fullName = '',
    String university = '',
    String role = '',
    String researchInterest = '',
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'university': university,
          'role': role,
          'research_interest': researchInterest,
        }),
      ),
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

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ),
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

  static Future<List<Map<String, dynamic>>> listProjects() async {
    final response = await _send(() => http.get(Uri.parse('$baseUrl/projects')));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final projects = decoded is Map<String, dynamic> ? decoded['projects'] : null;
    if (projects is List) {
      return projects.whereType<Map>().map((project) => Map<String, dynamic>.from(project)).toList();
    }

    throw Exception('Unexpected backend response shape.');
  }

  static Future<Map<String, dynamic>> getProjectRepository(int projectId) async {
    final response = await _send(() => http.get(Uri.parse('$baseUrl/projects/$projectId/repository')));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected backend response shape.');
  }

  static Future<Map<String, dynamic>> runProjectAgent({
    required int projectId,
    required String endpoint,
    required String desiredOutputType,
    required String userPrompt,
    required List<int> selectedPaperIds,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'project_id': projectId,
        'desired_output_type': desiredOutputType,
        'user_prompt': userPrompt,
        'selected_paper_ids': selectedPaperIds,
      }),
      ),
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

  static Future<Map<String, dynamic>> saveVersion({
    required int projectId,
    required String snapshotName,
    String versionMessage = '',
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/projects/$projectId/versions/save'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'snapshot_name': snapshotName,
        'version_message': versionMessage,
      }),
      ),
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

  static Future<Map<String, dynamic>> restoreVersion({
    required int projectId,
    required int versionId,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/projects/$projectId/versions/restore'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'version_id': versionId,
      }),
      ),
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