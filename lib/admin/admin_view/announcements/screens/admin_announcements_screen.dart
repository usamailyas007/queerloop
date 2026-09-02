import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../communities/models/community.dart';
import '../../communities/provider/communities_provider.dart';
import '../models/announcement.dart';
import '../provider/announcements_provider.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  AnnouncementAudience _audience = AnnouncementAudience.everyone;
  String? _communityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AnnouncementsProvider>().loadInitial();
      context.read<CommunitiesProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String title = _titleController.text.trim();
    final String body = _messageController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _snack('Title and message are required.');
      return;
    }
    if (_audience == AnnouncementAudience.community && _communityId == null) {
      _snack('Pick a community for this announcement.');
      return;
    }

    final AnnouncementsProvider provider = context
        .read<AnnouncementsProvider>();
    final Announcement? created = await provider.createAnnouncement(
      title: title,
      body: body,
      audience: _audience,
      communityId: _communityId,
    );

    if (!mounted) {
      return;
    }
    if (created != null) {
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _audience = AnnouncementAudience.everyone;
        _communityId = null;
      });
      _snack('Announcement published.');
    } else {
      _snack(provider.error ?? 'Could not publish the announcement.');
      provider.clearError();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                style: TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(flex: 3, child: _composeCard()),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: _sentCard()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composeCard() {
    final bool sending = context.select<AnnouncementsProvider, bool>(
      (AnnouncementsProvider p) => p.isSending,
    );

    return _Card(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _CardTitle('Compose'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _titleController,
              enabled: !sending,
              hintText: 'Title',
              fillColor: AppColors.adminSurfaceAlt,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _messageController,
              enabled: !sending,
              hintText: 'Message',
              fillColor: AppColors.adminSurfaceAlt,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FieldLabel('Audience'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final AnnouncementAudience a
                    in AnnouncementAudience.values)
                  AppTagChip(
                    label: a.label,
                    isSelected: _audience == a,
                    onTap: sending
                        ? null
                        : () => setState(() {
                            _audience = a;
                            if (a != AnnouncementAudience.community) {
                              _communityId = null;
                            }
                          }),
                  ),
              ],
            ),
            if (_audience == AnnouncementAudience.community) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('Community'),
              _CommunityPicker(
                selectedId: _communityId,
                onSelect: (String id) => setState(() => _communityId = id),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            AppGradientButton(
              text: 'Send',
              isLoading: sending,
              onPressed: sending ? () {} : _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _CardTitle('Sent'),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Consumer<AnnouncementsProvider>(
              builder: (_, AnnouncementsProvider provider, _) =>
                  _SentList(provider: provider),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sent list ───────────────────────────────────────────────────────────────

class _SentList extends StatelessWidget {
  const _SentList({required this.provider});

  final AnnouncementsProvider provider;

  static final DateFormat _dateFormat = DateFormat('d MMM · h:mm a');

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.announcements.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.adminPink,
          ),
        ),
      );
    }

    if (provider.error != null && provider.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: 110,
              child: AppOutlineButton(
                text: 'Retry',
                height: 36,
                onPressed: provider.refresh,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.isEmpty) {
      return const Center(
        child: Text(
          'Nothing published yet.',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
        ),
      );
    }

    final List<Announcement> items = provider.pageItems;
    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            color: AppColors.adminPink,
            backgroundColor: AppColors.adminSurface,
            onRefresh: provider.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, int index) {
                final Announcement a = items[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.adminSurfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              a.title,
                              style: const TextStyle(
                                color: AppColors.adminTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _Badge(text: 'Sent', color: AppColors.adminTeal),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${a.audience.label} · ${_dateFormat.format(a.publishedAt.toLocal())}',
                        style: const TextStyle(
                          color: AppColors.adminTextMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (a.body.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          a.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _AnnouncementsPager(provider: provider),
      ],
    );
  }
}

// ── Client-side pager: Back · 1 2 3 · Next ─────────────────────────────────

class _AnnouncementsPager extends StatelessWidget {
  const _AnnouncementsPager({required this.provider});

  final AnnouncementsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.pageCount <= 1) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.adminDivider)),
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              'Showing ${provider.rangeStart}–${provider.rangeEnd} of ${provider.total}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.adminTextMuted,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
          _PagerChip(
            label: 'Back',
            enabled: provider.canPrev,
            onTap: provider.prevPage,
          ),
          for (int p = 1; p <= provider.pageCount; p++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _PagerChip(
                label: '$p',
                selected: p == provider.page,
                onTap: () => provider.goToPage(p),
              ),
            ),
          _PagerChip(
            label: 'Next',
            enabled: provider.canNext,
            onTap: provider.nextPage,
          ),
        ],
      ),
    );
  }
}

class _PagerChip extends StatelessWidget {
  const _PagerChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && !selected;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected
            ? AppColors.moderatorChipSelected
            : AppColors.adminSurfaceAlt,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: interactive ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.adminButtonBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.adminTextPrimary
                    : AppColors.adminTextSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Community single-select ─────────────────────────────────────────────────

class _CommunityPicker extends StatelessWidget {
  const _CommunityPicker({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (_, CommunitiesProvider provider, _) {
        if (provider.isLoading && provider.communities.isEmpty) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.adminPink,
            ),
          );
        }
        if (provider.communities.isEmpty) {
          return const Text(
            'No communities available.',
            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Community c in provider.communities)
              AppTagChip(
                label: c.name,
                isSelected: selectedId == c.id,
                onTap: () => onSelect(c.id),
              ),
          ],
        );
      },
    );
  }
}

// ── Small building blocks ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.adminTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.adminTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
