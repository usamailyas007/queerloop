import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/community.dart';
import '../provider/communities_provider.dart';
import 'admin_add_community_screen.dart';

class AdminCommunitiesScreen extends StatefulWidget {
  const AdminCommunitiesScreen({super.key});

  @override
  State<AdminCommunitiesScreen> createState() => _AdminCommunitiesScreenState();
}

class _AdminCommunitiesScreenState extends State<AdminCommunitiesScreen> {
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunitiesProvider>().loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return AdminAddCommunityScreen(
        onBack: () => setState(() => _isAdding = false),
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
                          'Communities',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Selector<CommunitiesProvider, (int, bool)>(
                          selector: (_, CommunitiesProvider p) =>
                              (p.count, p.isLoading),
                          builder: (_, (int, bool) data, _) {
                            final (int count, bool loading) = data;
                            return Text(
                              loading && count == 0
                                  ? 'Loading…'
                                  : '$count group${count == 1 ? '' : 's'} · '
                                      'each becomes a tab in the app',
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
                        child: Consumer<CommunitiesProvider>(
                          builder: (_, CommunitiesProvider provider, _) =>
                              _CommunitiesBody(provider: provider),
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

class _CommunitiesBody extends StatelessWidget {
  const _CommunitiesBody({required this.provider});

  final CommunitiesProvider provider;

  static final NumberFormat _count = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.communities.isEmpty) {
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

    if (provider.error != null && provider.communities.isEmpty) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.groups_2_outlined,
        message: 'No communities yet — add your first one.',
      );
    }

    final List<Community> items = provider.communities;
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
        itemBuilder: (_, int index) {
          final Community c = items[index];
          final bool isPrivate = c.visibility == CommunityVisibility.private;
          final Color chip =
              isPrivate ? AppColors.adminPurple : AppColors.adminTeal;
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
                      _CommunityAvatar(imageUrl: c.imageUrl, name: c.name),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              c.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.adminTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              c.slug,
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
                    _count.format(c.memberCount),
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _count.format(c.postCount),
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    _count.format(c.reportCount),
                    style: TextStyle(
                      color: c.reportCount > 50
                          ? AppColors.adminOrange
                          : AppColors.adminTextSecondary,
                      fontWeight: c.reportCount > 50
                          ? FontWeight.w700
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    c.moderatorsLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
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
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: chip.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: chip.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        c.visibility.label,
                        style: TextStyle(
                          color: chip,
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
          Expanded(flex: 3, child: _Header('COMMUNITY')),
          Expanded(flex: 2, child: _Header('MEMBERS')),
          Expanded(flex: 2, child: _Header('POSTS')),
          Expanded(flex: 1, child: _Header('REPORTS')),
          Expanded(flex: 2, child: _Header('MODERATORS')),
          Expanded(flex: 2, child: _Header('VISIBILITY')),
        ],
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({required this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    const double size = 34;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final String initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.adminPink.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.adminPink.withValues(alpha: 0.5)),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.adminPink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
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
