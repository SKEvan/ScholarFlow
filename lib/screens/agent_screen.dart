import 'package:flutter/material.dart';

import '../services/backend_api.dart';

/// Reusable full-page AI agent screen.
///
/// Each named agent screen (SummaryScreen, ComparisonScreen, etc.) passes its
/// own [toolConfig] and reads [projectId], [projectTitle], and [papers] from
/// the route arguments map:
///
///   Navigator.of(context).pushNamed(
///     '/agent/summary',
///     arguments: {
///       'projectId'   : String,
///       'projectTitle': String,
///       'papers'      : List<Map<String, dynamic>>,
///     },
///   );
class AgentScreen extends StatefulWidget {
  const AgentScreen({
    super.key,
    required this.toolConfig,
  });

  /// Tool definition: title, icon, endpoint, choices.
  final Map<String, dynamic> toolConfig;

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  // ── from route args ────────────────────────────────────────────────────────
  String? _projectId;
  String _projectTitle = '';
  List<Map<String, dynamic>> _papers = [];

  // ── local state ────────────────────────────────────────────────────────────
  late String _selectedChoice;
  Set<String> _selectedPaperIds = {};
  final TextEditingController _promptCtrl = TextEditingController();

  bool _isRunning = false;
  bool _isLoadingLatest = false;
  bool _isStreaming = false;
  Map<String, dynamic>? _result;
  String _resultChoice = '';
  String _resultPrompt = '';

  // ── streaming state ────────────────────────────────────────────────────────
  String _streamDelta = '';
  AgentStreamHandle? _streamHandle;

  // Maps agent endpoint to the project column that stores the latest output.
  static const _endpointToOutputKey = {
    '/agents/summary'           : 'summary',
    '/agents/comparison'        : 'comparison',
    '/agents/research-gap'      : 'research_gap',
    '/agents/literature-review' : 'literature_review',
  };

