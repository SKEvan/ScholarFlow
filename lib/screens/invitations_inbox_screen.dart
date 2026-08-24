import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../services/user_session.dart';

/// Lists every pending invitation addressed to the signed-in user's
/// email. Accepting an invite creates the corresponding
/// `project_members` row server-side; declining marks the invitation
/// declined so it disappears from this list.
class InvitationsInboxScreen extends StatefulWidget {
  const InvitationsInboxScreen({super.key});

  @override
  State<InvitationsInboxScreen> createState() =>
      _InvitationsInboxScreenState();
}

class _InvitationsInboxScreenState extends State<InvitationsInboxScreen> {
  bool _isLoading = true;
  String? _busyToken; // token currently being responded to
  List<Map<String, dynamic>> _invitations = const [];
  String? _errorMessage;
  bool _anyAccepted = false;

  String? get _currentEmail {
    // Local session cache exposes the email in many places — we look
    // first at the dedicated field, then fall back to splitting
    // full_name, finally to nothing (the inbox API needs an email).
    final direct = UserSession.userEmail;
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final email = _currentEmail;
    if (email == null) {
      setState(() {
        _isLoading = false;
        _invitations = const [];
        _errorMessage =
            'No email on file for this account — invitations are sent by '
            'email, so add one to your profile first.';
      });
      return;
    }
    try {
      final invitations =
          await BackendApi.listMyInvitations(email);
      if (!mounted) return;
      setState(() {
        _invitations = invitations;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load invitations: $error';
      });
    }
  }

  String _projectTitle(Map<String, dynamic> invitation) {
    final project = invitation['projects'];
    if (project is Map) {
      final title = project['title']?.toString().trim();
      if (title != null && title.isNotEmpty) {
        return title;
      }
    }
    return 'Untitled project';
  }

  String _senderName(Map<String, dynamic> invitation) {
    final profile = invitation['profiles'];
    if (profile is Map) {
      final name = profile['full_name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    return 'A project lead';
  }

  String _role(Map<String, dynamic> invitation) {
    final raw = invitation['role']?.toString().toLowerCase() ?? '';
    if (raw.isEmpty) return 'editor';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String? _message(Map<String, dynamic> invitation) {
    final message = invitation['message']?.toString().trim();
    if (message == null || message.isEmpty) return null;
    return message;
  }

  Future<void> _accept(Map<String, dynamic> invitation) async {
    final token = invitation['token']?.toString();
    if (token == null || token.isEmpty) return;
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }
    setState(() {
      _busyToken = token;
    });
    try {
      await BackendApi.acceptProjectInvitation(
        token: token,
        acceptingUserId: userId,
      );
      if (!mounted) return;
      _anyAccepted = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Joined ${_projectTitle(invitation)} as ${_role(invitation)}.',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not accept invite: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyToken = null;
        });
      }
    }
  }

  Future<void> _decline(Map<String, dynamic> invitation) async {
    final token = invitation['token']?.toString();
    if (token == null || token.isEmpty) return;
    final projectTitle = _projectTitle(invitation);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline invitation'),
        content: Text(
          'Decline the invitation to join "$projectTitle"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busyToken = token;
    });
    try {
      await BackendApi.declineProjectInvitation(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation declined.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not decline invite: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyToken = null;
        });
      }
    }
  }

  Widget _buildInvitationCard(
    BuildContext context,
    Map<String, dynamic> invitation,
  ) {
    final theme = Theme.of(context);
    final token = invitation['token']?.toString() ?? '';
    final isBusy = token.isNotEmpty && token == _busyToken;
    final projectTitle = _projectTitle(invitation);
    final sender = _senderName(invitation);
    final role = _role(invitation);
    final message = _message(invitation);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                child: Icon(
                  Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Invited by $sender',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  role,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => _decline(invitation),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: isBusy ? null : () => _accept(invitation),
                  child: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Accept'),
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
              Icons.inbox_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'No invitations yet',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_anyAccepted ? true : false);
      },
      child: Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(_anyAccepted ? true : false);
          },
        ),
        title: Text(
          'Invitations',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: _invitations.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          _buildEmptyState(context),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ..._invitations.map(
                            (inv) => _buildInvitationCard(context, inv),
                          ),
                        ],
                      ),
              ),
      ),
      ),
    );
  }
}
