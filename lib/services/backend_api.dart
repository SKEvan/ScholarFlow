import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class BackendApi {
  BackendApi._();

  /// Production Render URL. Tests against a locally-running uvicorn on
  /// 127.0.0.1:8765 can override this via [useLocalBackend] /
  /// [useProductionBackend] without rebuilding the app.
  ///
  /// At startup the `--dart-define=BACKEND_URL=…` flag (or env var) takes
  /// priority, so each feature branch can ship its own endpoint without
  /// touching code.
  static String _baseUrl = const String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://scholarflow-i4bq.onrender.com',
  );

  /// Read-only view of the active base URL. Screens / error messages
  /// can show this so users can see which backend they're hitting.
  static String get baseUrl => _baseUrl;

  /// Switch to a local uvicorn instance for development. Pass
  /// `useProductionBackend()` once you're done testing locally to go
  /// back to Render.
  static void useLocalBackend({String host = '127.0.0.1', int port = 8765}) {
    _baseUrl = 'http://$host:$port';
  }

  /// Restore the production Render URL. Call this before releasing
  /// the app or after you've finished local testing.
  static void useProductionBackend() {
    _baseUrl = 'https://scholarflow-i4bq.onrender.com';
  }

  static String _connectionHint(Object error) {
    if (error is SocketException) {
      return 'Backend not reachable at $_baseUrl. '
          'If you expected production, check Render is live. '
          'If testing locally, run '
          '`python -m uvicorn backend.main:app --host 127.0.0.1 --port 8765` '
          'and call `BackendApi.useLocalBackend()`.';
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

  /// Fetch a profile row directly by user id. Returns the same shape as
  /// [profileStatus]: `{"profile": {...}, "missing_fields": [...], "is_complete": bool}`.
  /// Used by the profile screen to render real data instead of the
  /// hardcoded "Dr. Julian Vance" placeholder.
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/profiles/$userId')),
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

  /// Aggregated stats for the profile screen: total citations, total
  /// papers, h-index, recent_projects list. See the backend
  /// `get_profile_stats` method for the full payload shape.
  static Future<Map<String, dynamic>> getProfileStats(String userId) async {
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/profiles/$userId/stats')),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected backend response shape.');
  }

  /// Fetch every research paper across the user's accessible projects
  /// (owned + membered). Returns `{"papers": [...], "total": N}`.
  /// Each paper has `project_id` and `project_title` for grouping.
  static Future<Map<String, dynamic>> listDashboardPapers(String userId) async {
    final uri = Uri.parse('$baseUrl/dashboard/research-papers').replace(
      queryParameters: {'user_id': userId},
    );
    final response = await _send(() => http.get(uri));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
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
    String about = '',
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
          'about': about,
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
    // The deployed Render instance only exposes the non-streaming agent
    // endpoints (e.g. `/agents/summary`). The `/stream` variants aren't
    // registered, so we call the regular endpoint and synthesise a single
    // token + done event from its response.
    final streamEndpoint = endpoint;
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

  // ------------------------------------------------------------------ //
  // Project Members
  // ------------------------------------------------------------------ //

  static const Set<String> _validMemberRoles = {'viewer', 'editor', 'lead'};

  /// Fetches every member of [projectId] with the joined `profiles` payload
  /// (`full_name`, `avatar_url`, `university`, `role`).
  static Future<List<Map<String, dynamic>>> listProjectMembers(
    String projectId,
  ) async {
    final response = await _send(
      () => http.get(Uri.parse('$baseUrl/projects/$projectId/members')),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final members = decoded is Map<String, dynamic> ? decoded['members'] : null;
    if (members is List) {
      return members
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Adds [userId] to [projectId] with the given [role]
  /// (`viewer`, `editor`, or `lead`). [actorUserId] must be the project
  /// owner or the backend will respond with 403.
  static Future<Map<String, dynamic>> addProjectMember({
    required String projectId,
    required String userId,
    required String role,
    required String actorUserId,
  }) async {
    final normalized = role.trim().toLowerCase();
    if (!_validMemberRoles.contains(normalized)) {
      throw Exception(
        'Invalid role "$role". Expected one of $_validMemberRoles.',
      );
    }

    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/projects/$projectId/members'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'role': normalized,
          'actor_user_id': actorUserId,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final member = decoded['member'];
      if (member is Map) {
        return Map<String, dynamic>.from(member);
      }
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Updates the role of an existing member row. [actorUserId] must be
  /// the project owner or the backend will respond with 403.
  static Future<Map<String, dynamic>> updateProjectMemberRole({
    required String projectId,
    required String memberId,
    required String role,
    required String actorUserId,
  }) async {
    final normalized = role.trim().toLowerCase();
    if (!_validMemberRoles.contains(normalized)) {
      throw Exception(
        'Invalid role "$role". Expected one of $_validMemberRoles.',
      );
    }

    final response = await _send(
      () => http.patch(
        Uri.parse('$baseUrl/projects/$projectId/members/$memberId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'role': normalized, 'actor_user_id': actorUserId}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final member = decoded['member'];
      if (member is Map) {
        return Map<String, dynamic>.from(member);
      }
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Removes the member row identified by [memberId] from [projectId].
  /// [actorUserId] must be the project owner or the backend will
  /// respond with 403. To remove yourself as a non-owner, use
  /// [leaveProject] instead.
  static Future<void> removeProjectMember({
    required String projectId,
    required String memberId,
    required String actorUserId,
  }) async {
    final response = await _send(
      () => http.delete(
        Uri.parse('$baseUrl/projects/$projectId/members/$memberId'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'actor_user_id': actorUserId}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Removes the calling user ([userId]) from [projectId]. Only valid
  /// when the caller is not the project owner — owners cannot leave
  /// their own project.
  static Future<void> leaveProject({
    required String projectId,
    required String userId,
  }) async {
    final response = await _send(
      () => http.delete(
        Uri.parse(
          '$baseUrl/projects/$projectId/members/by-user/$userId',
        ),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ------------------------------------------------------------------ //
  // Invitations (collaboration_requests)
  // ------------------------------------------------------------------ //

  /// Fetches invitations for [projectId]. Pass [status] (pending, accepted,
  /// declined, revoked) to narrow the result set.
  static Future<List<Map<String, dynamic>>> listProjectInvitations(
    String projectId, {
    String? status,
  }) async {
    final uri = Uri.parse('$baseUrl/projects/$projectId/invitations').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final response = await _send(() => http.get(uri));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final invitations = decoded is Map<String, dynamic>
        ? decoded['invitations']
        : null;
    if (invitations is List) {
      return invitations
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Creates a new invitation. Returns the full row including the `token`
  /// used by the invitee to accept / decline. [actorUserId] must be
  /// the project owner or the backend will respond with 403.
  static Future<Map<String, dynamic>> createProjectInvitation({
    required String projectId,
    required String email,
    required String role,
    String? invitedBy,
    String message = '',
    required String actorUserId,
  }) async {
    final normalized = role.trim().toLowerCase();
    if (!_validMemberRoles.contains(normalized)) {
      throw Exception(
        'Invalid role "$role". Expected one of $_validMemberRoles.',
      );
    }
    final payload = <String, dynamic>{
      'email': email.trim(),
      'role': normalized,
      'actor_user_id': actorUserId,
      if (message.trim().isNotEmpty) 'message': message.trim(),
      if (invitedBy != null && invitedBy.isNotEmpty) 'invited_by': invitedBy,
    };

    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/projects/$projectId/invitations'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final invitation = decoded['invitation'];
      if (invitation is Map) {
        return Map<String, dynamic>.from(invitation);
      }
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Revokes a pending invitation. [actorUserId] must be the project
  /// owner or the backend will respond with 403.
  static Future<void> revokeProjectInvitation({
    required String projectId,
    required String invitationId,
    required String actorUserId,
  }) async {
    final response = await _send(
      () => http.delete(
        Uri.parse(
          '$baseUrl/projects/$projectId/invitations/$invitationId',
        ),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'actor_user_id': actorUserId}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Lists pending invitations for the user identified by [email].
  static Future<List<Map<String, dynamic>>> listMyInvitations(
    String email,
  ) async {
    final uri = Uri.parse('$baseUrl/invitations').replace(
      queryParameters: {'email': email.trim()},
    );
    final response = await _send(() => http.get(uri));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final invitations = decoded is Map<String, dynamic>
        ? decoded['invitations']
        : null;
    if (invitations is List) {
      return invitations
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Accepts an invitation by its [token]. The server flips the row to
  /// "accepted" and inserts a matching `project_members` entry.
  static Future<Map<String, dynamic>> acceptProjectInvitation({
    required String token,
    required String acceptingUserId,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/invitations/$token/accept'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'accepting_user_id': acceptingUserId}),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final invitation = decoded['invitation'];
      if (invitation is Map) {
        return Map<String, dynamic>.from(invitation);
      }
    }
    throw Exception('Unexpected backend response shape.');
  }

  /// Declines an invitation by its [token]. The row is flipped to
  /// "declined"; no `project_members` row is created.
  static Future<Map<String, dynamic>> declineProjectInvitation(
    String token,
  ) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/invitations/$token/decline'),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final invitation = decoded['invitation'];
      if (invitation is Map) {
        return Map<String, dynamic>.from(invitation);
      }
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