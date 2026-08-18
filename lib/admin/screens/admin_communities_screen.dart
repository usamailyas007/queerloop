import 'package:flutter/material.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import 'admin_add_community_screen.dart';

class _CommunityRow {
  const _CommunityRow({
    required this.name,
    required this.avatar,
    required this.members,
    required this.posts,
    required this.reports,
    required this.moderators,
    required this.membersOnly,
  });

  final String name;
  final String avatar;
  final String members;
  final String posts;
  final String reports;
  final String moderators;
  final bool membersOnly;
}

class AdminCommunitiesScreen extends StatefulWidget {
  const AdminCommunitiesScreen({super.key});

  @override
  State<AdminCommunitiesScreen> createState() =>
      _AdminCommunitiesScreenState();
}

class _AdminCommunitiesScreenState extends State<AdminCommunitiesScreen> {
  bool _isAdding = false;

  static const List<_CommunityRow> _communities = <_CommunityRow>[
    _CommunityRow(
      name: 'Lesbian',
      avatar: AppImages.lesbian,
      members: '184,220',
      posts: '21,004',
      reports: '38',
      moderators: 'Iris T.',
      membersOnly: false,
    ),
    _CommunityRow(
      name: 'Gay',
      avatar: AppImages.gay,
      members: '312,880',
      posts: '39,712',
      reports: '64',
      moderators: 'Ben O.',
      membersOnly: false,
    ),
    _CommunityRow(
      name: 'Bisexual',
      avatar: AppImages.bisexual,
      members: '201,455',
      posts: '18,900',
      reports: '29',
      moderators: 'Iris T.',
      membersOnly: false,
    ),
    _CommunityRow(
      name: 'Transgender',
      avatar: AppImages.transgender,
      members: '156,012',
      posts: '16,338',
      reports: '92',
      moderators: 'Priya R. · Sana K.',
      membersOnly: true,
    ),
    _CommunityRow(
      name: 'Non-binary',
      avatar: AppImages.nonBinary,
      members: '98,704',
      posts: '9,120',
      reports: '27',
      moderators: 'Priya R.',
      membersOnly: false,
    ),
    _CommunityRow(
      name: 'Queer',
      avatar: AppImages.queer,
      members: '227,331',
      posts: '24,566',
      reports: '41',
      moderators: 'Ben O.',
      membersOnly: false,
    ),
    _CommunityRow(
      name: 'Pansexual',
      avatar: AppImages.pansexual,
      members: '604,190',
      posts: '52,880',
      reports: '21',
      moderators: 'Sana K.',
      membersOnly: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return AdminAddCommunityScreen(
        onBack: () => setState(() => _isAdding = false),
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
                          'Communities',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '7 groups · assign moderators and rules per group',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: AppGradientButton(
                      text: 'Add community',
                      height: 44,
                      onPressed: () => setState(() => _isAdding = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16131D),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                          Expanded(flex: 3, child: _Header('COMMUNITY')),
                          Expanded(flex: 2, child: _Header('MEMBERS')),
                          Expanded(flex: 2, child: _Header('POSTS')),
                          Expanded(flex: 1, child: _Header('REPORTS')),
                          Expanded(flex: 2, child: _Header('MODERATORS')),
                          Expanded(flex: 2, child: _Header('VISIBILITY')),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _communities.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      itemBuilder: (_, int index) {
                        final _CommunityRow c = _communities[index];
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
                                      child: Image.asset(c.avatar,
                                          width: 34,
                                          height: 34,
                                          fit: BoxFit.cover),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(c.members,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(c.posts,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  c.reports,
                                  style: TextStyle(
                                    color: int.parse(c.reports) > 50
                                        ? const Color(0xFFD97706)
                                        : Colors.white70,
                                    fontWeight: int.parse(c.reports) > 50
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(c.moderators,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (c.membersOnly
                                              ? const Color(0xFF9333EA)
                                              : const Color(0xFF16A34A))
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: (c.membersOnly
                                                ? const Color(0xFF9333EA)
                                                : const Color(0xFF16A34A))
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      c.membersOnly ? 'Members only' : 'Public',
                                      style: TextStyle(
                                        color: c.membersOnly
                                            ? const Color(0xFF9333EA)
                                            : const Color(0xFF16A34A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
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
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
