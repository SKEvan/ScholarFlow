import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeTab = 0;

  void _showReportsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text('Research Report'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Summary Metrics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Papers added: 12\n• Co-author annotations: 42\n• Active reading time: 14.5 hours\n• AI assistance tokens used: 8.4k'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
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
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 28,
            ),
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
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: const NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBqb8N9ENDKM_quKjXZ3JQ_fZmTmx9m-t050uLJ6FTT7Zq2M-jlvozURB9ExLUX5DP3WYl_xwJLUXic8qmvscxvQLOE4HF_XDLh6Jokgo8jy7KrC5GS9D28MuXVGoja5m_8uDBVLx3Xc9gvUL_7bK_S1p311exG4nWrqqFq25YTYHjjA6gwzjMGxsTu-NoEAPl78Xe7slevusgjQ1DITxGi-ACP1q8h5Q2w5KLs1kX31YuLt5mCbDwWIqEy99_pu9Om0Ftlk52KXys',
                ),
                backgroundColor: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: theme.colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBqb8N9ENDKM_quKjXZ3JQ_fZmTmx9m-t050uLJ6FTT7Zq2M-jlvozURB9ExLUX5DP3WYl_xwJLUXic8qmvscxvQLOE4HF_XDLh6Jokgo8jy7KrC5GS9D28MuXVGoja5m_8uDBVLx3Xc9gvUL_7bK_S1p311exG4nWrqqFq25YTYHjjA6gwzjMGxsTu-NoEAPl78Xe7slevusgjQ1DITxGi-ACP1q8h5Q2w5KLs1kX31YuLt5mCbDwWIqEy99_pu9Om0Ftlk52KXys',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dr. Julian Vance',
                    style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'Stanford University',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Discover'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Projects'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/projects');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Collaboration'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/add-collaborator');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => Navigator.of(context).pushReplacementNamed('/signin'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search field trigger
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for papers, researchers, or topics',
                  hintStyle: TextStyle(color: theme.colorScheme.outline.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    Navigator.of(context).pushNamed(
                      '/search-results',
                      arguments: query.trim(),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Research Summary metrics
              Text(
                'OVERVIEW',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Research Summary',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      theme,
                      icon: Icons.description,
                      value: '84',
                      label: 'Papers',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      theme,
                      icon: Icons.group,
                      value: '18',
                      label: 'Collabs',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      theme,
                      icon: Icons.timer,
                      value: '248',
                      label: 'Hours',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Grid
              Text(
                'QUICK ACTIONS',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _buildQuickAction(
                    theme,
                    icon: Icons.add_circle,
                    title: 'New Project',
                    bgColor: theme.colorScheme.secondaryContainer.withOpacity(0.15),
                    iconColor: theme.colorScheme.secondary,
                    onTap: () => Navigator.of(context).pushNamed('/create-folder'),
                  ),
                  _buildQuickAction(
                    theme,
                    icon: Icons.analytics,
                    title: 'Reports',
                    bgColor: theme.colorScheme.surfaceContainerHigh,
                    iconColor: theme.colorScheme.secondary,
                    onTap: () => Navigator.of(context).pushNamed('/insights'),
                  ),
                  _buildQuickAction(
                    theme,
                    icon: Icons.folder_shared,
                    title: 'Shared',
                    bgColor: theme.colorScheme.surfaceContainerHigh,
                    iconColor: theme.colorScheme.secondary,
                    onTap: () => Navigator.of(context).pushNamed('/projects'),
                  ),
                  _buildQuickAction(
                    theme,
                    icon: Icons.groups,
                          title: 'Collaboration',
                    bgColor: theme.colorScheme.surfaceContainerHigh,
                    iconColor: theme.colorScheme.secondary,
                          onTap: () => Navigator.of(context).pushNamed('/add-collaborator'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recently Active Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Active',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/projects'),
                    child: Text(
                      'VIEW ALL',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildProjectCard(
                theme,
                category: 'Artificial Intelligence',
                title: 'Ethical AI Framework',
                status: 'ACTIVE',
                progress: 0.65,
                statusBg: theme.colorScheme.secondary.withOpacity(0.1),
                statusTextColor: theme.colorScheme.secondary,
                actionLabel: 'RESUME',
                projectId: 'ethical-ai',
              ),
              const SizedBox(height: 12),
              _buildProjectCard(
                theme,
                category: 'Neural Science',
                title: 'Quantum Neural Networks',
                status: 'REVIEW',
                progress: 0.92,
                statusBg: Colors.orange[50]!,
                statusTextColor: Colors.orange[700]!,
                actionLabel: 'VIEW',
                projectId: 'genomics', // matches one of the project arguments
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/projects');
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

  Widget _buildMetricCard(
    ThemeData theme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.secondary, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    ThemeData theme, {
    required String category,
    required String title,
    required String status,
    required double progress,
    required Color statusBg,
    required Color statusTextColor,
    required String actionLabel,
    required String projectId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Progress',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildAvatar('JD'),
                  Transform.translate(
                    offset: const Offset(-6, 0),
                    child: _buildAvatar('AK'),
                  ),
                  Transform.translate(
                    offset: const Offset(-12, 0),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: theme.colorScheme.secondary,
                      child: const Text(
                        '+2',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/project-details', arguments: projectId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  foregroundColor: theme.colorScheme.secondary,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Colors.grey[200],
      child: Text(
        initials,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }
}
