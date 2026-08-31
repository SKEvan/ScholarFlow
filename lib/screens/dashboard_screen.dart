import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_route_observer.dart';
import '../services/backend_api.dart';
import '../services/user_session.dart';
import '../widgets/floating_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  late Future<List<Map<String, dynamic>>> _projectsFuture;
  Map<String, dynamic> _profile = const {};
  List<String> _missingFields = const [];
  bool _profileLoaded = false;
  bool _showAppBar = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _projectsFuture = BackendApi.listProjects(ownerId: UserSession.userId);
  }

  @override
  void dispose() {
    dashboardRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // A route pushed on top of us (e.g. the invitations inbox) just popped.
    // Re-fetch projects so a freshly-accepted invite shows up immediately.
    super.didPopNext();
    if (mounted) {
      // Fire-and-forget; the Future setter updates _projectsFuture via setState.
      _refreshProjects();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      // Scrolling down the list (sliding content up): hide AppBar
      if (delta > 0.5) {
        if (_showAppBar) {
          setState(() => _showAppBar = false);
        }
      }
      // Scrolling up the list (sliding content down): reappear AppBar
      else if (delta < -0.5) {
        if (!_showAppBar) {
          setState(() => _showAppBar = true);
        }
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        if (!_showAppBar) {
          setState(() => _showAppBar = true);
        }
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      dashboardRouteObserver.subscribe(this, route);
    }
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
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: lightSkyBlue,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/editor-test'),
        label: const Text('Test Editor Widget'),
        icon: const Icon(Icons.edit_note_rounded),
      ),
      body: Stack(
        children: [
          // Subtle Ambient Background Shapes
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
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
            bottom: 100,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.06),
              ),
            ),
          ),

          // Main Content
          NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: RefreshIndicator(
              onRefresh: _refreshProjects,
              color: brandColor,
              edgeOffset: topPadding + kToolbarHeight,
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
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      topPadding + kToolbarHeight + 8,
                      20,
                      120,
                    ),
                    children: [
                      // Minimal Header Banner
                      _buildHeaderCard(context, theme, brandColor),
                      const SizedBox(height: 16),

                      // Profile completion warning banner
                      if (_needsProfileCompletion) ...[
                        _buildProfileWarningCard(context, theme),
                        const SizedBox(height: 16),
                      ],

                      // Overview Cards
                      _buildQuickStats(projects.length, totalPapers),
                      const SizedBox(height: 20),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Running Projects',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF0F172A),
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            '${projects.length} Active',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // List State
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
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),

          // Collapsible Animated Top AppBar (slides in only on fast scroll up or top of screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _showAppBar ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showAppBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: lightSkyBlue,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Center(
                        child: Text(
                          'ScholarFlow',
                          style: GoogleFonts.poppins(
                            textStyle: theme.textTheme.titleLarge,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                            fontSize: 22,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Glassmorphism Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: FloatingNavBar(
              currentRoute: '/dashboard',
              needsProfileCompletion: _needsProfileCompletion,
            ),
          ),
        ],
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
                      fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
                            fontWeight: FontWeight.w500,
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
                        fontWeight: FontWeight.w500,
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
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
