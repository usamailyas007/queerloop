import 'package:flutter/material.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_icons.dart';

enum _UserStatus { active, suspended, banned }

class _AdminUser {
  _AdminUser({
    required this.handle,
    required this.pronoun,
    required this.avatar,
    required this.joined,
    required this.posts,
    required this.reports,
    required this.status,
    this.suspendedFor,
  });

  final String handle;
  final String pronoun;
  final String avatar;
  final String joined;
  final int posts;
  final int reports;
  _UserStatus status;
  String? suspendedFor;
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  int _statusFilter = 0; // 0: All, 1: Suspended, 2: Banned
  String _searchQuery = '';

  final List<_AdminUser> _users = <_AdminUser>[
    _AdminUser(
      handle: '@ashinorbit',
      pronoun: 'Ash Mercado · she/they',
      avatar: AppImages.user1,
      joined: '4 Jan 2026',
      posts: 128,
      reports: 0,
      status: _UserStatus.active,
    ),
    _AdminUser(
      handle: '@rowankeeps',
      pronoun: 'Rowan · they/them',
      avatar: AppImages.user2,
      joined: '19 Nov 2025',
      posts: 402,
      reports: 2,
      status: _UserStatus.active,
    ),
    _AdminUser(
      handle: '@dg_returns',
      pronoun: 'No display name',
      avatar: AppImages.user3,
      joined: '11 Mar 2026',
      posts: 37,
      reports: 6,
      status: _UserStatus.suspended,
      suspendedFor: 'Suspended 7d',
    ),
    _AdminUser(
      handle: '@truth_ftw',
      pronoun: 'No display name',
      avatar: AppImages.user4,
      joined: '28 Jul 2026',
      posts: 4,
      reports: 14,
      status: _UserStatus.banned,
    ),
    _AdminUser(
      handle: '@jules.does',
      pronoun: 'Jules · she/her',
      avatar: AppImages.user1,
      joined: '2 Feb 2026',
      posts: 219,
      reports: 1,
      status: _UserStatus.active,
    ),
    _AdminUser(
      handle: '@free_giftcards',
      pronoun: 'Flagged as spam',
      avatar: AppImages.user2,
      joined: '31 Jul 2026',
      posts: 91,
      reports: 17,
      status: _UserStatus.suspended,
      suspendedFor: 'Under review',
    ),
  ];

  static const List<String> _statusLabels = <String>[
    'All status',
    'Suspended',
    'Banned',
  ];

  static const List<String> _suspendOptions = <String>[
    'Suspend · 1 day',
    'Suspend · 3 days',
    'Suspend · 7 days',
    'Suspend · 14 days',
    'Suspend · 30 days',
  ];

  void _applyStatus(_AdminUser user, _UserStatus status, [String? note]) {
    setState(() {
      user.status = status;
      user.suspendedFor = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<_AdminUser> filtered = _users.where((_AdminUser user) {
      final bool matchesSearch = _searchQuery.isEmpty ||
          user.handle.toLowerCase().contains(_searchQuery.toLowerCase());
      final bool matchesFilter = switch (_statusFilter) {
        1 => user.status == _UserStatus.suspended,
        2 => user.status == _UserStatus.banned,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    final int suspendedCount =
        _users.where((_AdminUser u) => u.status == _UserStatus.suspended).length;

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Users',
                          style: TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_users.length} accounts · $suspendedCount currently suspended',
                          style: const TextStyle(
                              color: Color(0xFF948CA3), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: AppTextField(
                      hintText: 'Search by username, email or report ID',
                      prefixIconPath: AdminIcons.search,
                      fillColor: const Color(0xFF141119),
                      onChanged: (String val) =>
                          setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141119),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.09)),
                    ),
                    child: Row(
                      children: <Widget>[
                        for (int i = 0; i < _statusLabels.length; i++)
                          GestureDetector(
                            onTap: () => setState(() => _statusFilter = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: _statusFilter == i
                                    ? const Color(0xFF2C2738)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                _statusLabels[i],
                                style: TextStyle(
                                  color: _statusFilter == i
                                      ? Colors.white
                                      : Color(0xFF948CA3),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Export',
                      height: 40,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141119),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.09)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md - 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.06)),
                          ),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: _ColumnHeader('ACCOUNT'),
                            ),
                            Expanded(flex: 2, child: _ColumnHeader('JOINED')),
                            Expanded(flex: 1, child: _ColumnHeader('POSTS')),
                            Expanded(
                                flex: 2,
                                child: _ColumnHeader('REPORTS AGAINST')),
                            Expanded(flex: 2, child: _ColumnHeader('STATUS')),
                            SizedBox(width: 110),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                          itemBuilder: (_, int index) {
                            final _AdminUser user = filtered[index];
                            return _UserRow(
                              user: user,
                              onSetActive: () =>
                                  _applyStatus(user, _UserStatus.active),
                              onSuspend: (String option) => _applyStatus(
                                  user, _UserStatus.suspended, option),
                              onBan: () =>
                                  _applyStatus(user, _UserStatus.banned),
                              suspendOptions: _suspendOptions,
                            );
                          },
                        ),
                      ),
                    ],
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

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF635C72),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onSetActive,
    required this.onSuspend,
    required this.onBan,
    required this.suspendOptions,
  });

  final _AdminUser user;
  final VoidCallback onSetActive;
  final ValueChanged<String> onSuspend;
  final VoidCallback onBan;
  final List<String> suspendOptions;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (user.status) {
      _UserStatus.active => ('Active', const Color(0xFF3FE0AE)),
      _UserStatus.suspended => (
          user.suspendedFor ?? 'Suspended',
          const Color(0xFFD97706)
        ),
      _UserStatus.banned => ('Banned', const Color(0xFFFF3B77)),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                ClipOval(
                  child: Image.asset(user.avatar,
                      width: 34, height: 34, fit: BoxFit.cover),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        user.handle,
                        style: const TextStyle(
                          color: Color(0xFFF3EFF7),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user.pronoun,
                        style: const TextStyle(
                            color: Color(0xFF635C72), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user.joined,
                style: const TextStyle(color: Color(0xFF948CA3), fontSize: 13)),
          ),
          Expanded(
            flex: 1,
            child: Text('${user.posts}',
                style: const TextStyle(color: Color(0xFF948CA3), fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${user.reports}',
              style: TextStyle(
                color: user.reports > 5 ? const Color(0xFFFF3B77) : Color(0xFF948CA3),
                fontWeight: user.reports > 5 ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: PopupMenuButton<String>(
              color: const Color(0xFF1C1824),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              onSelected: (String value) {
                if (value == 'active') {
                  onSetActive();
                } else if (value == 'ban') {
                  onBan();
                } else {
                  onSuspend(value);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'active',
                  child: Text('Active',
                      style: TextStyle(color: Color(0xFFF3EFF7), fontSize: 13)),
                ),
                const PopupMenuDivider(),
                for (final String option in suspendOptions)
                  PopupMenuItem<String>(
                    value: option,
                    child: Text(option,
                        style:
                            const TextStyle(color: Color(0xFF948CA3), fontSize: 13)),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'ban',
                  child: Text('Ban permanently',
                      style: TextStyle(
                          color: Color(0xFFFF3B77), fontSize: 13)),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1824),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('Manage',
                        style: TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 16, color: Color(0xFF948CA3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
