import 'package:flutter/material.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import 'admin_invite_moderator_screen.dart';

class _ModeratorRow {
  const _ModeratorRow({
    required this.name,
    required this.modId,
    required this.email,
    required this.avatar,
    required this.communities,
    required this.resolved,
    required this.avgResponse,
    required this.reversed,
    this.pending = false,
  });

  final String name;
  final String modId;
  final String email;
  final String avatar;
  final String communities;
  final String resolved;
  final String avgResponse;
  final String reversed;
  final bool pending;
}

class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({super.key});

  @override
  State<AdminModeratorsScreen> createState() => _AdminModeratorsScreenState();
}

class _AdminModeratorsScreenState extends State<AdminModeratorsScreen> {
  bool _isInviting = false;

  static const List<_ModeratorRow> _moderators = <_ModeratorRow>[
    _ModeratorRow(
      name: 'Priya R.',
      modId: 'MOD-04',
      email: 'priya@queerloop.app',
      avatar: AppImages.user1,
      communities: 'Transgender, Non-binary',
      resolved: '412',
      avgResponse: '3.8h',
      reversed: '2',
    ),
    _ModeratorRow(
      name: 'Ben O.',
      modId: 'MOD-02',
      email: 'ben@queerloop.app',
      avatar: AppImages.user2,
      communities: 'Gay, Queer',
      resolved: '388',
      avgResponse: '5.1h',
      reversed: '1',
    ),
    _ModeratorRow(
      name: 'Sana K.',
      modId: 'MOD-01',
      email: 'sana@queerloop.app',
      avatar: AppImages.user3,
      communities: 'All communities',
      resolved: '501',
      avgResponse: '2.9h',
      reversed: '0',
    ),
    _ModeratorRow(
      name: 'Iris T.',
      modId: 'MOD-03',
      email: 'iris@queerloop.app',
      avatar: AppImages.user4,
      communities: 'Lesbian, Bisexual',
      resolved: '276',
      avgResponse: '6.4h',
      reversed: '5',
    ),
    _ModeratorRow(
      name: 'Noor A.',
      modId: 'MOD-07',
      email: 'Invitation pending',
      avatar: AppImages.user1,
      communities: 'General',
      resolved: '—',
      avgResponse: '—',
      reversed: '—',
      pending: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isInviting) {
      return AdminInviteModeratorScreen(
        onBack: () => setState(() => _isInviting = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Moderators',
                          style: TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '9 active · covering 3 time zones',
                          style: TextStyle(color: Color(0xFF948CA3), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: AppGradientButton(
                      text: 'Invite moderator',
                      height: 44,
                      onPressed: () => setState(() => _isInviting = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
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
                          Expanded(flex: 3, child: _Header('MODERATOR')),
                          Expanded(flex: 2, child: _Header('COMMUNITIES')),
                          Expanded(flex: 2, child: _Header('RESOLVED · 30D')),
                          Expanded(flex: 2, child: _Header('AVG RESPONSE')),
                          Expanded(flex: 1, child: _Header('REVERSED')),
                          SizedBox(width: 90),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _moderators.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      itemBuilder: (_, int index) {
                        final _ModeratorRow mod = _moderators[index];
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
                                    Opacity(
                                      opacity: mod.pending ? 0.4 : 1,
                                      child: ClipOval(
                                        child: Image.asset(mod.avatar,
                                            width: 34,
                                            height: 34,
                                            fit: BoxFit.cover),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            '${mod.name} · ${mod.modId}',
                                            style: const TextStyle(
                                              color: Color(0xFFF3EFF7),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            mod.email,
                                            style: const TextStyle(
                                                color: Color(0xFF635C72),
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(mod.communities,
                                    style: const TextStyle(
                                        color: Color(0xFF948CA3), fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(mod.resolved,
                                    style: const TextStyle(
                                        color: Color(0xFF948CA3), fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(mod.avgResponse,
                                    style: const TextStyle(
                                        color: Color(0xFF948CA3), fontSize: 13)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  mod.reversed,
                                  style: TextStyle(
                                    color: mod.reversed != '0' &&
                                            mod.reversed != '—'
                                        ? const Color(0xFFFF3B77)
                                        : Color(0xFF948CA3),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1824),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.12)),
                                  ),
                                  child: Text(
                                    mod.pending ? 'Resend' : 'Sent',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFF3EFF7),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

class _Header extends StatelessWidget {
  const _Header(this.label);

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
