import 'dart:async';
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
    String? ownerId,                          // UUID → String (was int?)
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
      payload['owner_id'] = ownerId;             // now a String UUID
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
    String avatarUrl = '',
    String university = '',
    String role = '',
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
          'avatar_url': avatarUrl,
          'university': university,
          'role': role,
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

  static Future<Map<String, dynamic>> profileStatus(String userId) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/auth/profile-status'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
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

  static Future<Map<String, dynamic>> completeProfile({
    required String userId,
    required String fullName,
    String avatarUrl = '',
    String university = '',
    String role = '',
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/auth/complete-profile'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'full_name': fullName,
          'avatar_url': avatarUrl,
          'university': university,
          'role': role,
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

  static Future<List<Map<String, dynamic>>> listProjects({String? ownerId}) async {
    final uri = Uri.parse('$baseUrl/projects').replace(
      queryParameters: ownerId != null ? {'owner_id': ownerId} : null,
    );
    final response = await _send(() => http.get(uri));

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

  static Future<Map<String, dynamic>> getProjectRepository(String projectId) async {
    // UUID → String (was int). Previously sent /projects/123/repository
    // which FastAPI rejected since the route expects a UUID string.
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/projects/$projectId/repository')),
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

  static Future<Map<String, dynamic>> getProjectSearchStatus(String projectId) async {
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/projects/$projectId/search-status')),
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

  static Future<Map<String, dynamic>> runProjectAgent({
    required String projectId,                   // UUID → String (was int)
    required String endpoint,
    required String desiredOutputType,
    required String userPrompt,
    required List<String> selectedPaperIds,       // UUID → List<String> (was List<int>)
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'project_id': projectId,               // String UUID
          'desired_output_type': desiredOutputType,
          'user_prompt': userPrompt,
          'selected_paper_ids': selectedPaperIds, // List<String> UUIDs
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

  /// Open a streaming POST to the matching `/agents/{name}/stream` endpoint.
  ///
  /// [endpoint] should be one of `/agents/summary`, `/agents/comparison`,
  /// `/agents/research-gap`, or `/agents/literature-review`. The returned
  /// handle exposes the decoded SSE event stream; call [AgentStreamHandle.cancel]
  /// to abort the request (which closes the server-side generator).
  static AgentStreamHandle runProjectAgentStream({
    required String projectId,
    required String endpoint,
    required String desiredOutputType,
    required String userPrompt,
    required List<String> selectedPaperIds,
  }) {
    final streamEndpoint = '$endpoint/stream';
    final client = http.Client();
    final controller = StreamController<AgentStreamEvent>();

    Future<void> run() async {
      final request = http.StreamedRequest(
        'POST',
        Uri.parse('$baseUrl$streamEndpoint'),
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      });
      final payload = jsonEncode({
        'project_id': projectId,
        'desired_output_type': desiredOutputType,
        'user_prompt': userPrompt,
        'selected_paper_ids': selectedPaperIds,
      });
      request.sink.add(utf8.encode(payload));
      // Close sink before send() so the request body has a known end.
      unawaited(request.sink.close());

      try {
        final response = await client.send(request);
        if (response.statusCode != 200) {
          final body = await response.stream.bytesToString();
          if (!controller.isClosed) {
            controller.add(
              AgentStreamError._(
                'Backend request failed: ${response.statusCode} '
                '${response.statusCode == 404 ? 'endpoint not registered' : body}',
              ),
            );
          }
          await controller.close();
          client.close();
          return;
        }

        final parser = _SseParser(response.stream, controller);
        await parser.run();
      } catch (error) {
        if (!controller.isClosed) {
          controller.add(AgentStreamError._(error.toString()));
        }
      } finally {
        if (!controller.isClosed) {
          await controller.close();
        }
        try {
          client.close();
        } catch (_) {}
      }
    }

    Future<void> cancel() async {
      try {
        client.close();
      } catch (_) {}
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    run();
    return AgentStreamHandle._(controller.stream, cancel);
  }

  static Future<Map<String, dynamic>> saveVersion({
    required String projectId,                   // UUID → String (was int)
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
    required String projectId,                   // UUID → String (was int)
    required String versionId,                   // UUID → String (was int)
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/projects/$projectId/versions/restore'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version_id': versionId,               // String UUID
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

// ── SSE streaming helpers ────────────────────────────────────────────────────

/// Discriminated event types emitted by an agent stream.
sealed class AgentStreamEvent {
  const AgentStreamEvent();
}

class AgentStreamMeta extends AgentStreamEvent {
  const AgentStreamMeta({required this.tool, required this.outputType});
  final String tool;
  final String outputType;
}

class AgentStreamToken extends AgentStreamEvent {
  const AgentStreamToken(this.delta);
  final String delta;
}

class AgentStreamDone extends AgentStreamEvent {
  const AgentStreamDone(this.result);
  final Map<String, dynamic> result;
}

class AgentStreamError extends AgentStreamEvent {
  AgentStreamError._(this.message);
  final String message;
}

/// A handle returned by [BackendApi.runProjectAgentStream].
class AgentStreamHandle {
  AgentStreamHandle._(this.events, this._cancel);

  final Stream<AgentStreamEvent> events;
  final Future<void> Function() _cancel;

  /// Close the underlying HTTP request. Safe to call multiple times.
  Future<void> cancel() => _cancel();
}

class _SseParser {
  _SseParser(this._source, this._sink);

  final Stream<List<int>> _source;
  final StreamController<AgentStreamEvent> _sink;

  String? _eventName;
  final StringBuffer _dataBuffer = StringBuffer();

  Future<void> run() async {
    final lineStream = _source
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      if (line.isEmpty) {
        _flush();
        continue;
      }
      if (line.startsWith(':')) {
        // SSE comment / keep-alive; ignore.
        continue;
      }
      final colon = line.indexOf(':');
      if (colon == -1) {
        continue;
      }
      final field = line.substring(0, colon);
      var value = line.substring(colon + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      switch (field) {
        case 'event':
          _eventName = value;
          break;
        case 'data':
          if (_dataBuffer.isNotEmpty) {
            _dataBuffer.write('\n');
          }
          _dataBuffer.write(value);
          break;
        default:
          break;
      }
    }

    if (_dataBuffer.isNotEmpty) {
      _flush();
    }
  }

  void _flush() {
    final raw = _dataBuffer.toString();
    _dataBuffer.clear();
    final name = _eventName ?? 'message';
    _eventName = null;
    if (raw.isEmpty) {
      return;
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map) {
      _sink.add(AgentStreamError._('Malformed SSE payload for "$name".'));
      return;
    }
    final data = Map<String, dynamic>.from(decoded);
    switch (name) {
      case 'meta':
        _sink.add(AgentStreamMeta(
          tool: (data['tool'] ?? '').toString(),
          outputType: (data['output_type'] ?? '').toString(),
        ));
      case 'token':
        _sink.add(AgentStreamToken((data['delta'] ?? '').toString()));
      case 'done':
        final result = data['result'];
        if (result is Map) {
          _sink.add(AgentStreamDone(Map<String, dynamic>.from(result)));
        } else {
          _sink.add(AgentStreamError._('"done" event missing result.'));
        }
      case 'error':
        _sink.add(AgentStreamError._((data['message'] ?? 'Unknown error').toString()));
      default:
        // Unknown events are ignored.
        break;
    }
  }
}