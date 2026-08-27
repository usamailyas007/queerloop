import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/post_item_model.dart';
import 'safety_bottom_sheet.dart';

class PostFeedCard extends StatelessWidget {
  const PostFeedCard({
    required this.post,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onOpenComments,
    super.key,
  });

  final PostItemModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onOpenComments;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.themeBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Header Row (Avatar + Handle + Pronouns/Time) ──
          GestureDetector(
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UserProfileScreen(
                    username: post.username.replaceAll('@', ''),
                    name: post.username.replaceAll('@', '').split('.').first,
                    avatarAsset: post.avatarAsset,
                  ),
                ),
              );
            },
            child: Row(
              children: <Widget>[
                ClipOval(
                  child: Image.asset(
                    post.avatarAsset,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        post.username,
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        post.pronounsTime,
                        style: TextStyle(
                          color: context.themeTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Content Body Text ─────────────────────────────────────────────
          Text(
            post.content,
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          // ── Optional Post Attached Image ──────────────────────────────────
          if (post.postImageAsset != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                post.postImageAsset!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Bottom Action Row (Like + Comment + Save + Safety Badge) ─────
          Row(
            children: <Widget>[
              // Like Action (liked-logo.png / unlike-logo.png)
              GestureDetector(
                onTap: onLikeToggle,
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      post.isLiked ? AppIcons.likedLogo : AppIcons.unlikeLogo,
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likesCount > 1000 ? '${(post.likesCount / 1000).toStringAsFixed(1)}K' : post.likesCount}',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Comment Action (Opens Comments Bottom Sheet)
              GestureDetector(
                onTap: onOpenComments,
                child: Row(
                  children: <Widget>[
                    SvgPicture.asset(
                      AppIcons.comment,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        context.themeTextSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Save Action
              GestureDetector(
                onTap: onSaveToggle,
                child: SvgPicture.asset(
                  AppIcons.save,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    post.isSaved
                        ? AppColors.gradientCyan
                        : context.themeTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const Spacer(),

              // Safety Badge Pill
              GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return SafetyBottomSheet(username: post.username);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.themeBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        AppIcons.safety,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.homeSafety,
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
