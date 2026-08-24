import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend_api.dart';
import '../services/user_session.dart';
import 'add_collaborator_screen.dart';

/// Lists every collaborator on a single project. Each row exposes a
/// three-dot menu with the operations defined in the product spec:
///
/// * **Make Viewer**     — sets `member_role` to `viewer`
/// * **Make Editor**     — sets `member_role` to `editor`
/// * **Remove from project** — deletes the `project_members` row
///
/// The screen reuses the existing [AddCollaboratorScreen] for the
/// "+" action so the invite form is consistent across the app.
class ProjectMembersScreen extends StatefulWidget {
  const ProjectMembersScreen({
    super.key,
    required this.projectId,
    required this.currentUserId,
    required this.ownerId,
  });

  final String projectId;
  final String currentUserId;
  final String ownerId;

  bool get _isOwner => ownerId == currentUserId;

  @override
  State<ProjectMembersScreen> createState() => _ProjectMembersScreenState();
}

class _ProjectMembersScreenState extends State<ProjectMembersScreen> {
  bool _isLoading = true;
  String? _busyMemberId; // member-id currently being mutated (for spinner)
  String? _busyInvitationId; // invitation-id currently being mutated
  List<Map<String, dynamic>> _members = const [];
  List<Map<String, dynamic>> _invitations = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await Future.wait([
        BackendApi.listProjectMembers(widget.projectId),
        BackendApi.listProjectInvitations(
          widget.projectId,
          status: 'pending',
        ),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _members = results[0];
        _invitations = results[1];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load members: $error')),
      );
    }
  }

  Future<void> _changeRole({
    required Map<String, dynamic> member,
    required String role,
  }) async {
    final memberId = member['id']?.toString();
    if (memberId == null) {
      return;
    }
    setState(() {
      _busyMemberId = memberId;
    });
    try {
      await BackendApi.updateProjectMemberRole(
        projectId: widget.projectId,
        memberId: memberId,
        role: role,
        actorUserId: widget.currentUserId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated to ${_titleCase(role)}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update role: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyMemberId = null;
        });
      }
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final memberId = member['id']?.toString();
    if (memberId == null) {
      return;
    }
    final profile = member['profiles'];
    final name = (profile is Map ? profile['full_name'] : null)
            ?.toString()
            .trim() ??
        'this member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Remove $name from this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busyMemberId = memberId;
    });
    try {
      await BackendApi.removeProjectMember(
        projectId: widget.projectId,
        memberId: memberId,
        actorUserId: widget.currentUserId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name was removed.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyMemberId = null;
        });
      }
    }
  }

  Future<void> _openAddCollaborator() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddCollaboratorScreen(
          projectId: widget.projectId,
          invitedBy: UserSession.userId ?? '',
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (result is Map<String, dynamic>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent.')),
      );
    }
    await _refresh();
  }

  Future<void> _copyInviteLink(Map<String, dynamic> invitation) async {
    final token = invitation['token']?.toString() ?? '';
    if (token.isEmpty) {
      return;
    }
    final link =
        'https://scholarflow.app/invitations/$token'; // placeholder URL
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite link copied to clipboard.')),
    );
  }

  Future<void> _revokeInvitation(Map<String, dynamic> invitation) async {
    final invitationId = invitation['id']?.toString();
    final email = invitation['email']?.toString() ?? 'this invite';
    if (invitationId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke invitation'),
        content: Text('Revoke the pending invitation for $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _busyInvitationId = invitationId;
    });
    try {
      await BackendApi.revokeProjectInvitation(
        projectId: widget.projectId,
        invitationId: invitationId,
        actorUserId: widget.currentUserId,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation to $email was revoked.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not revoke invitation: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyInvitationId = null;
        });
      }
    }
  }

  String _invitationDisplayEmail(Map<String, dynamic> invitation) {
    final explicit = invitation['email']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    final profile = invitation['invited_user'];
    if (profile is Map) {
      final email = profile['email']?.toString().trim();
      if (email != null && email.isNotEmpty) {
        return email;
      }
    }
    return 'pending invite';
  }

  String _invitationDisplayRole(Map<String, dynamic> invitation) {
    final role = invitation['role']?.toString().toLowerCase() ?? '';
    if (role.isEmpty) {
      return 'Editor';
    }
    return _titleCase(role);
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  String _displayName(Map<String, dynamic> member) {
    final profile = member['profiles'];
    if (profile is Map) {
      final name = profile['full_name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    final userId = member['user_id']?.toString();
    return (userId != null && userId.isNotEmpty)
        ? 'User ${userId.substring(0, 8)}'
        : 'Unknown user';
  }

  String _displaySubtitle(Map<String, dynamic> member) {
    final profile = member['profiles'];
    if (profile is Map) {
      final uni = profile['university']?.toString().trim();
      if (uni != null && uni.isNotEmpty) {
        return uni;
      }
    }
    final role = member['member_role']?.toString() ?? '';
    return _titleCase(role);
  }

  String _displayRole(Map<String, dynamic> member) {
    final role = member['member_role']?.toString().toLowerCase() ?? '';
    return _titleCase(role);
  }

  String? _avatarUrl(Map<String, dynamic> member) {
    final profile = member['profiles'];
    if (profile is Map) {
      final url = profile['avatar_url']?.toString().trim();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _buildAvatar(BuildContext context, Map<String, dynamic> member) {
    final theme = Theme.of(context);
    final url = _avatarUrl(member);
    final name = _displayName(member);
    if (url != null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: Text(
          _initials(name),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: theme.colorScheme.secondary.withOpacity(0.15),
      child: Text(
        _initials(name),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    final theme = Theme.of(context);
    final normalized = role.toLowerCase();
    Color tint;
    switch (normalized) {
      case 'lead':
        tint = theme.colorScheme.primary;
        break;
      case 'editor':
        tint = theme.colorScheme.secondary;
        break;
      default:
        tint = theme.colorScheme.outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withOpacity(0.4)),
      ),
      child: Text(
        normalized.isEmpty ? '—' : _titleCase(normalized),
        style: theme.textTheme.labelSmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, Map<String, dynamic> member) {
    final theme = Theme.of(context);
    final memberId = member['id']?.toString();
    final isBusy = memberId != null && memberId == _busyMemberId;
    final name = _displayName(member);
    final subtitle = _displaySubtitle(member);
    final role = _displayRole(member);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildAvatar(context, member),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip(context, role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (widget._isOwner)
            PopupMenuButton<_MemberAction>(
              tooltip: 'Member options',
              icon: Icon(Icons.more_vert, color: theme.colorScheme.outline),
              onSelected: (action) {
                switch (action) {
                  case _MemberAction.makeViewer:
                    _changeRole(member: member, role: 'viewer');
                    break;
                  case _MemberAction.makeEditor:
                    _changeRole(member: member, role: 'editor');
                    break;
                  case _MemberAction.remove:
                    _removeMember(member);
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _MemberAction.makeViewer,
                  child: ListTile(
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('Make Viewer'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MemberAction.makeEditor,
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Make Editor'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _MemberAction.remove,
                  child: ListTile(
                    leading: Icon(Icons.person_remove_outlined, color: Colors.red),
                    title: Text(
                      'Remove from project',
                      style: TextStyle(color: Colors.red),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'No members yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the + button to invite the first collaborator.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTile(
    BuildContext context,
    Map<String, dynamic> invitation,
  ) {
    final theme = Theme.of(context);
    final id = invitation['id']?.toString();
    final isBusy = id != null && id == _busyInvitationId;
    final email = _invitationDisplayEmail(invitation);
    final role = _invitationDisplayRole(invitation);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Icon(
              Icons.mark_email_unread_outlined,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        email,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRoleChip(context, role.toLowerCase()),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Invitation pending',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (widget._isOwner) ...[
            IconButton(
              tooltip: 'Copy invite link',
              icon: const Icon(Icons.link),
              onPressed: () => _copyInviteLink(invitation),
            ),
            IconButton(
              tooltip: 'Revoke invitation',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () => _revokeInvitation(invitation),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingInvitesSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.outgoing_mail,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'PENDING INVITES',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                '${_invitations.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._invitations.map(
            (inv) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildInvitationTile(context, inv),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Project Members'),
        actions: [
          if (widget._isOwner)
            IconButton(
              tooltip: 'Add member',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: _openAddCollaborator,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: _members.isEmpty && _invitations.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          _buildEmptyState(context),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_invitations.isNotEmpty)
                            _buildPendingInvitesSection(context),
                          ..._members.expand(
                            (member) => [
                              _buildMemberTile(context, member),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}

enum _MemberAction { makeViewer, makeEditor, remove }
