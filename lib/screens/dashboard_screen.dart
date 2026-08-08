import 'package:flutter/material.dart';

import '../services/backend_api.dart';
import '../services/user_session.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Map<String, dynamic>>> _projectsFuture;
  Map<String, dynamic> _profile = const {};
  List<String> _missingFields = const [];
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _projectsFuture = BackendApi.listProjects(ownerId: UserSession.userId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profileLoaded) {
      return;
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final profile = args['profile'];
      if (profile is Map<String, dynamic>) {
        _profile = profile;
      }
      final missingFields = args['missingFields'];
      if (missingFields is List) {
        _missingFields = missingFields.map((value) => value.toString()).toList();
      }
    }
    _profileLoaded = true;
  }

  Future<void> _refreshProjects() async {
    setState(() {
      _projectsFuture = BackendApi.listProjects(ownerId: UserSession.userId);
    });
    await _projectsFuture;
  }

  void _openProject(Map<String, dynamic> project) {
    Navigator.of(context).pushNamed(
      '/project-details',
      arguments: {
        'projectId': project['id'],
        'projectTitle': project['title'] ?? 'Project',
      },
    ).then((_) => _refreshProjects());
  }

  bool get _needsProfileCompletion {
    if (_missingFields.isNotEmpty) {
      return true;
    }
    final profile = _profile;
    final requiredFields = ['full_name', 'university', 'role'];
    for (final field in requiredFields) {
      if ((profile[field]?.toString().trim() ?? '').isEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 28),
            const SizedBox(width: 8),
            Text(
              'ScholarFlow',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              if (_needsProfileCompletion)
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Complete your profile'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(
                      '/complete-profile',
                      arguments: {
                        'profile': _profile,
                      },
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await UserSession.clear();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed('/signin');
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProjects,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 32),
                    if (_needsProfileCompletion)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: const Text('Complete your profile'),
                          subtitle: const Text('Add the missing profile details to finish setup.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/complete-profile',
                            arguments: {
                              'profile': _profile,
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 80),
                    if (_needsProfileCompletion) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: const Text('Complete your profile'),
                          subtitle: const Text('Add the missing profile details to finish setup.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/complete-profile',
                            arguments: {
                              'profile': _profile,
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Running Projects',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text('Could not load projects: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refreshProjects,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/create-folder'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Project'),
                    ),
                  ],
                );
              }

              final projects = snapshot.data ?? const <Map<String, dynamic>>[];

              if (projects.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_needsProfileCompletion) ...[
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.edit_note),
                          title: const Text('Complete your profile'),
                          subtitle: const Text('Add the missing profile details to finish setup.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/complete-profile',
                            arguments: {
                              'profile': _profile,
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Running Projects',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('No running projects yet.'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/create-folder'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Project'),
                    ),
                  ],
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_needsProfileCompletion) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.edit_note),
                        title: const Text('Complete your profile'),
                        subtitle: const Text('Add the missing profile details to finish setup.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pushNamed(
                          '/complete-profile',
                          arguments: {
                            'profile': _profile,
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Running Projects',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/create-folder'),
                        icon: const Icon(Icons.add),
                        label: const Text('New Project'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...projects.map(
                    (project) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProjectCard(
                        project: project,
                        onTap: () => _openProject(project),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Map<String, dynamic> project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = project['title']?.toString() ?? 'Untitled Project';
    final description = project['description']?.toString() ?? '';
    final status = project['status']?.toString() ?? 'active';
    final paperCount = project['paper_count'] ?? 0;
    final versionCount = project['version_count'] ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, style: TextStyle(color: theme.colorScheme.outline.withValues(alpha: 0.9))),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(label: 'Papers', value: paperCount.toString()),
                const SizedBox(width: 8),
                _StatChip(label: 'Versions', value: versionCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
  }
}