import 'package:flutter/material.dart';

import '../services/backend_api.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  late Future<List<dynamic>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = BackendApi.listProjects();
  }

  Future<void> _refreshProjects() async {
    setState(() {
      _projectsFuture = BackendApi.listProjects();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Projects',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshProjects,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProjects,
        child: FutureBuilder<List<dynamic>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final errorText = snapshot.error.toString();
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Could not load projects',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          errorText,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final projects = snapshot.data ?? const <dynamic>[];

            if (projects.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.folder_open_outlined, size: 72, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No projects yet',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a project to see it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.outline.withValues(alpha: 0.8)),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final project = projects[index] as Map<String, dynamic>;
                final title = project['title']?.toString() ?? 'Untitled Project';
                final description = project['description']?.toString() ?? '';
                final status = project['status']?.toString() ?? 'active';
                final paperCount = project['paper_count'] ?? 0;
                final versionCount = project['version_count'] ?? 0;

                return InkWell(
                  onTap: () => _openProject(project),
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
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: projects.length,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/create-folder'),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
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
