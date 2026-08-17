import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../widgets/add_tag_bottom_sheet.dart';
import '../widgets/custom_gradient_switch.dart';
import '../widgets/media_thumbnail_widget.dart';
import '../widgets/select_community_bottom_sheet.dart';
import 'post_success_screen.dart';

/// Controller that highlights hashtags (#word) in cyan color like Image 5.
class _HashtagTextEditingController extends TextEditingController {
  _HashtagTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    final List<TextSpan> children = <TextSpan>[];
    final RegExp regex = RegExp(r'(#\w+)|([^#]+)');

    for (final RegExpMatch match in regex.allMatches(text)) {
      final String token = match.group(0)!;
      if (token.startsWith('#')) {
        children.add(
          TextSpan(
            text: token,
            style: style?.copyWith(
              color: AppColors.gradientCyan,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      } else {
        children.add(
          TextSpan(text: token, style: style),
        );
      }
    }

    return TextSpan(style: style, children: children);
  }
}

class NewPostFormScreen extends StatefulWidget {
  const NewPostFormScreen({super.key});

  @override
  State<NewPostFormScreen> createState() => _NewPostFormScreenState();
}

class _NewPostFormScreenState extends State<NewPostFormScreen> {
  late final _HashtagTextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    final CreatePostProvider provider = context.read<CreatePostProvider>();
    _captionController =
        _HashtagTextEditingController(text: provider.caption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final GalleryMediaItem? selectedItem = provider.selectedMedia;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Navigation Bar (Back, Title "New post") ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  // Circular Back Button <
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      'New post',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 36), // Balance title centering
                ],
              ),
            ),

            // ── Scrollable Form Body ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  // ── Top Row: Media Thumbnail + Caption Input Box ─────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Media Thumbnail Box
                      Container(
                        width: 84,
                        height: 106,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.card - 1),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              MediaThumbnailWidget(item: selectedItem),

                              if (selectedItem?.isVideo ?? true) ...<Widget>[
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: SvgPicture.asset(
                                    AppIcons.play,
                                    width: 12,
                                    height: 12,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      selectedItem?.duration.isNotEmpty ?? false
                                          ? selectedItem!.duration
                                          : '0:38',
                                      style: AppTextStyles.caption.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: AppSpacing.md),

                      // Caption Box using AppTextField widget directly
                      Expanded(
                        child: SizedBox(
                          height: 106,
                          child: AppTextField(
                            controller: _captionController,
                            hintText: 'Write a caption...',
                            maxLines: 4,
                            maxLength: CreatePostProvider.maxCaptionLength,
                            onChanged: (String val) =>
                                provider.updateCaption(val),
                            suffixIcon: provider.tags.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      right: 10,
                                      top: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: provider.tags
                                          .take(3)
                                          .map(
                                            (String tag) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Text(
                                                tag,
                                                style: AppTextStyles.bodySmall
                                                    .copyWith(
                                                  color:
                                                      AppColors.gradientCyan,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Caption counter row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Caption',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        '${provider.captionCharCount} / ${CreatePostProvider.maxCaptionLength}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Form Option 1: Community ─────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final String? selected =
                          await SelectCommunityBottomSheet.show(
                        context,
                        currentCommunity: provider.selectedCommunity,
                      );
                      if (selected != null) {
                        provider.setSelectedCommunity(selected);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.people_outline_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Community',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Selected community pill button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryGradientButton,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              provider.selectedCommunity,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Form Option 2: Who can see this ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Who can see this',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: <Widget>[
                            _VisibilityOptionChip(
                              label: 'Everyone',
                              isSelected:
                                  provider.visibility == PostVisibility.everyone,
                              onTap: () => provider
                                  .setVisibility(PostVisibility.everyone),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _VisibilityOptionChip(
                              label: 'Followers',
                              isSelected:
                                  provider.visibility == PostVisibility.followers,
                              onTap: () => provider
                                  .setVisibility(PostVisibility.followers),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _VisibilityOptionChip(
                              label: 'Community only',
                              isSelected: provider.visibility ==
                                  PostVisibility.communityOnly,
                              onTap: () => provider
                                  .setVisibility(PostVisibility.communityOnly),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Form Option 3: Allow comments Toggle ─────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Allow comments',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Filtered for slurs automatically',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomGradientSwitch(
                          value: provider.allowComments,
                          onChanged: provider.toggleAllowComments,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Form Option 4: Allow downloads Toggle ────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Allow downloads',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Off keeps the video inside the app',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomGradientSwitch(
                          value: provider.allowDownloads,
                          onChanged: provider.toggleAllowDownloads,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Form Option 5: Tags Section ──────────────────────────
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      ...provider.tags.map(
                        (String tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                tag,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => provider.removeTag(tag),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // + Add tag chip
                      GestureDetector(
                        onTap: () {
                          AddTagBottomSheet.show(
                            context,
                            initialTags: provider.tags,
                            onTagsChanged: (List<String> newTags) {
                              provider.setTags(newTags);
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            '+ Add tag',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // ── Fixed Bottom Action Buttons: Draft & Publish ────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppOutlineButton(
                      text: 'Draft',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved to drafts'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppGradientButton(
                      text: 'Publish',
                      onPressed: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PostSuccessScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOptionChip extends StatelessWidget {
  const _VisibilityOptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradientButton : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
