import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_images.dart';
import '../core/theme/app_spacing.dart';
import 'admin_auth_provider.dart';
import 'admin_icons.dart';
import 'screens/admin_analytics_screen.dart';
import 'screens/admin_announcements_screen.dart';
import 'screens/admin_communities_screen.dart';
import 'screens/admin_content_screen.dart';
import 'screens/admin_conversation_history_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_moderators_screen.dart';
import 'screens/admin_spotlight_screen.dart';
import 'screens/admin_users_screen.dart';

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
      const AdminDashboardScreen(),
      const AdminUsersScreen(),
      const AdminModeratorsScreen(),
      const AdminContentScreen(),
      const AdminCommunitiesScreen(),
      const AdminAnalyticsScreen(),
      const AdminAnnouncementsScreen(),
      const AdminConversationHistoryScreen(),
      const AdminSpotlightScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: Row(
        children: <Widget>[
          // ── Sidebar Navigation Drawer ─────────────────────────────────────
          _AdminSidebar(selectedIndex: _selectedIndex, onSelected: _select),

          // ── Main Screen View Area ─────────────────────────────────────────
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: screens),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<_NavSection> _sections = <_NavSection>[
    _NavSection(
      title: 'PLATFORM',
      items: <_NavItem>[
        _NavItem(iconPath: AdminIcons.chart, label: 'Dashboard'),
        _NavItem(iconPath: AdminIcons.users, label: 'Users'),
        _NavItem(iconPath: AdminIcons.shield, label: 'Moderators'),
        _NavItem(iconPath: AdminIcons.image, label: 'Content'),
        _NavItem(iconPath: AdminIcons.globe, label: 'Communities'),
        _NavItem(iconPath: AdminIcons.chart, label: 'Analytics'),
        _NavItem(iconPath: AdminIcons.megaphone, label: 'Announcements'),
      ],
    ),
    _NavSection(
      title: 'ENGAGEMENT',
      items: <_NavItem>[
        _NavItem(
          iconPath: AdminIcons.convo,
          label: 'Conversation of the day',
        ),
        _NavItem(
          iconPath: AdminIcons.spotlight,
          label: 'Community spotlight',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final String? email = context.select<AdminAuthProvider, String?>(
      (AdminAuthProvider provider) => provider.email,
    );
    final String name = email == null
        ? 'Dana Okafor'
        : email.split('@').first.replaceAll('.', ' ');

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Top Brand Logo (icon + gradient QUEERLOOP+ wordmark)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Image.asset(AppImages.logo, width: 28, height: 11),
                const SizedBox(width: 8),
                Image.asset(AppImages.logoName, height: 17),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Expanded(
            child: SingleChildScrollView(
              child: _buildSections(),
            ),
          ),

          // Bottom Divider
          Divider(color: Colors.white.withValues(alpha: 0.09)),
          const SizedBox(height: AppSpacing.sm),

          // Bottom User Profile Card (Admin)
          Row(
            children: <Widget>[
              ClipOval(
                child: Image.asset(
                  AppImages.user2,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF3EFF7),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Admin',
                      style: TextStyle(color: Color(0xFF948CA3), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF3FE0AE),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF3FE0AE).withValues(alpha: 0.18),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSections() {
    int index = 0;
    final List<Widget> children = <Widget>[];
    for (final _NavSection section in _sections) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            section.title,
            style: const TextStyle(
              color: Color(0xFF635C72),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.9,
            ),
          ),
        ),
      );
      children.add(const SizedBox(height: AppSpacing.sm));
      for (final _NavItem item in section.items) {
        children.add(_buildSidebarItem(index: index, item: item));
        index++;
      }
      children.add(const SizedBox(height: AppSpacing.lg));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildSidebarItem({required int index, required _NavItem item}) {
    final bool isSelected = selectedIndex == index;
    final Color iconColor =
        isSelected ? const Color(0xFF00E5FF) : const Color(0xFF948CA3);

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
            color: isSelected ? const Color(0xFF1C1824) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              if (item.iconPath.endsWith('.svg'))
                SvgPicture.asset(
                  item.iconPath,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                )
              else
                Image.asset(
                  item.iconPath,
                  width: 16,
                  height: 16,
                  color: iconColor,
                  colorBlendMode: BlendMode.srcIn,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFF3EFF7)
                        : const Color(0xFF948CA3),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

class _NavSection {
  const _NavSection({required this.title, required this.items});

  final String title;
  final List<_NavItem> items;
}

class _NavItem {
  const _NavItem({required this.iconPath, required this.label});

  final String iconPath;
  final String label;
}
