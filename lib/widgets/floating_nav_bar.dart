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
    const double barHeight = 58.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: 340,
        height:
            barHeight +
            14, // Extra height for the elevated central floating button
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Custom Notched Bar Canvas Background
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight,
              child: CustomPaint(
                painter: _NotchedBarPainter(
                  bgColor: Colors.white.withValues(alpha: 0.94),
                  borderColor: Colors.white.withValues(alpha: 0.9),
                ),
                child: SizedBox(
                  height: barHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left Item 1: Home
                      _NavIconItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Home',
                        isSelected: currentRoute == '/dashboard',
                        onTap: () {
                          if (currentRoute != '/dashboard') {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed('/dashboard');
                          }
                        },
                      ),

                      // Left Item 2: Notes
                      _NavIconItem(
                        icon: Icons.edit_note_rounded,
                        label: 'Notes',
                        isSelected: currentRoute == '/notes',
                        onTap: () {
                          if (currentRoute != '/notes') {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed('/notes');
                          }
                        },
                      ),

                      // Center Gap for the big floating notch button
                      const SizedBox(width: 48),

                      // Right Item 1: Profile
                      _NavIconItem(
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

                      // Right Item 2: Logout (Replaced Projects)
                      _NavIconItem(
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

            // Prominent Circular Floating Action Button (+ New Project) with Soft/Reduced Shadow
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/create-folder');
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: brandColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: brandColor.withValues(alpha: 0.22),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  _NotchedBarPainter({required this.bgColor, required this.borderColor});

  final Color bgColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = h / 2; // rounded ends

    final path = Path();
    path.moveTo(r, 0);
    path.lineTo(cx - 34, 0);

    // Smooth organic notch dip in center top
    path.cubicTo(cx - 20, 0, cx - 20, 23, cx, 23);
    path.cubicTo(cx + 20, 23, cx + 20, 0, cx + 34, 0);

    path.lineTo(w - r, 0);
    path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    path.lineTo(w, h - r);
    path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    path.lineTo(r, h);
    path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    path.close();

    // Soft drop shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.10), 10, true);

    // Background fill
    final fillPaint = Paint()..color = bgColor;
    canvas.drawPath(path, fillPaint);

    // Subtle outline border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavIconItem extends StatelessWidget {
  const _NavIconItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge = false,
    this.activeColor = const Color(0xFF017ECB),
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool badge;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (badge)
                  Positioned(
                    top: 1,
                    right: 1,
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
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
