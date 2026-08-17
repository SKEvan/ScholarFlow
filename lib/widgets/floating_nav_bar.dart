import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/user_session.dart';

class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({
    super.key,
    required this.currentRoute,
    this.needsProfileCompletion = false,
  });

  final String currentRoute;
  final bool needsProfileCompletion;

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  Timer? _autoCloseTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isExpanded) {
        _collapse();
      }
    });
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _controller.forward();
    _startAutoCloseTimer();
  }

  void _collapse() {
    _autoCloseTimer?.cancel();
    setState(() {
      _isExpanded = false;
    });
    _controller.reverse();
  }

  void _toggleMenu() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF017ECB);

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 26),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(
                      alpha: _isExpanded ? 0.20 : 0.14,
                    ),
                    blurRadius: _isExpanded ? 24 : 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _isExpanded ? 0.90 : 0.82,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.85),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Permanent Menu Toggle Icon Button
                        _buildMenuToggleButton(brandColor),

                        // Drawer Animation for Menu Options
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          axis: Axis.horizontal,
                          alignment: Alignment.centerLeft,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 4),
                                Container(
                                  height: 22,
                                  width: 1.2,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(width: 4),

                                // Dashboard Option
                                _NavItem(
                                  icon: Icons.grid_view_rounded,
                                  label: 'Dashboard',
                                  isSelected:
                                      widget.currentRoute == '/dashboard',
                                  onTap: () {
                                    _autoCloseTimer?.cancel();
                                    if (widget.currentRoute != '/dashboard') {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/dashboard');
                                    } else {
                                      _collapse();
                                    }
                                  },
                                ),
                                const SizedBox(width: 2),

                                // New Project Option
                                _NavItem(
                                  icon: Icons.add_circle_rounded,
                                  label: 'New Project',
                                  isSelected: false,
                                  isHighlight: true,
                                  onTap: () {
                                    _autoCloseTimer?.cancel();
                                    _collapse();
                                    Navigator.of(
                                      context,
                                    ).pushNamed('/create-folder');
                                  },
                                ),
                                const SizedBox(width: 2),

                                // Profile Option
                                _NavItem(
                                  icon: Icons.person_rounded,
                                  label: 'Profile',
                                  isSelected: widget.currentRoute == '/profile',
                                  badge: widget.needsProfileCompletion,
                                  onTap: () {
                                    _autoCloseTimer?.cancel();
                                    if (widget.currentRoute != '/profile') {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/profile');
                                    } else {
                                      _collapse();
                                    }
                                  },
                                ),
                                const SizedBox(width: 2),

                                // Logout Option
                                _NavItem(
                                  icon: Icons.logout_rounded,
                                  label: 'Logout',
                                  isSelected: false,
                                  activeColor: const Color(0xFFEF4444),
                                  onTap: () async {
                                    _autoCloseTimer?.cancel();
                                    await UserSession.clear();
                                    if (!context.mounted) return;
                                    Navigator.of(
                                      context,
                                    ).pushNamedAndRemoveUntil(
                                      '/signin',
                                      (route) => false,
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuToggleButton(Color brandColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleMenu,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _isExpanded
                ? brandColor.withValues(alpha: 0.15)
                : brandColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RotationTransition(
                turns: _rotateAnimation,
                child: Icon(
                  _isExpanded ? Icons.tune_rounded : Icons.widgets_rounded,
                  color: brandColor,
                  size: 21,
                ),
              ),
              if (widget.needsProfileCompletion && !_isExpanded)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
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
                const SizedBox(height: 2),
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
