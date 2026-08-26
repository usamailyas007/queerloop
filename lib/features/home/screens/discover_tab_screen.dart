import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../screens/hashtag_posts_screen.dart';
import '../widgets/guest_action_modal_dialog.dart';

class DiscoverTabScreen extends StatelessWidget {
  const DiscoverTabScreen({this.isGuest = false, super.key});

  final bool isGuest;

  void _handleTrendingTap(
    BuildContext context, {
    required String hashtag,
    required String postsCount,
    required Color rankColor,
  }) {
    if (isGuest) {
      GuestActionModalDialog.show(
        context,
        title: 'Sign up to explore trending posts',
        subtitle:
            'Create a free account to view full trending discussions, interact, and save posts. Browsing stays free forever.',
        iconData: Icons.tag_rounded,
      );
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HashtagPostsScreen(
          hashtag: hashtag,
          postsCount: postsCount,
          rankColor: rankColor,
        ),
      ),
    );
  }

  void _handleCommunityTap(BuildContext context, String communityName) {
    if (isGuest) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      GuestActionModalDialog.show(
        context,
        title: l10n.guestSignUpBrowseCommunityTitle,
        subtitle: l10n.guestSignUpBrowseCommunitySub,
        iconData: Icons.chat_bubble_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),

            // Title: "Discover"
            Text(
              l10n.guestDiscoverTitle,
              style: AppTextStyles.headingMedium.copyWith(
                color: context.themeTextPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Reusable TextField Widget: AppTextField
            GestureDetector(
              onTap: isGuest
                  ? () {
                      GuestActionModalDialog.show(
                        context,
                        title: 'Sign up to search QueerLoop+',
                        subtitle:
                            'Create a free account to search creators, tags, and communities.',
                        iconData: Icons.search_rounded,
                      );
                    }
                  : null,
              child: AbsorbPointer(
                absorbing: isGuest,
                child: AppTextField(
                  hintText: l10n.guestDiscoverSearchHint,
                  prefixIconPath: AppIcons.search,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Subheader: TRENDING NOW + Worldwide
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  l10n.guestTrendingNow,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.themeTextMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  l10n.guestWorldwide,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // 01. #chosenfamily Card
            _TrendingItemCard(
              rank: '01',
              rankColor: AppColors.gradientPink,
              hashtag: '#chosenfamily',
              postsCount: '28.4K posts today',
              thumbnailAsset: AppImages.forYouImg,
              onTap: () => _handleTrendingTap(
                context,
                hashtag: '#chosenfamily',
                postsCount: '28.4K posts today',
                rankColor: AppColors.gradientPink,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // 02. #prideprep2026 Card
            _TrendingItemCard(
              rank: '02',
              rankColor: AppColors.gradientPurple,
              hashtag: '#prideprep2026',
              postsCount: '19.7K posts today',
              thumbnailAsset: AppImages.followingImg,
              onTap: () => _handleTrendingTap(
                context,
                hashtag: '#prideprep2026',
                postsCount: '19.7K posts today',
                rankColor: AppColors.gradientPurple,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // 03. #binderfitcheck Card
            _TrendingItemCard(
              rank: '03',
              rankColor: AppColors.gradientCyan,
              hashtag: '#binderfitcheck',
              postsCount: '11.2K posts today',
              thumbnailAsset: AppImages.communityImg,
              onTap: () => _handleTrendingTap(
                context,
                hashtag: '#binderfitcheck',
                postsCount: '11.2K posts today',
                rankColor: AppColors.gradientCyan,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // 04. #queerbooktok Card
            _TrendingItemCard(
              rank: '04',
              rankColor: AppColors.gradientPurple,
              hashtag: '#queerbooktok',
              postsCount: '8.9K posts today',
              thumbnailAsset: AppImages.forYouImg,
              onTap: () => _handleTrendingTap(
                context,
                hashtag: '#queerbooktok',
                postsCount: '8.9K posts today',
                rankColor: AppColors.gradientPurple,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Subheader: BROWSE COMMUNITIES
            Text(
              l10n.guestBrowseCommunities,
              style: AppTextStyles.labelSmall.copyWith(
                color: context.themeTextMuted,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Grid of Communities (Transgender, Queer, etc.)
            Row(
              children: <Widget>[
                Expanded(
                  child: _CommunityCard(
                    title: 'Transgender',
                    imageAsset: AppImages.transgender,
                    isGuest: isGuest,
                    onTap: () => _handleCommunityTap(context, 'Transgender'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _CommunityCard(
                    title: 'Queer',
                    imageAsset: AppImages.queer,
                    isGuest: isGuest,
                    onTap: () => _handleCommunityTap(context, 'Queer'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxxxxl),
          ],
        ),
      ),
    );
  }
}

class _TrendingItemCard extends StatelessWidget {
  const _TrendingItemCard({
    required this.rank,
    required this.rankColor,
    required this.hashtag,
    required this.postsCount,
    required this.thumbnailAsset,
    required this.onTap,
  });

  final String rank;
  final Color rankColor;
  final String hashtag;
  final String postsCount;
  final String thumbnailAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: <Widget>[
            Text(
              rank,
              style: AppTextStyles.titleMedium.copyWith(
                color: rankColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hashtag,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    postsCount,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                thumbnailAsset,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.title,
    required this.imageAsset,
    required this.isGuest,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final bool isGuest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.themeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ClipOval(
                  child: Image.asset(
                    imageAsset,
                    width: AppSizes.avatarSizeSm,
                    height: AppSizes.avatarSizeSm,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isGuest)
                  Icon(
                    Icons.lock_outline_rounded,
                    color: context.themeIconMuted,
                    size: AppSizes.iconSm,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
