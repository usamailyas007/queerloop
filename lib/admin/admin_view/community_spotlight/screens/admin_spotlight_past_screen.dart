import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../models/spotlight.dart';
import '../provider/spotlights_provider.dart';
import 'spotlight_image.dart';

class AdminSpotlightPastScreen extends StatefulWidget {
  const AdminSpotlightPastScreen({
    required this.onNew,
    required this.onEdit,
    super.key,
  });

  final VoidCallback onNew;
  final ValueChanged<Spotlight> onEdit;

  @override
  State<AdminSpotlightPastScreen> createState() =>
      _AdminSpotlightPastScreenState();
}

class _AdminSpotlightPastScreenState extends State<AdminSpotlightPastScreen> {
  void _onError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<SpotlightsProvider>().clearError();
    });
  }

  Future<void> _rerun(Spotlight s) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.adminSurfaceAlt,
            title: const Text('Re-run spotlight?',
                style: TextStyle(color: AppColors.adminTextPrimary)),
            content: Text(
              '“${s.title}” will be published again as this week\'s spotlight.',
              style: const TextStyle(color: AppColors.adminTextSecondary),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Re-run'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      await context.read<SpotlightsProvider>().rerunSpotlight(s.id);
    }
  }

  void _view(Spotlight s) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.adminSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.adminBorder),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SpotlightImage(url: s.imageUrl, height: 200, borderRadius: 0),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      s.title,
                      style: const TextStyle(
                        color: AppColors.adminTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.body,
                      style: const TextStyle(
                        color: AppColors.adminTextSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${DateFormat('d MMM yyyy').format(s.createdAt)} · '
                      '${NumberFormat.decimalPattern().format(s.views)} views · '
                      '${NumberFormat.decimalPattern().format(s.taps)} taps',
                      style: const TextStyle(
                        color: AppColors.adminTextMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        AppOutlineButton(
                          text: 'Edit',
                          width: 90,
                          height: 36,
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onEdit(s);
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (!s.live) ...<Widget>[
                          AppOutlineButton(
                            text: 'Re-run',
                            width: 90,
                            height: 36,
                            onPressed: () {
                              Navigator.pop(context);
                              _rerun(s);
                            },
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
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
                'Community spotlight /',
                style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Past spotlights',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Every weekly pick, with reach and click-through',
                          style: TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: AppTextField(
                      hintText: 'Search past spotlights',
                      prefixIconPath: AdminIcons.search,
                      fillColor: AppColors.adminSurface,
                      onChanged: (String v) =>
                          context.read<SpotlightsProvider>().setSearch(v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 130,
                    height: 44,
                    child: AppGradientButton(
                      text: 'New spotlight',
                      textStyle: const TextStyle(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: widget.onNew,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<SpotlightsProvider>(
                  builder: (_, SpotlightsProvider provider, _) {
                    if (provider.error != null &&
                        provider.spotlights.isNotEmpty) {
                      _onError(provider.error!);
                    }
                    return _Grid(
                      provider: provider,
                      onView: _view,
                      onEdit: widget.onEdit,
                      onRerun: _rerun,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.provider,
    required this.onView,
    required this.onEdit,
    required this.onRerun,
  });

  final SpotlightsProvider provider;
  final ValueChanged<Spotlight> onView;
  final ValueChanged<Spotlight> onEdit;
  final ValueChanged<Spotlight> onRerun;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.spotlights.isEmpty) {
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
    if (provider.error != null && provider.spotlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.error!,
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 120,
              child: AppOutlineButton(
                text: 'Retry',
                height: 38,
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
          'No spotlights yet.',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 13),
        ),
      );
    }

    final List<Spotlight> items = provider.spotlights;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (_, int index) {
          final Spotlight s = items[index];
          return _Card(
            spotlight: s,
            busy: provider.isRerunning(s.id),
            onView: () => onView(s),
            onEdit: () => onEdit(s),
            onRerun: () => onRerun(s),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.spotlight,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onRerun,
  });

  final Spotlight spotlight;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onRerun;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SpotlightImage(url: spotlight.imageUrl, borderRadius: 0),
                if (spotlight.live)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.adminTeal.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Live now',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  spotlight.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM').format(spotlight.createdAt)} · '
                  '${NumberFormat.compact().format(spotlight.views)} views · '
                  '${NumberFormat.compact().format(spotlight.taps)} taps',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminTextMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                busy
                    ? const SizedBox(
                        height: 26,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.adminPink,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: <Widget>[
                          Expanded(
                            child: _MiniButton(label: 'View', onTap: onView),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MiniButton(
                              label: spotlight.live ? 'Edit' : 'Re-run',
                              onTap: spotlight.live ? onEdit : onRerun,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.adminSurfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.adminBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.adminTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
