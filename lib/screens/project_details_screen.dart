import 'package:flutter/material.dart';
import '../widgets/add_to_project_sheet.dart';

class ProjectDetailsScreen extends StatefulWidget {
  const ProjectDetailsScreen({super.key});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final int _activeTab = 1; // Projects active
  final TextEditingController _aiRequestController = TextEditingController();
  final FocusNode _aiRequestFocusNode = FocusNode();
  final List<Map<String, dynamic>> _aiTools = [
    {
      'icon': Icons.summarize,
      'title': 'Generate Summary',
      'subtitle': 'Synthesize key findings across partners.',
      'choices': ['General Summary', 'Key insights', 'Critical Analysis'],
    },
    {
      'icon': Icons.compare_arrows,
      'title': 'Comparison Gap',
      'subtitle': 'Analyze divergent arguments in drafts.',
      'choices': [
        'Overall Comparison',
        'Similarity and Difference',
        'Strength and Limitation',
      ],
    },
    {
      'icon': Icons.search,
      'title': 'Research Gap',
      'subtitle': 'Identify unexplored domains in collection.',
      'choices': [
        'Research Gaps',
        'Future Research Opportunities',
        'Strengths and Limitations',
      ],
    },
    {
      'icon': Icons.menu_book,
      'title': 'Literature Review',
      'subtitle': 'Automated bibliography synthesis.',
      'choices': ['Narrative Review', 'Theme based Review', 'Critical Review'],
    },
  ];
  String _selectedAiOutput = 'No AI output selected yet.';
  String _selectedAiTool = 'Generate Summary';
  String _selectedAiChoice = 'General Summary';
  String _selectedAiPrompt = 'Enter what you want the AI to focus on.';
  String _projectTitle = 'Ethical AI Framework';

