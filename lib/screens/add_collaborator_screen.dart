import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend_api.dart';

class AddCollaboratorScreen extends StatefulWidget {
  const AddCollaboratorScreen({
    super.key,
    required this.projectId,
    required this.invitedBy,
  });

  /// UUID of the project the new invitation belongs to.
  final String projectId;

  /// UUID of the user sending the invitation (current session user).
  final String invitedBy;

  @override
  State<AddCollaboratorScreen> createState() => _AddCollaboratorScreenState();
}

class _AddCollaboratorScreenState extends State<AddCollaboratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _permissionLevel = 'editor';
  bool _isProcessing = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isProcessing = true;
    });

    try {
      final invitation = await BackendApi.createProjectInvitation(
        projectId: widget.projectId,
        email: _emailController.text.trim(),
        role: _permissionLevel,
        invitedBy: widget.invitedBy,
        actorUserId: widget.invitedBy,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isProcessing = false;
        _isSent = true;
      });
      await _showInviteLinkSheet(invitation);
      if (!mounted) {
        return;
      }
      // Return the row so callers can refresh their lists.
      Navigator.of(context).pop(invitation);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send invite: $error')),
      );
    }
  }

  /// Local-dev helper: shows the invite token + a copy button so the
  /// sender can hand the link to the invitee manually. Replace with
  /// transactional email when SMTP is wired up.
  Future<void> _showInviteLinkSheet(Map<String, dynamic> invitation) async {
    final theme = Theme.of(context);
    final token = invitation['token']?.toString() ?? '';
    final email = invitation['email']?.toString() ??
        _emailController.text.trim();
    final role = invitation['role']?.toString() ?? _permissionLevel;
    final link =
        'https://scholarflow.app/invitations/$token'; // placeholder URL
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Invitation ready',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Share this link with $email so they can accept the '
                  '$role invitation. (Email delivery is not configured yet.)',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    link,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: link),
                          );
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('Link copied')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy link'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Add Collaborator',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary),
            onPressed: () {
              // Search action
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Illustration / Header container
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DIGITAL SCHOLASTICISM',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Expand your research circle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Email input
                      Text(
                        'EMAIL ADDRESS',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'colleague@university.edu',
                          suffixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter colleague email address';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Permission Select
                      Text(
                        'PERMISSION LEVEL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _permissionLevel,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'viewer',
                            child: Text('Viewer (Read Only)'),
                          ),
                          DropdownMenuItem(
                            value: 'editor',
                            child: Text('Editor (Can edit papers)'),
                          ),
                          DropdownMenuItem(
                            value: 'lead',
                            child: Text('Lead (Admin Access)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _permissionLevel = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 28),

                      // AI Insight Card
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondaryContainer
                                .withOpacity(0.2),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: theme.colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI INSIGHT',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Collaborators with 'Editor' access can annotate papers and trigger shared citations in real-time.",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            // Invite Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing || _isSent ? null : _sendInvitation,
                  child: _isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing...'),
                          ],
                        )
                      : _isSent
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text('Invite Sent'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Send Invitation'),
                            SizedBox(width: 8),
                            Icon(Icons.send, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
