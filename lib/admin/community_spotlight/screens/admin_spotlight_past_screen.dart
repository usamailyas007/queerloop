import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import 'admin_spotlight_screen.dart';

class AdminSpotlightPastScreen extends StatelessWidget {
  const AdminSpotlightPastScreen({
    required this.picks,
    required this.onOpenOverview,
    super.key,
  });

  final List<SpotlightPick> picks;
  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
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
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 120,
                      child: AppOutlineButton(
                        text: 'Past Spotlight',
                        height: 44,
                        backgroundColor: AppColors.adminSurfaceAlt,
                        onPressed: () {},
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
                        onPressed: onOpenOverview,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: picks.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (_, int index) =>
                      _SpotlightCard(pick: picks[index]),
                ),

                const SizedBox(height: AppSpacing.md),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Showing ${picks.length} of 22 past spotlights',
                      style: const TextStyle(
                        color: AppColors.adminTextMuted,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        _pageButton('Previous'),
                        const SizedBox(width: 8),
                        _pageButton('Next'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.adminSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.adminTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.pick});

  final SpotlightPick pick;

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
                Image(image: pick.coverImage, fit: BoxFit.cover),
                if (pick.isLive)
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
                  pick.headline,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pick.isLive
                      ? '${pick.weekLabel} · ${pick.views} views so far'
                      : '${pick.weekLabel} · ${pick.views} views · ${pick.taps} taps',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminTextMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    Expanded(child: _actionButton('View')),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _actionButton(pick.isLive ? 'Edit' : 'Re-run'),
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

  Widget _actionButton(String label) {
    return Container(
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
    );
  }
}
