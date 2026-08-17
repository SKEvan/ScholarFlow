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
        _missingFields = missingFields
            .map((value) => value.toString())
            .toList();
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
    Navigator.of(context)
        .pushNamed(
          '/project-details',
          arguments: {
            'projectId': project['id'],
            'projectTitle': project['title'] ?? 'Project',
          },
        )
        .then((_) => _refreshProjects());
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

  String get _userName {
    final name = _profile['full_name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Researcher';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandColor = Color(0xFF017ECB);
    const lightSkyBlue = Color(0xFFEAF4FB);

    return Scaffold(
      backgroundColor: lightSkyBlue,
      appBar: AppBar(
        backgroundColor: lightSkyBlue,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: brandColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/logo.png', height: 26, width: 26),
            ),
            const SizedBox(width: 10),
            Text(
              'ScholarFlow',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                fontSize: 19,
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: brandColor,
                  image: DecorationImage(
                    image: AssetImage('assets/logo.png'),
                    opacity: 0.05,
                    fit: BoxFit.cover,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: brandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                accountName: Text(
                  _userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Text(
                  _profile['email']?.toString() ??
                      UserSession.userId ??
                      'Scholar Workspace',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.dashboard_outlined,
                  color: brandColor,
                ),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                selected: true,
                selectedTileColor: brandColor.withValues(alpha: 0.08),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF475569),
                ),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              if (_needsProfileCompletion)
                ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD97706),
                  ),
                  title: const Text('Complete your profile'),
                  subtitle: const Text(
                    'Required fields missing',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(
                      '/complete-profile',
                      arguments: {'profile': _profile},
                    );
                  },
                ),
              const Spacer(),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  await UserSession.clear();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed('/signin');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Modern Design Objects
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withValues(alpha: 0.12),
                    brandColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: const Color(0xFF0284C7).withValues(alpha: 0.06),
              ),
            ),
          ),
          // Screen Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshProjects,
              color: brandColor,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _projectsFuture,
                builder: (context, snapshot) {
                  final projects =
                      snapshot.data ?? const <Map<String, dynamic>>[];
                  final totalPapers = projects.fold<int>(
                    0,
                    (sum, item) => sum + ((item['paper_count'] as int?) ?? 0),
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                    children: [
                      // Greeting & Header Card
                      _buildHeaderCard(context, theme, brandColor),
                      const SizedBox(height: 20),

                      // Missing Profile Warning Banner
                      if (_needsProfileCompletion) ...[
                        _buildProfileWarningCard(context, theme),
                        const SizedBox(height: 20),
                      ],

                      // Stats Overview Grid
                      _buildQuickStats(projects.length, totalPapers),
                      const SizedBox(height: 24),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Running Projects',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${projects.length} Total',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Projects Content State
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) ...[
                        const SizedBox(height: 40),
                        const Center(
                          child: CircularProgressIndicator(color: brandColor),
                        ),
                      ] else if (snapshot.hasError) ...[
                        _buildErrorCard(snapshot.error.toString(), brandColor),
                      ] else if (projects.isEmpty) ...[
                        _buildEmptyState(context, brandColor),
                      ] else ...[
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
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamed('/create-folder').then((_) => _refreshProjects());
        },
        elevation: 3,
        highlightElevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          'New Project',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: brandColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    Color brandColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF017ECB), Color(0xFF0058BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back 👋',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Literature Workspace & Semantic Analysis',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileWarningCard(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed('/complete-profile', arguments: {'profile': _profile}),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Add missing academic information to personalize your literature discovery.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFD97706),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(int projectCount, int paperCount) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Active Projects',
            value: projectCount.toString(),
            icon: Icons.folder_open_rounded,
            color: const Color(0xFF017ECB),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Papers Compiled',
            value: paperCount.toString(),
            icon: Icons.description_outlined,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_copy_outlined,
              size: 40,
              color: brandColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Running Projects Yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by creating your first research project folder to organize academic papers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed('/create-folder').then((_) => _refreshProjects()),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create First Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load projects',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF991B1B),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshProjects,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
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

    final isCompleted = status.toLowerCase() == 'completed';
    final statusBgColor = isCompleted
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFEFF6FF);
    final statusTextColor = isCompleted
        ? const Color(0xFF059669)
        : const Color(0xFF0284C7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF017ECB).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Color(0xFF017ECB),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            fontSize: 16,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.article_outlined,
                        label: '$paperCount Papers',
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.history_rounded,
                        label: '$versionCount Versions',
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
