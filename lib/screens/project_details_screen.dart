import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/backend_api.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final TextEditingController _versionNameController = TextEditingController();
  final TextEditingController _versionNoteController = TextEditingController();

  final List<Map<String, dynamic>> _aiTools = [
    {
      'icon': Icons.summarize,
      'title': 'Generate Summary',
      'endpoint': '/agents/summary',
      'choices': ['General Summary', 'Key insights', 'Critical Analysis'],
    },
    {
      'icon': Icons.compare_arrows,
      'title': 'Comparison Gap',
      'endpoint': '/agents/comparison',
      'choices': ['Overall Comparison', 'Similarity and Difference', 'Strength and Limitation'],
    },
    {
      'icon': Icons.search,
      'title': 'Research Gap',
      'endpoint': '/agents/research-gap',
      'choices': ['Research Gaps', 'Future Research Opportunities', 'Strengths and Limitations'],
    },
    {
      'icon': Icons.menu_book,
      'title': 'Literature Review',
      'endpoint': '/agents/literature-review',
      'choices': ['Narrative Review', 'Theme based Review', 'Critical Review'],
    },
  ];

  String? _projectId;                              // UUID → String? (was int?)
  String _projectTitle = 'Project';
  bool _isLoading = false;
  bool _isSavingVersion = false;

  List<Map<String, dynamic>> _projectPapers = [];
  List<Map<String, dynamic>> _versions = [];
  Set<String> _selectedPaperIds = <String>{};
  final Set<String> _expandedPaperIds = <String>{};

  @override
  void dispose() {
    _versionNameController.dispose();
    _versionNoteController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final rawProjectId = args['projectId'];
      // UUID is already a String — just convert to string, no int parsing
      _projectId = rawProjectId?.toString();
      final title = args['projectTitle']?.toString();
      if (title != null && title.isNotEmpty) {
        _projectTitle = title;
      }
    } else if (args is String && args.isNotEmpty) {
      _projectTitle = args;
    }

    if (_projectId != null && _projectPapers.isEmpty && !_isLoading) {
      _loadRepository();
    }
  }

  Future<void> _loadRepository() async {
    if (_projectId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = await BackendApi.getProjectRepository(_projectId!);
      final project = repository['project'] as Map<String, dynamic>?;
      final papers = (repository['papers'] as List? ?? const [])
          .whereType<Map>()
          .map((paper) => Map<String, dynamic>.from(paper))
          .toList();
      final versions = (repository['versions'] as List? ?? const [])
          .whereType<Map>()
          .map((version) => Map<String, dynamic>.from(version))
          .toList();

      setState(() {
        if (project != null && project['title'] != null) {
          _projectTitle = project['title'].toString();
        }
        _projectPapers = papers;
        _versions = versions;
        // UUID strings — no int.parse needed
        _selectedPaperIds = papers
            .where((paper) => paper['id'] != null)
            .map<String>((paper) => paper['id'].toString())
            .toSet();
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
        SnackBar(content: Text('Could not load repository: $error')),
      );
    }
  }

  // Map from tool title → dedicated route
  static const _toolRoutes = {
    'Generate Summary'  : '/agent/summary',
    'Comparison Gap'    : '/agent/comparison',
    'Research Gap'      : '/agent/research-gap',
    'Literature Review' : '/agent/literature-review',
  };

  void _openAgentScreen(Map<String, dynamic> tool) {
    final route = _toolRoutes[tool['title'] as String];
    if (route == null) return;
    Navigator.of(context).pushNamed(
      route,
      arguments: {
        'projectId'   : _projectId,
        'projectTitle': _projectTitle,
        'papers'      : _projectPapers,
      },
    );
  }

  Future<void> _showSaveVersionDialog() async {
    if (_projectId == null) {
      return;
    }

    _versionNameController.clear();
    _versionNoteController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save Version'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _versionNameController,
                decoration: const InputDecoration(labelText: 'Version name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _versionNoteController,
                decoration: const InputDecoration(labelText: 'Version note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSavingVersion
                  ? null
                  : () async {
                      final snapshotName = _versionNameController.text.trim();
                      if (snapshotName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Version name is required.')),
                        );
                        return;
                      }

                      setState(() {
                        _isSavingVersion = true;
                      });

                      try {
                        final version = await BackendApi.saveVersion(
                          projectId: _projectId!,  // String UUID
                          snapshotName: snapshotName,
                          versionMessage: _versionNoteController.text.trim(),
                        );
                        if (!mounted) {
                          return;
                        }

                        setState(() {
                          _isSavingVersion = false;
                          _versions = [Map<String, dynamic>.from(version), ..._versions];
                        });
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Version saved.')),
                        );
                      } catch (error) {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _isSavingVersion = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Version save failed: $error')),
                        );
                      }
                    },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showVersionHistory() async {
    if (_projectId == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...(_versions.isEmpty
                    ? <Widget>[const Text('No saved versions yet.')]
                    : _versions.map((version) {
                        return Card(
                          child: ListTile(
                            title: Text(version['snapshot_name']?.toString() ?? 'Unnamed version'),
                            subtitle: Text(version['version_message']?.toString() ?? ''),
                            trailing: const Icon(Icons.restore),
                            onTap: () async {
                              try {
                                await BackendApi.restoreVersion(
                                  projectId: _projectId!,
                                  versionId: version['id'].toString(), // UUID → String, no int.parse
                                );
                                if (!mounted) {
                                  return;
                                }
                                Navigator.of(sheetContext).pop();
                                await _loadRepository();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Version restored.')),
                                );
                              } catch (error) {
                                if (!mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Version restore failed: $error')),
                                );
                              }
                            },
                          ),
                        );
                      }).toList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaperCard(ThemeData theme, Map<String, dynamic> paper) {
    final paperId = paper['id'].toString(); // UUID → String, no int.parse
    final isExpanded = _expandedPaperIds.contains(paperId);
    final abstractText = (paper['abstract'] ?? '').toString().trim();
    final paperUrl = (paper['paper_url'] ?? '').toString().trim();
    final doi = (paper['doi'] ?? '').toString().trim();
    final doiUrl = (paper['doi_url'] ?? '').toString().trim();
    final pdfUrl = (paper['pdf_url'] ?? '').toString().trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: _selectedPaperIds.contains(paperId),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedPaperIds.add(paperId);
                } else {
                  _selectedPaperIds.remove(paperId);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              paper['title']?.toString() ?? 'Untitled paper',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${paper['authors'] ?? 'Unknown authors'} • ${paper['year'] ?? ''} • ${paper['citations'] ?? 0} citations',
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPaperIds.remove(paperId);
                } else {
                  _expandedPaperIds.add(paperId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Text(
                    isExpanded ? 'Hide details' : 'View details',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text('Abstract', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    abstractText.isEmpty ? 'No abstract stored.' : abstractText,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text('Publication Info', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('DOI: ${doi.isEmpty ? 'N/A' : doi}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  _buildLinkRow(theme, label: 'Paper URL', url: paperUrl),
                  _buildLinkRow(theme, label: 'DOI Link', url: doiUrl),
                  _buildLinkRow(theme, label: 'PDF', url: pdfUrl),
                  const SizedBox(height: 2),
                  Text('Fetched at: ${paper['fetched_at'] ?? 'N/A'}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIToolTile(ThemeData theme, Map<String, dynamic> tool) {
    return InkWell(
      onTap: () => _openAgentScreen(tool),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tool['icon'] as IconData, color: theme.colorScheme.secondary, size: 22),
            ),
            const Spacer(),
            Text(
              tool['title'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Open',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward, size: 12, color: theme.colorScheme.secondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a labelled clickable link row. Shows "N/A" text if url is empty.
  Widget _buildLinkRow(ThemeData theme, {required String label, required String url}) {
    final isEmpty = url.isEmpty || url == 'null';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ', style: theme.textTheme.bodySmall),
          if (isEmpty)
            Text('N/A', style: theme.textTheme.bodySmall)
          else
            GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open link.')),
                      );
                    }
                  }
                }
              },
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildJsonSections(ThemeData theme, Map<String, dynamic> data) {
    final widgets = <Widget>[];
    data.forEach((key, value) {
      if (value == null) return;
      final label = key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' ');
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            _buildJsonValue(theme, value),
          ],
        ),
      ));
    });
    return widgets;
  }

  Widget _buildJsonValue(ThemeData theme, dynamic value) {
    if (value is String) {
      return Text(value, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5));
    }
    if (value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.map<Widget>((item) {
          if (item is Map<String, dynamic>) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildJsonSections(theme, item),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 8),
                  width: 5, height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary),
                ),
                Expanded(child: Text(item.toString(), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5))),
              ],
            ),
          );
        }).toList(),
      );
    }
    if (value is Map<String, dynamic>) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildJsonSections(theme, value));
    }
    return Text(value.toString(), style: theme.textTheme.bodyMedium);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _projectTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadRepository,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSaveVersionDialog,
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.save),
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRepository,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PROJECT REPOSITORY', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                                  const SizedBox(height: 6),
                                  Text(_projectTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${_projectPapers.length} papers • ${_versions.length} saved versions'),
                                ],
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: CircularProgressIndicator(
                                      value: _projectPapers.isEmpty ? 0.0 : 0.6,
                                      strokeWidth: 5,
                                      backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                    ),
                                  ),
                                  Text('${(_projectPapers.isEmpty ? 0 : 60)}%'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showSaveVersionDialog,
                                icon: const Icon(Icons.save),
                                label: const Text('Save Version'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showVersionHistory,
                                icon: const Icon(Icons.history),
                                label: const Text('Versions'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Research Papers (scrollable fixed-height box) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text('Research Papers', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(
                              '(${_projectPapers.where((p) => (p['citations'] as num? ?? 0) > 0).length} with citations)',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _projectPapers.isEmpty
                            ? const Text('No papers were fetched yet.')
                            : ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 380),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: _projectPapers
                                        .where((p) => (p['citations'] as num? ?? 0) > 0)
                                        .map((paper) => _buildPaperCard(theme, paper))
                                        .toList(),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      // ── AI Collaboration Tools (always visible) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('AI Collaboration Tools', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.9,
                          children: _aiTools.map((tool) => _buildAIToolTile(theme, tool)).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}