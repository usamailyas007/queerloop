import 'package:flutter/material.dart';

import '../core/theme/app_images.dart';
import '../core/theme/app_spacing.dart';
import 'screens/action_log_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/reports_queue_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  void _select(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      AdminDashboardScreen(onOpenQueue: () => _select(1)),
      const ReportsQueueScreen(),
      const ActionLogScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121019),
      body: Row(
        children: <Widget>[
          // ── Sidebar Navigation Drawer ─────────────────────────────────────
          _AdminSidebar(
            selectedIndex: _selectedIndex,
            onSelected: _select,
          ),

          // ── Main Screen View Area ─────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF16131D),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Top Brand Logo (QUEERLOOP+)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                CustomPaint(
                  size: const Size(28, 14),
                  painter: _InfinityLogoPainter(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'QUEERLOOP+',
                  style: TextStyle(
                    color: Color(0xFFFF4B8B),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Sidebar Navigation Items
          _buildSidebarItem(
            index: 0,
            icon: Icons.bar_chart_rounded,
            label: 'Dashboard',
          ),
          _buildSidebarItem(
            index: 1,
            icon: Icons.flag_outlined,
            label: 'Reports queue',
            badgeText: '28',
          ),
          _buildSidebarItem(
            index: 2,
            icon: Icons.description_outlined,
            label: 'Action log',
          ),

          const Spacer(),

          // Bottom Divider
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: AppSpacing.sm),

          // Bottom User Profile Card (MOD-04 Priya)
          Row(
            children: <Widget>[
              ClipOval(
                child: Image.asset(
                  AppImages.user1,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const <Widget>[
                    Text(
                      'MOD-04 · Priya',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Moderator',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    String? badgeText,
  }) {
    final bool isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF231E30) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badgeText != null && badgeText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
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

class _InfinityLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF00E5FF),
          Color(0xFFFF4B8B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.5, h * 0.5);
    path.cubicTo(w * 0.7, 0, w, 0, w, h * 0.5);
    path.cubicTo(w, h, w * 0.7, h, w * 0.5, h * 0.5);
    path.cubicTo(w * 0.3, 0, 0, 0, 0, h * 0.5);
    path.cubicTo(0, h, w * 0.3, h, w * 0.5, h * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
