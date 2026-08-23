import 'package:flutter/material.dart';
import '../../core/widgets/app_user_avatar.dart';
import '../../core/theme/app_colors.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import 'moderator_action_log_screen.dart';
import 'moderator_dashboard_screen.dart';
import 'moderator_reports_queue_screen.dart';

class ModeratorShell extends StatefulWidget {
  const ModeratorShell({super.key});

  @override
  State<ModeratorShell> createState() => _ModeratorShellState();
}

class _ModeratorShellState extends State<ModeratorShell> {
  int _selectedIndex = 0;

  void _select(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      ModeratorDashboardScreen(onOpenQueue: () => _select(1)),
      const ModeratorReportsQueueScreen(),
      const ModeratorActionLogScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: Row(
        children: <Widget>[
          // ── Sidebar Navigation Drawer ─────────────────────────────────────
          _ModeratorSidebar(
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

class _ModeratorSidebar extends StatelessWidget {
  const _ModeratorSidebar({
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
        color: AppColors.moderatorSurface,
        border: Border(
          right: BorderSide(
            color: AppColors.moderatorBorder,
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
                    color: AppColors.moderatorPink,
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
          Divider(color: AppColors.moderatorBorder),
          const SizedBox(height: AppSpacing.sm),

          // Bottom User Profile Card (MOD-04 Priya)
          Row(
            children: <Widget>[
              AppUserAvatar(
                imageAsset: AppImages.user1,
                size: 38,
                hasGradientBorder: false,
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
                        color: AppColors.moderatorTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Moderator',
                      style: TextStyle(
                        color: AppColors.moderatorTextFaint,
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
                  color: AppColors.gradientCyan,
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
            color: isSelected ? AppColors.moderatorSidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.moderatorTextPrimary : AppColors.moderatorTextMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.moderatorTextPrimary : AppColors.moderatorTextSecondary,
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
                    color: AppColors.gradientCyan,
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
          AppColors.gradientCyan,
          AppColors.moderatorPink,
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
