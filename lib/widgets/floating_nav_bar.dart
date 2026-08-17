import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/user_session.dart';

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentRoute,
    this.needsProfileCompletion = false,
  });

  final String currentRoute;
  final bool needsProfileCompletion;

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF017ECB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: brandColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () {
                    if (currentRoute != '/dashboard') {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.folder_copy_rounded,
                  label: 'Projects',
                  isSelected: currentRoute == '/projects',
                  onTap: () {
                    if (currentRoute != '/projects') {
                      Navigator.of(context).pushReplacementNamed('/projects');
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.add_circle_rounded,
                  label: 'New Project',
                  isSelected: false,
                  isHighlight: true,
                  onTap: () {
                    Navigator.of(context).pushNamed('/create-folder');
                  },
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentRoute == '/profile',
                  badge: needsProfileCompletion,
                  onTap: () {
                    if (currentRoute != '/profile') {
                      Navigator.of(context).pushNamed('/profile');
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isSelected: false,
                  activeColor: const Color(0xFFEF4444),
                  onTap: () async {
                    await UserSession.clear();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/signin',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge = false,
    this.isHighlight = false,
    this.activeColor = const Color(0xFF017ECB),
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool badge;
  final bool isHighlight;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? activeColor
        : (isHighlight ? activeColor : const Color(0xFF64748B));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: isHighlight ? 21 : 19),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            if (badge)
              Positioned(
                top: -1,
                right: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
