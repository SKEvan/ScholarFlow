import 'package:flutter/material.dart';
import '../theme.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final int _activeTab = 2; // Network tab active

  // Data for "Collaborated Papers" carousel
  final List<Map<String, String>> _collaboratedPapers = [
    {
      'discipline': 'NEUROSCIENCE',
      'status': 'IN REVIEW',
      'title': 'Neural Pathways in Hybrid AI',
      'authors': 'Dr. Aris, Prof. Zhang',
    },
    {
      'discipline': 'ETHICS',
      'status': 'DRAFTING',
      'title': 'Algorithmic Governance & Policy',
      'authors': 'Dr. Sarah Jenkins, Eli Vance',
    },
    {
      'discipline': 'QUANTUM',
      'status': 'IN REVIEW',
      'title': 'Variational Circuit Scaling',
      'authors': 'Prof. Zhang, M. Thorne',
    },
  ];

  // Data for "AI Collaboration Tools" 2x2 grid
  final List<Map<String, dynamic>> _aiTools = [
    {
      'icon': Icons.summarize,
      'title': 'Generate Summary',
      'subtitle': 'Synthesize key findings across partners.',
      'route': '/summarizer-review',
    },
    {
      'icon': Icons.compare_arrows,
      'title': 'Comparison Gap',
      'subtitle': 'Analyze divergent arguments in drafts.',
      'route': '/comparison-gap',
    },
    {
      'icon': Icons.search,
      'title': 'Research Gap',
      'subtitle': 'Identify unexplored domains in collection.',
      'route': '/literature-review',
    },
    {
      'icon': Icons.menu_book,
      'title': 'Literature Review',
      'subtitle': 'Automated bibliography synthesis.',
      'route': '/literature-review',
    },
  ];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryNavy,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Collaborated Papers
            _buildSectionHeader(theme, 'Collaborated Papers',
                onViewAll: () {}),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _collaboratedPapers.length,
                itemBuilder: (context, index) =>
                    _buildPaperCard(theme, _collaboratedPapers[index]),
              ),
            ),
            const SizedBox(height: 16),

            // Section 2: Collaboration Requests
            _buildSectionHeader(theme, 'Collaboration Requests'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRequestCard(
                      theme,
                      icon: Icons.person_add,
                      label: 'Send Request',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRequestCard(
                      theme,
                      icon: Icons.group_add,
                      label: 'Join Project',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: AI Collaboration Tools
            _buildSectionHeader(theme, 'AI Collaboration Tools'),
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
                children:
                    _aiTools.map((t) => _buildAIToolTile(theme, t)).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/projects');
          } else if (index == 3) {
            Navigator.of(context).pushReplacementNamed('/ai-tools');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: theme.colorScheme.secondary,
        unselectedItemColor: theme.colorScheme.outline,
        selectedLabelStyle: theme.textTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle:
            theme.textTheme.labelLarge?.copyWith(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_open), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Network'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
        ],
      ),
    );
  }

  // ─── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(ThemeData theme, String title,
      {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'VIEW ALL',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Collaborated paper card ───────────────────────────────────────────────
  Widget _buildPaperCard(ThemeData theme, Map<String, String> paper) {
    final isReview = paper['status'] == 'IN REVIEW';
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    paper['discipline']!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isReview
                      ? AppTheme.accentBlueSoft
                      : const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isReview
                        ? theme.colorScheme.secondary
                        : const Color(0xFFD6A700),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  paper['status']!,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isReview
                        ? theme.colorScheme.secondary
                        : const Color(0xFF8A6500),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                paper['title']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                paper['authors']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Collaboration request card (dark) ─────────────────────────────────────
  Widget _buildRequestCard(ThemeData theme,
      {required IconData icon, required String label}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/add-collaborator');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── AI tool tile ──────────────────────────────────────────────────────────
  Widget _buildAIToolTile(ThemeData theme, Map<String, dynamic> tool) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(tool['route'] as String);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentBlueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(tool['icon'] as IconData,
                  color: theme.colorScheme.secondary, size: 22),
            ),
            const Spacer(),
            Text(
              tool['title'] as String,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
}
