import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSignIn() {
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF017ECB),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -40,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -90,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/logo.png', height: 32),
                          const SizedBox(width: 8),
                          Text(
                            'ScholarFlow',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (_currentPage < 3)
                        TextButton(
                          onPressed: _navigateToSignIn,
                          child: Text(
                            'SKIP',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white.withOpacity(0.84),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 48, width: 60),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildDiscoveryCard(theme),
                      _buildReviewCard(theme),
                      _buildCollaborationCard(theme),
                      _buildGetStartedCard(theme),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 24.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (index) => _buildDot(index, theme),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0)
                            IconButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              icon: const Icon(Icons.chevron_left, size: 28),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                          if (_currentPage < 3)
                            IconButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              icon: const Icon(Icons.chevron_right, size: 28),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 32.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildCardFrame({
    required ThemeData theme,
    required String category,
    required Widget visualContent,
    required String title,
    required String description,
    List<Widget>? extraElements,
  }) {
    return Container(
      margin: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Tag
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                category.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Central Visual
          Center(child: visualContent),
          const Spacer(),
          // Text Details
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
              height: 1.5,
            ),
          ),
          if (extraElements != null) ...[
            const SizedBox(height: 20),
            ...extraElements,
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDiscoveryCard(ThemeData theme) {
    return _buildCardFrame(
      theme: theme,
      category: 'Discovery',
      visualContent: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.search, size: 64, color: theme.colorScheme.secondary),
      ),
      title: 'Intelligent Paper Discovery',
      description:
          'Navigate millions of academic papers with AI-driven semantic search that understands context, not just keywords.',
      extraElements: [
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            _buildTag(theme, 'Neural Mapping'),
            _buildTag(theme, 'Cross-Domain Synthesis'),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(ThemeData theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.secondary.withOpacity(0.15),
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.secondary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme) {
    return _buildCardFrame(
      theme: theme,
      category: 'Review',
      visualContent: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 180,
            height: 110,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                // Simulated pulsing lines
                _buildPulseLine(80),
                const SizedBox(height: 4),
                _buildPulseLine(120),
                const SizedBox(height: 4),
                _buildPulseLine(100),
              ],
            ),
          ),
          Positioned(
            bottom: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      title: 'Automated Literature Reviews',
      description:
          'Generate comprehensive summaries and automated synthesis of complex literature in minutes, not weeks.',
      extraElements: [
        Center(
          child: SizedBox(
            width: 160,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: 0.65,
                backgroundColor: theme.colorScheme.outlineVariant.withOpacity(
                  0.3,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPulseLine(double width) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerMuted,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildCollaborationCard(ThemeData theme) {
    return _buildCardFrame(
      theme: theme,
      category: 'Network',
      visualContent: SizedBox(
        width: 160,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Researcher Avatars
            Positioned(
              top: 0,
              child: _buildAvatarCircle(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBonnxI30_jnHUY--Eu4Fa-DpG2Jpgb0vQMYEEdDhfs_uarpgTvomsIcQSWcwz9SouPY-j4TOWBOXkCNAjMk_dPTyN0SY5CMJXDJ94SIpvAtJLBhDK4WfRVfP6efNN9d4HBxsrABEW0_kpcGcMMESsQvvYXIY8qpVWf4Bd_zDJFpdkVeWmu1Otl6QUCunpXCz8IKNOeHXGwL6OV7CY_aDyeLJyEHxJ33IwmAbwceazLkF5NLaajd_uEgUpvl--I2U6fdZToUqq5fpg',
              ),
            ),
            Positioned(
              bottom: 0,
              left: 10,
              child: _buildAvatarCircle(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC6jmGC_50SXypNLWlPENOo1l797etZqOXthirL8qmMfltl1ZTsbW6qJlk_QsEwHsWDSnIJW3FACfIJOowlIpOc0RziOUWfOzx2WGTpRprGi_zF_YAk66kTKy0d3OI1Hsybsh3woH98scZUPBuvgX-hZFKj1WO2ctV23_SBHYKIxf41kfzRgkEMfJw9q0BumSx9bU6rDG97C-O7mX459AU-519S_EEbRIq7cLLeKVuylu226xy_m5hVm_3dGKkivWDXlD2brjLgSWk',
              ),
            ),
            Positioned(
              bottom: 0,
              right: 10,
              child: _buildAvatarCircle(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCKoKSywPTA_XNhFZQywqeU8yNcj4_PCmuhzgkxAEI_41siL5qxvDsqjhgMZUcGf8_ps3utyGMZy3Fh84phe3CbHvX0jmKQkogUxRxOA4S4iBz5Eq-TJWmOuXAIevwuDTwA9wDPKmQ14csLQrp0EQeerkMO8asAnqUd2BgXq55R1sWOW0ReaAtaIkOw_8FfOIniEZSBObpvFvVtCHGbdHuXbYDUK8_v78yL793eJj3SQqcSF9gwlh4b07Ml_ANAA2_SP6fyrxqJPDg',
              ),
            ),
            // Center network hub icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Icon(
                Icons.hub,
                color: theme.colorScheme.secondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
      title: 'Researcher Collaboration',
      description:
          'Connect with peers globally, share datasets, and co-author papers in secure, AI-enhanced workspaces.',
      extraElements: [
        TextButton.icon(
          onPressed: () {},
          label: const Text('Find Colleagues'),
          icon: const Icon(Icons.arrow_forward, size: 18),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.secondary,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarCircle(String url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person),
        ),
      ),
    );
  }

  Widget _buildGetStartedCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(child: Image.asset('assets/logo.png', height: 64)),
          const Spacer(),
          Text(
            'Ready to Elevate Your Research?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join a community of 50,000+ researchers using AI to break new boundaries in science and academia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToSignIn,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF017ECB),
            ),
            child: const Text('Get Started'),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 14,
                color: theme.colorScheme.outline.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'SECURE & ACADEMIC STANDARD',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.outline.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
