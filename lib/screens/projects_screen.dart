import 'package:flutter/material.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final int _activeTab = 1; // Projects active

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'My Projects',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
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
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Projects'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Network'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/network');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Statistics summary widgets
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Total projects full card
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.folder, color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Projects',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Text(
                                '24',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '+4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.trending_up, size: 14, color: theme.colorScheme.secondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hours Researched & Collaborators grid row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hours Researched',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '1,240',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'HRS',
                                      style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Collaborators',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text(
                                      '12',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    // Overlapping avatars
                                    Row(
                                      children: [
                                        _buildMiniAvatar('JD'),
                                        Transform.translate(
                                          offset: const Offset(-5, 0),
                                          child: _buildMiniAvatar('AK'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickActionBtn(
                          theme,
                          icon: Icons.add,
                          label: 'New Project',
                          onTap: () => Navigator.of(context).pushNamed('/create-folder'),
                        ),
                        _buildQuickActionBtn(
                          theme,
                          icon: Icons.search,
                          label: 'Search Paper',
                          onTap: () => Navigator.of(context).pushNamed('/search-results'),
                        ),
                        _buildQuickActionBtn(
                          theme,
                          icon: Icons.group_add,
                          label: 'Join Space',
                          onTap: () => Navigator.of(context).pushNamed('/network'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Active Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Active',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'See All',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Project feed list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Card 1
                    _buildActiveProjectCard(
                      theme,
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC7cqSV-X9YwX--8bXf9Vy2WaNyviFcTD9_GoYbZ7L2PDSFZq0nv-A1sSb98BGrmeDLUzLaS-CaV79ZQ7CvmPSiZqBsztQJEoi-_fGfh_byimK9gb8ZMAwIxkZ651tS3ekC4eN6C8omZ5A7x9ZhvJPWuofCoqqC_5bhF-LwZX0WvAyZGkD5XAEhs1ZSxaThktCXFBXlNcs4U29MpJvSTGgGL7oKRRjTbvopbzDiEEXKQ_QaNakfdzAmjBtNqbq3bALcT925ksriqM0',
                      badge: 'Active Now',
                      badgeBgColor: Colors.black.withOpacity(0.5),
                      title: 'Neural Science UI',
                      description: 'Development of a tactile feedback interface for direct neural link visualization tools.',
                      collaboratorsCount: 8,
                      onTap: () {
                        Navigator.of(context).pushNamed('/project-details', arguments: 'memory');
                      },
                    ),
                    const SizedBox(height: 16),
                    // Card 2
                    _buildActiveProjectCard(
                      theme,
                      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCTrRdNA1X91Tiad7Z-It8C4oWZM98kbx_vcX2EziuG0zekJKris8ooCIQd-q1Xp9M2Wp7JJys1kkadO2CVm1EBTYZGZ8beQUs4g05Jjy0XI03Sk9FuNmdBIUk-b1dOsFhbNet-k6XhBSX_9VHr-TUJo2EtYzsO5e7piEt4Fux2tq3yegyoqPVy9o7F-66ki1O3sacMLnUl76idg6oXlCwS0J3IhujNfMBYcvr0pX1FNC11MErTJ1b8sudeTwBJosCVxsJDyli8WKI',
                      badge: 'Shared',
                      badgeBgColor: theme.colorScheme.secondary,
                      title: 'AI Logic Core',
                      description: 'Architecture for a recursive reasoning engine based on the latest transformer models.',
                      updateTime: 'Updated 2h ago',
                      progress: 0.65,
                      onTap: () {
                        Navigator.of(context).pushNamed('/project-details', arguments: 'genomics');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _activeTab,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (index == 2) {
            Navigator.of(context).pushReplacementNamed('/network');
          } else if (index == 3) {
            Navigator.of(context).pushReplacementNamed('/ai-tools');
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

  Widget _buildMiniAvatar(String initials) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.0),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 106,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProjectCard(
    ThemeData theme, {
    required String imageUrl,
    required String badge,
    required Color badgeBgColor,
    required String title,
    required String description,
    int? collaboratorsCount,
    String? updateTime,
    double? progress,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover image
              Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Body content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card footer elements
                    if (collaboratorsCount != null) ...[
                      Row(
                        children: [
                          Row(
                            children: [
                              _buildMiniAvatar('JD'),
                              Transform.translate(
                                offset: const Offset(-5, 0),
                                child: _buildMiniAvatar('SC'),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$collaboratorsCount collaborators active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ] else if (updateTime != null && progress != null) ...[
                      Row(
                        children: [
                          Icon(Icons.update, size: 14, color: theme.colorScheme.secondary),
                          const SizedBox(width: 4),
                          Text(
                            updateTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