  bool _argsParsed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsParsed) return;
    _argsParsed = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _projectId = args?['projectId']?.toString();
    _projectTitle = args?['projectTitle']?.toString() ?? '';
    _papers = (args?['papers'] as List? ?? [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    final choices = widget.toolConfig['choices'] as List? ?? [];
    _selectedChoice = choices.isNotEmpty ? choices.first.toString() : '';

    // pre-select papers that have citations
    _selectedPaperIds = _papers
        .where((p) => (p['citations'] as num? ?? 0) > 0)
        .map((p) => p['id'].toString())
        .toSet();

    // Load the latest saved output for this tool from the project row.
    _loadLatestOutput();
  }

  Future<void> _loadLatestOutput() async {
    if (_projectId == null) return;
    final endpoint = widget.toolConfig['endpoint'] as String? ?? '';
    final outputKey = _endpointToOutputKey[endpoint];
    if (outputKey == null) return;

    setState(() => _isLoadingLatest = true);
    try {
      final repo = await BackendApi.getProjectRepository(_projectId!);
      // The repository endpoint returns summary/comparison/research_gap/
      // literature_review at the top level (mirrored from project.latest_*).
      final raw = repo[outputKey] ?? (repo['project'] as Map?)?['latest_$outputKey'];
      if (!mounted) return;
      if (raw is Map<String, dynamic> && raw.isNotEmpty) {
        setState(() {
          _result = raw;
          _resultChoice = 'Saved output';
          _isLoadingLatest = false;
        });
      } else {
        setState(() => _isLoadingLatest = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLatest = false);
    }
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  // ── run agent (token-by-token streaming) ───────────────────────────────────
  Future<void> _run() async {
    if (_projectId == null) return;
    if (_selectedPaperIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one paper first.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isRunning = true;
      _isStreaming = true;
      _streamDelta = '';
      _result = null;
    });

    final handle = BackendApi.runProjectAgentStream(
      projectId: _projectId!,
      endpoint: widget.toolConfig['endpoint'] as String,
      desiredOutputType: _selectedChoice,
      userPrompt: _promptCtrl.text.trim(),
      selectedPaperIds: _selectedPaperIds.toList(),
    );
    _streamHandle = handle;

    handle.events.listen(
      (event) {
        if (!mounted) return;
        switch (event) {
          case AgentStreamMeta():
            // Reserved for future metadata (e.g. model id). No-op for now.
            break;
          case AgentStreamToken(:final delta):
            setState(() {
              _streamDelta = (_streamDelta + delta).replaceAll('\r\n', '\n');
            });
          case AgentStreamDone(:final result):
            setState(() {
              _isRunning = false;
              _isStreaming = false;
              _streamDelta = '';
              _result = result;
              _resultChoice = _selectedChoice;
              _resultPrompt = _promptCtrl.text.trim();
            });
            // Silently refresh so the stored output is in sync if user leaves & returns.
            _loadLatestOutput();
          case AgentStreamError(:final message):
            setState(() {
              _isRunning = false;
              _isStreaming = false;
              _streamDelta = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Agent failed: $message')),
            );
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isRunning = false;
          _isStreaming = false;
          _streamDelta = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agent failed: $error')),
        );
      },
      onDone: () {
        if (!mounted) return;
        // If the stream ended without an explicit "done" event, reset state.
        if (_isRunning || _isStreaming) {
          setState(() {
            _isRunning = false;
            _isStreaming = false;
            _streamDelta = '';
          });
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _stop() async {
    final handle = _streamHandle;
    if (handle == null) return;
    setState(() {
      _isRunning = false;
      _isStreaming = false;
      _streamDelta = '';
    });
    await handle.cancel();
    _streamHandle = null;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolTitle = widget.toolConfig['title']?.toString() ?? 'AI Tool';
    final toolIcon = widget.toolConfig['icon'] as IconData? ?? Icons.auto_awesome;
    final choices = (widget.toolConfig['choices'] as List? ?? []).map((e) => e.toString()).toList();
    final eligiblePapers = _papers.where((p) => (p['citations'] as num? ?? 0) > 0).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              toolTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (_projectTitle.isNotEmpty)
              Text(
                _projectTitle,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(toolIcon, color: theme.colorScheme.secondary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toolTitle,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select papers, choose an output type, and run.',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── output type ──────────────────────────────────────────────
                _Label(text: 'Output Type'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: choices.map((c) {
                    return ChoiceChip(
                      label: Text(c),
                      selected: _selectedChoice == c,
                      onSelected: (_) => setState(() => _selectedChoice = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── paper selector ───────────────────────────────────────────
                Row(
                  children: [
                    _Label(text: 'Papers'),
                    const SizedBox(width: 6),
                    Text(
                      '(${_selectedPaperIds.length} of ${eligiblePapers.length} selected)',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: eligiblePapers.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No papers with citations in this project.'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: eligiblePapers.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final paper = eligiblePapers[i];
                            final id = paper['id'].toString();
                            return CheckboxListTile(
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _selectedPaperIds.contains(id),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedPaperIds.add(id);
                                } else {
                                  _selectedPaperIds.remove(id);
                                }
                              }),
                              title: Text(
                                paper['title']?.toString() ?? 'Untitled',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('${paper['citations'] ?? 0} citations'),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),

                // ── focus prompt ─────────────────────────────────────────────
                _Label(text: 'Focus (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptCtrl,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe what you want the AI to focus on…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // ── run / stop button ─────────────────────────────────────────
                if (_isStreaming && _isRunning)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stop,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: Text('Stop $toolTitle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isRunning ? null : _run,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text('Run $toolTitle'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── live streaming bubble ────────────────────────────────────
                if (_isStreaming) _buildStreamingBubble(theme, toolTitle),
                if (_isStreaming) const SizedBox(height: 28),

                // ── latest output ────────────────────────────────────────────
                _buildOutputCard(theme, toolTitle),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── streaming bubble ────────────────────────────────────────────────────────
  Widget _buildStreamingBubble(ThemeData theme, String toolTitle) {
    final delta = _streamDelta;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$toolTitle · streaming…',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            delta.isEmpty ? 'Thinking…' : delta,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── output card ────────────────────────────────────────────────────────────
  Widget _buildOutputCard(ThemeData theme, String toolTitle) {
    final result = _result;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: result != null
              ? theme.colorScheme.secondary.withOpacity(0.4)
              : theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.18),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result != null ? 'Latest Output · $_resultChoice' : 'Latest Output',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                if (_isLoadingLatest)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                    ),
                  ),
              ],
            ),
          ),

          if (result == null || result.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isLoadingLatest
                    ? 'Loading latest output…'
                    : 'No output yet — run the agent above to generate.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_resultPrompt.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.person_outline, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _resultPrompt,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ..._buildJsonSections(theme, result),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── JSON rendering (same as project_details_screen) ────────────────────────
  List<Widget> _buildJsonSections(ThemeData theme, Map<String, dynamic> data) {
    final widgets = <Widget>[];
    data.forEach((key, value) {
      if (value == null) return;
      final label = key
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
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
              child: Text(
                label,
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
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary),
                ),
                Expanded(
                  child: Text(item.toString(), style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
    if (value is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildJsonSections(theme, value),
      );
    }
    return Text(value.toString(), style: theme.textTheme.bodyMedium);
  }
}

// ── tiny helper ────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}