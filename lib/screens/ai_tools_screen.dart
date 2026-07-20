import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class AIToolsScreen extends StatefulWidget {
  const AIToolsScreen({super.key});

  @override
  State<AIToolsScreen> createState() => _AIToolsScreenState();
}

class _AIToolsScreenState extends State<AIToolsScreen> {
  final int _activeTab = 3; // Tools active
  final _abstractController = TextEditingController();
  final _citationController = TextEditingController();

  String _selectedSummaryType = 'Standard Abstract';
  String _selectedCitationStyle = 'APA 7th Edition';

  bool _isSummarizing = false;
  String? _summaryResult;

  String? _citationResult;

  @override
  void dispose() {
    _abstractController.dispose();
    _citationController.dispose();
    super.dispose();
  }

  void _generateSummary() {
    if (_abstractController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to summarize.')),
      );
      return;
    }

    setState(() {
      _isSummarizing = true;
      _summaryResult = null;
    });

    // Simulate AI generation
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isSummarizing = false;
        _summaryResult = "AI Summary [$_selectedSummaryType]: The manuscript presents a comprehensive framework addressing computational optimization and distributed training strategies. By deploying a hybrid gradient tree-routing mechanism, the system achieves a 15% reduction in node latency and ensures complete consistency across multi-threaded operations.";
      });
    });
  }

  void _generateCitation() {
    if (_citationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL or DOI.')),
      );
      return;
    }

    setState(() {
      final input = _citationController.text;
      if (_selectedCitationStyle == 'APA 7th Edition') {
        _citationResult = "Vance, J., & Thorne, M. (2026). Optimization in Hybrid Topologies. Journal of ScholarFlow, 14(2), 112-125. DOI: $input";
      } else if (_selectedCitationStyle == 'MLA 9th Edition') {
        _citationResult = "Vance, Julian, and Marcus Thorne. \"Optimization in Hybrid Topologies.\" Journal of ScholarFlow, vol. 14, no. 2, 2026, pp. 112-125. DOI: $input.";
      } else {
        _citationResult = "Vance, Julian, and Marcus Thorne. 2026. \"Optimization in Hybrid Topologies.\" Journal of ScholarFlow 14 (2): 112-125. doi:$input.";
      }
    });

    Clipboard.setData(ClipboardData(text: _citationResult ?? ''));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Citation copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'ScholarFlow',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drawer menu requested.')),
                );
              },
            );
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCDjXO6XdfVP3zb59HMwG0pquQ-J-rFjlEydjXls8se839eUpxOxo3bL0RJr9L4LQZzo8IAc7DYmcKWmLraT6Kzmdl6Tnxl0q3tYfF6mkOd4g5ybsZpDEqY6jg2IfzXU6-Uw4NHqO5pRCgmLdcdyPGF609Un814FBXuLAZZ1nsXUGHNfK33eUMUBHI8dWJbXkhA36U0-HypTZjjlzHt69Df6Z7CbxMx1nMdnciVKL3UpcpKGzYxBxWDEDGhhAHE2Iyz8FJW5u77tWE',
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Text
              Text(
                'Academic Toolkit',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Intelligent utilities for rigorous research.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),

              // AI Summarizer Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI SUMMARIZER',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Icon(Icons.auto_awesome, color: theme.colorScheme.secondary, size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _abstractController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Paste paper abstract or raw text here...',
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSummaryType,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Standard Abstract', child: Text('Standard Abstract')),
                              DropdownMenuItem(value: 'Executive Summary', child: Text('Executive Summary')),
                              DropdownMenuItem(value: 'Bullet Points', child: Text('Bullet Points')),
                              DropdownMenuItem(value: 'Layman Terms', child: Text('Layman Terms')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSummaryType = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSummarizing ? null : _generateSummary,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: _isSummarizing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                )
                              : const Icon(Icons.bolt, size: 16),
                          label: const Text('GENERATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    if (_summaryResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
                        ),
                        child: Text(
                          _summaryResult!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Citation Generator Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CITATION GENERATOR',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Icon(Icons.format_quote, color: theme.colorScheme.outline, size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _citationController,
                      decoration: InputDecoration(
                        hintText: 'URL or DOI',
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCitationStyle,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'APA 7th Edition', child: Text('APA 7th Edition')),
                              DropdownMenuItem(value: 'MLA 9th Edition', child: Text('MLA 9th Edition')),
                              DropdownMenuItem(value: 'Chicago Style', child: Text('Chicago Style')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCitationStyle = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: _generateCitation,
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    if (_citationResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _citationResult!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Copied to clipboard',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Literature Review Assistant & Journal Finder Grid
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard(
                      theme,
                      Icons.library_books,
                      'LIT REVIEW\nASSISTANT',
                      'Automated synthesis of 20+ sources.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoCard(
                      theme,
                      Icons.find_in_page_outlined,
                      'JOURNAL\nFINDER',
                      'Match manuscript with journals.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Suggested For You
              Text(
                'SUGGESTED FOR YOU',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSuggestedChip(theme, Icons.science_outlined, 'Methodology Helper'),
                  const SizedBox(width: 8),
                  _buildSuggestedChip(theme, Icons.analytics_outlined, 'Data Visualizer'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/projects');
          } else if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/network');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: theme.colorScheme.secondary,
        unselectedItemColor: theme.colorScheme.outline,
        selectedLabelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Network',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard(ThemeData theme, IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${title.replaceAll('\n', ' ')} is under development.')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: theme.colorScheme.secondary),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentBlueSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
