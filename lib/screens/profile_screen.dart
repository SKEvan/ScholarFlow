import 'package:flutter/material.dart';

import '../widgets/floating_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(
          'Researcher Profile',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushNamed('/add-collaborator');
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Profile Header Section
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.secondary.withOpacity(0.3),
                                width: 3.0,
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundImage: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuCDjXO6XdfVP3zb59HMwG0pquQ-J-rFjlEydjXls8se839eUpxOxo3bL0RJr9L4LQZzo8IAc7DYmcKWmLraT6Kzmdl6Tnxl0q3tYfF6mkOd4g5ybsZpDEqY6jg2IfzXU6-Uw4NHqO5pRCgmLdcdyPGF609Un814FBXuLAZZ1nsXUGHNfK33eUMUBHI8dWJbXkhA36U0-HypTZjjlzHt69Df6Z7CbxMx1nMdnciVKL3UpcpKGzYxBxWDEDGhhAHE2Iyz8FJW5u77tWE',
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.0),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dr. Julian Vance',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lead Researcher',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stanford University • AI Research Lab',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Stats Row
                Row(
                  children: [
                    _buildStatBox(theme, 'PAPERS', '12'),
                    const SizedBox(width: 12),
                    _buildStatBox(theme, 'CITATIONS', '156'),
                    const SizedBox(width: 12),
                    _buildStatBox(theme, 'H-INDEX', '8'),
                  ],
                ),
                const SizedBox(height: 24),
                // About Section
                _buildSectionHeader(theme, 'ABOUT'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Dr. Vance specializes in the intersection of neural networks and ethical governance. With over a decade of experience in quantum machine learning, his work focuses on creating transparent AI systems for public sector applications.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Active Projects
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(theme, 'ACTIVE PROJECTS'),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'VIEW ALL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProjectCard(
                  theme: theme,
                  icon: Icons.hub,
                  title: 'Decentralized Neural Fabric',
                  description:
                      'Investigating distributed inference protocols across quantum-classical hybrid nodes.',
                  progress: 0.65,
                ),
                const SizedBox(height: 12),
                _buildProjectCard(
                  theme: theme,
                  icon: Icons.security,
                  title: 'Ethical Latency Models',
                  description:
                      'Real-time bias detection in high-frequency automated decision engines.',
                  progress: 0.40,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: FloatingNavBar(currentRoute: '/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(ThemeData theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.outline,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProjectCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String description,
    required double progress,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 14, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
                        minHeight: 4,
                      ),
                    ),
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
