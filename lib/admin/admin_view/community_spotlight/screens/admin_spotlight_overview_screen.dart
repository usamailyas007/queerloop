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

class AdminSpotlightOverviewScreen extends StatelessWidget {
  const AdminSpotlightOverviewScreen({
    required this.onOpenPast,
    required this.onNew,
    required this.onEditLive,
    super.key,
  });

  final VoidCallback onOpenPast;
  final VoidCallback onNew;
  final ValueChanged<Spotlight> onEditLive;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Community spotlight',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Admin-curated feature shown once a week in Discover',
                          style: TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(
                  //   width: 220,
                  //   child: AppTextField(
                  //     hintText: 'Search past spotlights',
                  //     prefixIconPath: AdminIcons.search,
                  //     fillColor: AppColors.adminSurface,
                  //     onChanged: (String v) =>
                  //         context.read<SpotlightsProvider>().setSearch(v),
                  //   ),
                  // ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 130,
                    child: AppOutlineButton(
                      text: 'Past spotlights',
                      height: 44,
                      backgroundColor: AppColors.adminSurfaceAlt,
                      onPressed: onOpenPast,
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
                      onPressed: onNew,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Consumer<SpotlightsProvider>(
                builder: (_, SpotlightsProvider provider, _) {
                  if (provider.isLoading && provider.spotlights.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.adminPink,
                          ),
                        ),
                      ),
                    );
                  }
                  if (provider.error != null && provider.spotlights.isEmpty) {
                    return _Notice(
                      message: provider.error!,
                      onRetry: provider.refresh,
                    );
                  }

                  final Spotlight? live = provider.liveSpotlight;
                  if (live == null) {
                    return const _Notice(
                      message:
                          'No spotlight is live — publish one to feature '
                          'a community this week.',
                    );
                  }
                  return _LivePickCard(
                    spotlight: live,
                    onEdit: () => onEditLive(live),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePickCard extends StatelessWidget {
  const _LivePickCard({required this.spotlight, required this.onEdit});

  final Spotlight spotlight;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  "This week's pick",
                  style: TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.adminTeal.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.adminTeal.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Live now',
                  style: TextStyle(
                    color: AppColors.adminTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SpotlightImage(
            url: spotlight.imageUrl,
            height: 220,
            borderRadius: 14,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            spotlight.title,
            style: const TextStyle(
              color: AppColors.adminTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            spotlight.body,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Published ${DateFormat('d MMM yyyy').format(spotlight.createdAt)} · '
            '${NumberFormat.compact().format(spotlight.views)} views · '
            '${NumberFormat.compact().format(spotlight.taps)} taps',
            style: const TextStyle(
              color: AppColors.adminTextMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 150,
              height: 42,
              child: AppOutlineButton(
                text: 'Edit spotlight',
                backgroundColor: AppColors.adminSurfaceAlt,
                onPressed: onEdit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
