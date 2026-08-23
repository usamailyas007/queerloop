import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';

class _SentAnnouncement {
  const _SentAnnouncement({
    required this.title,
    required this.meta,
  });

  final String title;
  final String meta;
}

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Community rules updated');
  final TextEditingController _messageController = TextEditingController(
    text:
        "Comment filters are now on by default for everyone. You can turn them off in Settings -> Privacy -> Muted words. Nothing else about your account has changed.",
  );
  int _audienceIndex = 0;

  final List<_SentAnnouncement> _sent = <_SentAnnouncement>[
    const _SentAnnouncement(
      title: 'Comment filters on by default',
      meta: '28 Jul · everyone · 74% opened',
    ),
    const _SentAnnouncement(
      title: 'Pride month safety guide',
      meta: '1 Jun · everyone · 81% opened',
    ),
    const _SentAnnouncement(
      title: 'Transgender feed is members-only',
      meta: '14 May · 1 community · 69% opened',
    ),
  ];

  static const List<String> _audiences = <String>[
    'Everyone',
    'One community',
    'Moderators',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _send() {
    if (_titleController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _sent.insert(
        0,
        _SentAnnouncement(
          title: _titleController.text.trim(),
          meta: 'Just now · ${_audiences[_audienceIndex].toLowerCase()} · 0% opened',
        ),
      );
      _titleController.clear();
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Announcements',
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sent as a push notification and pinned in the notifications list',
                style: TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
              ),

              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.adminBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Compose',
                              style: TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              controller: _titleController,
                              hintText: 'Title',
                              fillColor: AppColors.adminSurfaceAlt,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _messageController,
                              hintText: 'Message',
                              fillColor: AppColors.adminSurfaceAlt,
                              maxLines: 4,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Audience',
                              style: TextStyle(
                                  color: AppColors.adminTextSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (int i = 0; i < _audiences.length; i++)
                                  AppTagChip(
                                    label: _audiences[i],
                                    isSelected: _audienceIndex == i,
                                    onTap: () =>
                                        setState(() => _audienceIndex = i),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            AppGradientButton(text: 'Send', onPressed: _send),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.adminBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Sent',
                              style: TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _sent.length,
                                separatorBuilder: (_, _) => const SizedBox(
                                    height: AppSpacing.sm),
                                itemBuilder: (_, int index) {
                                  final _SentAnnouncement item =
                                      _sent[index];
                                  return Container(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.adminSurfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  color: AppColors.adminTextPrimary,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.meta,
                                                style: const TextStyle(
                                                  color: AppColors.adminTextMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.adminTeal
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.adminTeal
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'Sent',
                                            style: TextStyle(
                                              color: AppColors.adminTeal,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}