  @override
  void dispose() {
    _aiRequestController.dispose();
    _aiRequestFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args != null) {
      if (args == 'genomics') {
        _projectTitle = 'Genomics ML Study';
      } else if (args == 'urban-planning') {
        _projectTitle = 'Sustainable Urban Planning';
      } else if (args == 'memory') {
        _projectTitle = 'Neural Correlates of Memory';
      } else if (args == 'quantum-macro') {
        _projectTitle = 'Quantum Macro Systems';
      } else if (args == 'literacy-trends') {
        _projectTitle = 'Digital Literacy Trends';
      }
    }
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
            Navigator.of(context).pop();
          },
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
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project link copied to clipboard!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit project requested.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overview / Hero Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'IN PROGRESS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Overview',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Progress ring
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 52,
                                height: 52,
                                child: CircularProgressIndicator(
                                  value: 0.65,
                                  strokeWidth: 5,
                                  backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                                ),
                              ),
                              const Text(
                                '65%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'START DATE',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Oct 12, 2023',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEADLINE',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'May 24, 2024',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PRIMARY INVESTIGATOR',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: theme.colorScheme.secondary.withOpacity(0.15),
                            child: Text(
                              'DS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dr. Scholar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Collaboration Request Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          size: 18,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Collaboration Request',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Invite collaborators or request help.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/add-collaborator');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text('Request'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Research Papers Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Research Papers',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildPaperCard(
                      theme,
                      icon: Icons.description,
                      iconColor: theme.colorScheme.error,
                      bgColor: theme.colorScheme.errorContainer.withOpacity(0.3),
                      title: 'Algorithmic Bias Study',
                      subtitle: 'PDF • 2.4 MB',
                      actionIcon: Icons.download,
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading study paper...')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildPaperCard(
                      theme,
                      icon: Icons.menu_book,
                      iconColor: theme.colorScheme.secondary,
                      bgColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
                      title: 'Human-in-the-Loop',
                      subtitle: 'DOCX • 1.1 MB',
                      actionIcon: Icons.visibility,
                      onAction: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Preview Document'),
                            content: const Text('Displaying a simulated content summary for "Human-in-the-Loop.docx".'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Collaborators Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Collaborators',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildCollaborator(
                      theme,
                      url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAK6WLjABQJBthBM_K7hJ1-Yd8yRRQk3Na__5TpcenLfduEoOTg2np8MWa3y5HWPMzSPLJG-ChBysz3N0ukMVOYK6QMGiEbvmgs5rzBB6U3XqzoBEmyVmtkgAEZv0V0z1xNRl5klyYrt9B48PNqFVCVkJ0MlViFWL2dj4jTu5eM86ah6vnDj4KDnGtPLCajZs5uwqqfWjaBf-17jZHDOgaMB11M0j1ZK_rjfQluQCkXgN1I-hYT8we811mvQ8wkOE-tj1sovAeFWms',
                      name: 'Dr. Vance',
                      role: 'Lead',
                      isActive: true,
                    ),
                    const SizedBox(width: 16),
                    _buildCollaborator(
                      theme,
                      url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCpmwYRerCB22znQd7-SDvk0aR3xtMfwshua3BhFi6ldR96kCmJzGpAl9EZkNGaUeHvjOEDK3sr9rxWcJ2teEqWRU7F1j_b0c7DA8AFJZxWQCGysTgigN4_QlubpFzWGakXVMeU9i8lfEbHyrGB3K86IXhixD5qt5MB0xn088PQiYL7XnpNljtOfYN9Q-nwzpmVf-BJe_KbeO5jMGwvL0n2n5F-SDWuWV-huuaZV-Zd1qXPhpyf0qTp0ni_6Ez97NuyBdz9YXf1BxA',
                      name: 'Sarah Chen',
                      role: 'Reviewer',
                    ),
                    const SizedBox(width: 16),
                    _buildCollaborator(
                      theme,
                      url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuANGF2S6zDntOtGNYi45Niv4EcuMPDzZxmwJPTEVKLygS6HAllUJ2WLjKp4BeN3TUHPPqNwmSdlMumOm4qJu36fndMe2GS0dmyUchoK0RznNWyqjgpxpNCo2kw54GiKSPSEdmkTPvqibJfC5_EZh8Qd_G5H56vyANU_yY1OD4GxhQhMEYvhptGlXiB2YVzoGzOPxkeI2dcs1umFg-CWoNu0JUL6iIAgm4P0XikaeV3Fj5Yqh-ysp35_BMmj6UmjgejqUzSop_tvYik',
                      name: 'Prof. Aris',
                      role: 'Ethics',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Activity Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 16.0),
                child: Column(
                  children: [
                    _buildTimelineRow(
                      theme,
                      title: "Uploaded 'Methodology_v2'",
                      description: 'Dr. Scholar attached a new document to the library.',
                      time: '2 hours ago',
                      isFirst: true,
                    ),
                    _buildTimelineRow(
                      theme,
                      title: 'Milestone Reached: Phase 1',
                      description: 'The initial framework review has been marked as completed.',
                      time: 'Yesterday, 4:15 PM',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // AI Collaboration Tools
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'AI Collaboration Tools',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: _aiTools
                      .map((tool) => _buildAIToolTile(theme, tool))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildAiOutputCard(theme),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddToProjectSheet(context);
        },
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
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
        ],
      ),
    );
  }

  Widget _buildPaperCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(actionIcon, color: theme.colorScheme.outline),
            onPressed: onAction,
          ),
        ],
      ),
    );
  }

  Widget _buildAIToolTile(ThemeData theme, Map<String, dynamic> tool) {
    return InkWell(
      onTap: () {
        _showAiOutputChooser(theme, tool);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tool['icon'] as IconData,
                color: theme.colorScheme.secondary,
                size: 22,
              ),
            ),
            const Spacer(),
            Text(
              tool['title'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tool['subtitle'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.outline,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiOutputCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected AI Output',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tool: $_selectedAiTool',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Output type: $_selectedAiChoice',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedAiOutput,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedAiPrompt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _showAiOutputChooser(ThemeData theme, Map<String, dynamic> tool) {
    final String toolTitle = tool['title'] as String;
    final List<String> choices = List<String>.from(tool['choices'] as List);
    final TextEditingController promptController = TextEditingController(
      text: _aiRequestController.text,
    );
    String activeChoice = _selectedAiChoice;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void clearChoiceSelection() {
              if (activeChoice.isNotEmpty) {
                setSheetState(() {
                  activeChoice = '';
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      toolTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick an output type and describe what you want it to focus on.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: choices.map((choice) {
                        return ChoiceChip(
                          label: Text(choice),
                          selected: activeChoice == choice,
                          onSelected: (_) {
                            setSheetState(() {
                              activeChoice = choice;
                              promptController.clear();
                              _aiRequestController.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Focus(
                      focusNode: _aiRequestFocusNode,
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          clearChoiceSelection();
                        }
                      },
                      child: TextField(
                        controller: promptController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'What should the AI focus on?',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final promptText = promptController.text.trim();
                          setState(() {
                            _selectedAiTool = toolTitle;
                            _selectedAiChoice = activeChoice.isEmpty ? 'Custom' : activeChoice;
                            _selectedAiPrompt = promptText.isEmpty
                                ? 'No prompt provided.'
                                : promptText;
                            _selectedAiOutput =
                              'Placeholder $toolTitle output for "$_selectedAiChoice" will appear here once the backend is connected.';
                            _aiRequestController.text = promptText;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Update Project Output'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCollaborator(
    ThemeData theme, {
    required String url,
    required String name,
    required String role,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? theme.colorScheme.secondary : Colors.transparent,
              width: 2.0,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            backgroundImage: NetworkImage(url),
            child: ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          role,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.outline,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(
    ThemeData theme, {
    required String title,
    required String description,
    required String time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst ? theme.colorScheme.secondary : theme.colorScheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : theme.colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
