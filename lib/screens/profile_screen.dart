import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../services/user_session.dart';
import '../widgets/floating_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  Map<String, dynamic> _profile = const {};
  bool _isLoadingProfile = true;
  String? _profileError;

  int _pendingInviteCount = 0;
  bool _isLoadingInvites = true;

  Map<String, dynamic> _stats = const {};
  bool _isLoadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
    _loadPendingInviteCount();
    _loadStats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-fetch the badge whenever the app comes back to the foreground,
    // so a freshly-arrived invite shows up without a manual reload.
    if (state == AppLifecycleState.resumed) {
      _loadPendingInviteCount();
    }
  }

  Future<void> _loadProfile() async {
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profile = const {};
        _profileError = null;
      });
      return;
    }
    try {
      final response = await BackendApi.getProfile(userId);
      if (!mounted) return;
      final profile = response['profile'];
      setState(() {
        _profile =
            profile is Map<String, dynamic> ? profile : const <String, dynamic>{};
        _isLoadingProfile = false;
        _profileError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _profileError = error.toString();
      });
    }
  }

  Future<void> _loadPendingInviteCount() async {
    final email = UserSession.userEmail;
    if (email == null || email.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _pendingInviteCount = 0;
        _isLoadingInvites = false;
      });
      return;
    }
    try {
      final invites = await BackendApi.listMyInvitations(email.trim());
      if (!mounted) return;
      setState(() {
        _pendingInviteCount =
            invites.where((inv) => (inv['status']?.toString() ?? '') == 'pending')
                .length;
        _isLoadingInvites = false;
      });
    } catch (_) {
      // Silent: badge just hides if the inbox can't be reached.
      if (!mounted) return;
      setState(() {
        _pendingInviteCount = 0;
        _isLoadingInvites = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _isLoadingProfile = true;
      _isLoadingInvites = true;
      _isLoadingStats = true;
      _profileError = null;
      _statsError = null;
    });
    await Future.wait<void>([
      _loadProfile(),
      _loadPendingInviteCount(),
      _loadStats(),
    ]);
  }

  Future<void> _loadStats() async {
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
        _stats = const {};
        _statsError = null;
      });
      return;
    }
    try {
      final response = await BackendApi.getProfileStats(userId);
      if (!mounted) return;
      setState(() {
        _stats = response;
        _isLoadingStats = false;
        _statsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
        _statsError = error.toString();
      });
    }
  }

  String get _fullName {
    final name = _profile['full_name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Researcher';
  }

  String get _role {
    final role = _profile['role']?.toString().trim();
    if (role != null && role.isNotEmpty) return role;
    return '';
  }

  String get _university {
    final uni = _profile['university']?.toString().trim();
    if (uni != null && uni.isNotEmpty) return uni;
    return '';
  }

  String? get _avatarUrl {
    final raw = _profile['avatar_url']?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return null;
  }

  Widget _buildInviteIcon(BuildContext context) {
    final icon = const Icon(Icons.inbox_outlined, color: Colors.black);
    if (_pendingInviteCount <= 0) {
      return IconButton(
        tooltip: 'Invitations',
        icon: icon,
        onPressed: _isLoadingInvites
            ? null
            : () async {
                final accepted = await Navigator.of(context)
                    .pushNamed('/invitations-inbox');
                if (mounted && accepted == true) {
                  await _refreshAll();
                } else if (mounted) {
                  await _loadPendingInviteCount();
                }
              },
      );
    }
    return IconButton(
      tooltip: '$_pendingInviteCount pending invitation'
          '${_pendingInviteCount == 1 ? '' : 's'}',
      onPressed: () async {
        final accepted =
            await Navigator.of(context).pushNamed('/invitations-inbox');
        if (mounted && accepted == true) {
          await _refreshAll();
        } else if (mounted) {
          await _loadPendingInviteCount();
        }
      },
      icon: Badge.count(
        count: _pendingInviteCount,
        child: icon,
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final url = _avatarUrl;
    final theme = Theme.of(context);
    final placeholder = CircleAvatar(
      radius: 48,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      child: Text(
        _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return Container(
      width: 106,
      height: 106,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.3),
          width: 3.0,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: url != null
          ? ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder,
              ),
            )
          : placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          'Researcher Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          _buildInviteIcon(context),
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pushNamed('/add-collaborator');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile link copied to clipboard!'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshAll,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Profile Header Section
                  Center(
                    child: Column(
                      children: [
                        _buildAvatar(context),
                        const SizedBox(height: 16),
                        Text(
                          _isLoadingProfile && _profile.isEmpty
                              ? 'Loading…'
                              : _fullName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_role.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _role,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_university.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _university,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (_profileError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Could not load profile: $_profileError',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                // Stats Row
                Row(
                  children: [
                    _buildStatBox(
                      theme,
                      'PAPERS',
                      _isLoadingStats
                          ? '—'
                          : (_stats['papers_total']?.toString() ?? '0'),
                    ),
                    const SizedBox(width: 12),
                    _buildStatBox(
                      theme,
                      'CITATIONS',
                      _isLoadingStats
                          ? '—'
                          : (_stats['citations_total']?.toString() ?? '0'),
                    ),
                    const SizedBox(width: 12),
                    _buildStatBox(
                      theme,
                      'H-INDEX',
                      _isLoadingStats
                          ? '—'
                          : (_stats['h_index']?.toString() ?? '0'),
                    ),
                  ],
                ),
                if (_statsError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Could not load stats: $_statsError',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                // About Section
                _buildAboutSection(theme),
                const SizedBox(height: 28),
                // Active Projects
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(theme, 'ACTIVE PROJECTS'),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'VIEW ALL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentProjectsSection(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: FloatingNavBar(currentRoute: '/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(ThemeData theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.outline,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }

  /// About section: renders the persisted `about` text from
  /// `profiles.about` (or an empty-state placeholder), and offers an
  /// "Edit" button that opens a multi-line dialog. Saves go through
  /// `BackendApi.completeProfile`, which posts `about` to
  /// `POST /auth/complete-profile`.
  Widget _buildAboutSection(ThemeData theme) {
    final raw = _profile['about'];
    final about = raw == null ? '' : raw.toString().trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(theme, 'ABOUT'),
            TextButton.icon(
              onPressed: _isSavingAbout ? null : _editAboutDialog,
              icon: Icon(
                about.isEmpty ? Icons.add : Icons.edit_outlined,
                size: 14,
                color: theme.colorScheme.secondary,
              ),
              label: Text(
                about.isEmpty ? 'ADD' : 'EDIT',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: about.isEmpty
                ? Text(
                    'Tap "Add" to write a short bio so collaborators know what you work on.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(
                    about,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
          ),
        ),
      ],
    );
  }

  bool _isSavingAbout = false;

  Future<void> _editAboutDialog() async {
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) return;
    final current = (_profile['about'] ?? '').toString();
    final controller = TextEditingController(text: current);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit About'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              maxLines: 8,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'A short bio about you and your research...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (saved != true) return;
    final newAbout = controller.text.trim();
    if (newAbout == current.trim()) return;
    await _saveAbout(newAbout);
  }

  Future<void> _saveAbout(String about) async {
    final userId = UserSession.userId;
    if (userId == null || userId.isEmpty) return;
    setState(() => _isSavingAbout = true);
    try {
      final fullName = (_profile['full_name'] ?? '').toString();
      final avatarUrl = (_profile['avatar_url'] ?? '').toString();
      final university = (_profile['university'] ?? '').toString();
      final role = (_profile['role'] ?? '').toString();
      await BackendApi.completeProfile(
        userId: userId,
        fullName: fullName,
        avatarUrl: avatarUrl,
        university: university,
        role: role,
        about: about,
      );
      // Reload so the next About render pulls the persisted value
      // straight from the DB rather than from the local optimistic
      // value, and so any server-side normalization shows up.
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('About updated')),
      );
    } catch (error) {
      if (!mounted) return;
      // Most common cause pre-migration: the `about` column is absent
      // on `profiles`. The user must run migration 001 from the
      // Supabase SQL editor.
      final msg = error.toString().toLowerCase().contains('about') ||
              error.toString().toLowerCase().contains('column')
          ? 'Could not save About: the "about" column is missing on profiles. Run backend/migrations/001_add_profile_about.sql in Supabase SQL editor.'
          : 'Could not save About: $error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isSavingAbout = false);
    }
  }

  Widget _buildProjectCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required double progress,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: theme.colorScheme.outline,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.outlineVariant
                            .withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.secondary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the user's recent projects list backed by the
  /// `/profiles/{user_id}/stats` endpoint. Shows a friendly loading and
  /// empty state so the screen never displays hardcoded data.
  Widget _buildRecentProjectsSection(ThemeData theme) {
    final raw = _stats['recent_projects'];
    final projects = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const <Map<String, dynamic>>[];

    if (_isLoadingStats && projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Loading projects…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    if (projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No projects yet — create one to get started.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < projects.length; i++) ...[
          _buildRecentProjectTile(theme, projects[i]),
          if (i != projects.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRecentProjectTile(
    ThemeData theme,
    Map<String, dynamic> project,
  ) {
    final title = project['title']?.toString().trim() ?? 'Untitled project';
    final status = project['status']?.toString().toLowerCase() ?? '';
    final paperCount = (project['paper_count'] as num?)?.toInt() ?? 0;
    final versionCount = (project['version_count'] as num?)?.toInt() ?? 0;
    final subtitle =
        '$paperCount paper${paperCount == 1 ? '' : 's'} • $versionCount version${versionCount == 1 ? '' : 's'}'
            '${status.isNotEmpty ? ' • ${_titleCase(status)}' : ''}';
    // Estimate progress from status (rough heuristic for the bar).
    double progress;
    switch (status) {
      case 'completed':
      case 'finished':
        progress = 1.0;
        break;
      case 'in_progress':
      case 'active':
        progress = 0.5;
        break;
      default:
        progress = 0.25;
    }

    return _buildProjectCard(
      theme: theme,
      icon: Icons.science_outlined,
      title: title,
      description: subtitle,
      progress: progress,
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
