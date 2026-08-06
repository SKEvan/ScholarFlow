import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'backend_config.dart';

class BackendApi {
  BackendApi._();

  static Future<String> get baseUrl async {
    await BackendConfig.load();
    return BackendConfig.baseUrl;
  }

  static Future<String> _connectionHint(Object error) async {
    final host = Uri.tryParse(await baseUrl)?.host ?? '';
    final isLocalHost = host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2';
    if (error is SocketException && isLocalHost) {
      return 'Backend not reachable from this device. Set BACKEND_BASE_URL to https://scholarflow-i4bq.onrender.com or deploy the backend URL in app settings.';
    }
    return error.toString();
  }

  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on SocketException catch (error) {
      throw Exception(await _connectionHint(error));
    } on http.ClientException catch (error) {
      throw Exception(await _connectionHint(error));
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
        Uri.parse('${BackendConfig.baseUrl}/projects/research'),
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

  static Future<List<Map<String, dynamic>>> listProjects() async {
    final response = await _send(() => http.get(Uri.parse('${BackendConfig.baseUrl}/projects')));

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
    final response = await _send(() => http.get(Uri.parse('${BackendConfig.baseUrl}/projects/$projectId/repository')));

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
        Uri.parse('${BackendConfig.baseUrl}$endpoint'),
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
        Uri.parse('${BackendConfig.baseUrl}/projects/$projectId/versions/save'),
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
        Uri.parse('${BackendConfig.baseUrl}/projects/$projectId/versions/restore'),
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