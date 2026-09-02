import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/moderator.dart';
import '../provider/moderators_provider.dart';
import 'admin_invite_moderator_screen.dart';

class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({super.key});

  @override
  State<AdminModeratorsScreen> createState() => _AdminModeratorsScreenState();
}

class _AdminModeratorsScreenState extends State<AdminModeratorsScreen> {
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ModeratorsProvider>().loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInviting) {
      return AdminInviteModeratorScreen(
        onBack: () => setState(() => _isInviting = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Moderators',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Selector<ModeratorsProvider, (int, int, bool)>(
                          selector: (_, ModeratorsProvider p) =>
                              (p.activeCount, p.pendingCount, p.isLoading),
                          builder: (_, (int, int, bool) data, _) {
                            final (int active, int pending, bool loading) = data;
                            return Text(
                              loading && active == 0 && pending == 0
                                  ? 'Loading…'
                                  : '$active active'
                                      '${pending > 0 ? ' · $pending pending' : ''}',
                              style: const TextStyle(
                                color: AppColors.adminTextSecondary,
                                fontSize: 13,
                              ),
                            );
                          },
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.adminSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.adminBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      const _TableHeaderRow(),
                      Expanded(
                        child: Consumer<ModeratorsProvider>(
                          builder: (_, ModeratorsProvider provider, _) =>
                              _ModeratorsBody(provider: provider),
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

class _ModeratorsBody extends StatelessWidget {
  const _ModeratorsBody({required this.provider});

  final ModeratorsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.moderators.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.adminPink,
          ),
        ),
      );
    }

    if (provider.error != null && provider.moderators.isEmpty) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.shield_outlined,
        message: 'No moderators yet.',
      );
    }

    final List<Moderator> items = provider.moderators;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (_, int index) => _ModeratorRowTile(mod: items[index]),
      ),
    );
  }
}

class _ModeratorRowTile extends StatelessWidget {
  const _ModeratorRowTile({required this.mod});

  final Moderator mod;

  @override
  Widget build(BuildContext context) {
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
                _InitialsAvatar(seed: mod.name, faded: mod.pending),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${mod.name} · ${mod.role}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        mod.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mod.communitiesLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${mod.resolved30d}',
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mod.avgResponseHours == null
                  ? '—'
                  : '${mod.avgResponseHours!.toStringAsFixed(1)}h',
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${mod.reversed}',
              style: TextStyle(
                color: mod.reversed > 0
                    ? AppColors.adminPink
                    : AppColors.adminTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (mod.pending
                          ? AppColors.adminOrange
                          : AppColors.adminTeal)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (mod.pending
                            ? AppColors.adminOrange
                            : AppColors.adminTeal)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  mod.pending ? 'Pending' : 'Active',
                  style: TextStyle(
                    color: mod.pending
                        ? AppColors.adminOrange
                        : AppColors.adminTeal,
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
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 3, child: _Header('MODERATOR')),
          Expanded(flex: 2, child: _Header('COMMUNITIES')),
          Expanded(flex: 2, child: _Header('RESOLVED · 30D')),
          Expanded(flex: 2, child: _Header('AVG RESPONSE')),
          Expanded(flex: 1, child: _Header('REVERSED')),
          SizedBox(width: 96),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.seed, this.faded = false});

  final String seed;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final String initial =
        seed.isEmpty ? '?' : seed.characters.first.toUpperCase();
    return Opacity(
      opacity: faded ? 0.45 : 1,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.adminPurple.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border:
              Border.all(color: AppColors.adminPurple.withValues(alpha: 0.5)),
        ),
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.adminPurple,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppColors.adminTextMuted, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 120,
              child: AppOutlineButton(
                text: 'Retry',
                height: 38,
                onPressed: onRetry!,
              ),
            ),
          ],
        ],
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
        color: AppColors.adminTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
