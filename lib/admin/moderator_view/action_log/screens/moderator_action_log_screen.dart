import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/provider/admin_auth_provider.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';

class ModeratorActionLogScreen extends StatefulWidget {
  const ModeratorActionLogScreen({super.key});

  @override
  State<ModeratorActionLogScreen> createState() =>
      _ModeratorActionLogScreenState();
}

class _ModeratorActionLogScreenState extends State<ModeratorActionLogScreen> {
  bool _mineOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ModReportsProvider>().loadActionLog();
      }
    });
  }

  /// Reset the filter toggle and re-pull the log.
  void _refresh() {
    setState(() => _mineOnly = false);
    context.read<ModReportsProvider>().refreshActionLog();
  }

  @override
  Widget build(BuildContext context) {
    final String? myId = context.select<AdminAuthProvider, String?>(
      (AdminAuthProvider p) => p.user?.id,
    );

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Header(
                mineOnly: _mineOnly,
                onToggle: (bool v) => setState(() => _mineOnly = v),
                onRefresh: _refresh,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.moderatorSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.moderatorBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      const _TableHeader(),
                      Expanded(
                        child: Consumer<ModReportsProvider>(
                          builder: (_, ModReportsProvider provider, _) => _Body(
                            provider: provider,
                            mineOnly: _mineOnly,
                            myId: myId,
                          ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.mineOnly,
    required this.onToggle,
    required this.onRefresh,
  });

  final bool mineOnly;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ACTION LOG',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.gradientCyan,
                letterSpacing: 1.2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Action log',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Every decision is permanent and attributed.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.moderatorSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.moderatorBorder),
          ),
          child: Row(
            children: <Widget>[
              _tab('All moderators', !mineOnly, () => onToggle(false)),
              _tab('Just me', mineOnly, () => onToggle(true)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.moderatorSurfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.moderatorBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.refresh_rounded,
                    size: 15, color: AppColors.moderatorTextMuted),
                SizedBox(width: 6),
                Text(
                  'Refresh',
                  style: TextStyle(
                    color: AppColors.moderatorTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moderatorChipSelected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.moderatorTextPrimary
                : AppColors.moderatorTextMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.moderatorDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 2, child: _H('WHEN')),
          Expanded(flex: 2, child: _H('CASE')),
          Expanded(flex: 2, child: _H('MODERATOR')),
          Expanded(flex: 2, child: _H('ACTION')),
          Expanded(flex: 2, child: _H('ACCOUNT')),
          Expanded(flex: 4, child: _H('NOTE')),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.moderatorTextFaint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.mineOnly,
    required this.myId,
  });

  final ModReportsProvider provider;
  final bool mineOnly;
  final String? myId;

  static final DateFormat _when = DateFormat('d MMM · h:mm a');

  Color _actionColor(ModReport r) {
    return switch (r.decision) {
      ModDecision.hideContent || ModDecision.ban => AppColors.danger,
      ModDecision.warn || ModDecision.mute || ModDecision.suspend =>
        AppColors.warning,
      ModDecision.escalate => AppColors.moderatorPurple,
      ModDecision.reversed => AppColors.moderatorGreen,
      ModDecision.noAction => AppColors.moderatorGray,
      null => AppColors.moderatorGray,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingActionLog && provider.actionLog.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.moderatorPink,
          ),
        ),
      );
    }
    if (provider.actionLogError != null && provider.actionLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.actionLogError!,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: provider.refreshActionLog,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.moderatorPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<ModReport> rows = mineOnly && myId != null
        ? provider.actionLog
            .where((ModReport r) => r.assignedTo == myId)
            .toList()
        : provider.actionLog;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          mineOnly ? "You haven't logged any actions yet." : 'No actions logged yet.',
          style: const TextStyle(
            color: AppColors.moderatorTextFaint,
            fontSize: 13,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.moderatorPink,
      backgroundColor: AppColors.moderatorSurface,
      onRefresh: provider.refreshActionLog,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.moderatorRowDivider),
        itemBuilder: (_, int i) {
          final ModReport r = rows[i];
          final bool mine = myId != null && r.assignedTo == myId;
          final Color c = _actionColor(r);
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    _when.format((r.resolvedAt ?? r.createdAt).toLocal()),
                    style: const TextStyle(
                      color: AppColors.moderatorTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    r.displayId,
                    style: const TextStyle(
                      color: AppColors.moderatorTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    mine
                        ? 'You'
                        : (r.assignedTo == null
                            ? '—'
                            : '#${r.assignedTo!.substring(0, 8)}'),
                    style: const TextStyle(
                      color: AppColors.moderatorTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        r.decision?.title ?? r.status.label,
                        style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    r.targetOwnerId == null
                        ? '—'
                        : '#${r.targetOwnerId!.substring(0, 8)}',
                    style: const TextStyle(
                      color: AppColors.moderatorTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    r.moderatorNote ?? '—',
                    style: const TextStyle(
                      color: AppColors.moderatorTextMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
