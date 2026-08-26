import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../widgets/add_tag_bottom_sheet.dart';
import '../widgets/who_can_see_this_bottom_sheet.dart';
import 'post_success_screen.dart';

class WritePostScreen extends StatefulWidget {
  const WritePostScreen({super.key});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(); // Starts empty, no static initial text
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _visibilityLabel(PostVisibility v) {
    switch (v) {
      case PostVisibility.everyone:
        return 'Everyone can see this';
      case PostVisibility.followers:
        return 'Followers can see this';
      case PostVisibility.communityOnly:
        return 'Community only can see this';
    }
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final bool hasContent = _contentController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Navigation Bar (Cancel, Title, Post button) ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Cancel button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextMuted,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Write a post',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Post Button -> Navigates to PostSuccessScreen
                  AppGradientButton(
                    text: 'Post',
                    onPressed: () {
                      provider.resetPostForm();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PostSuccessScreen(),
                        ),
                      );
                    },
                    height: 32,
                    width: 70,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ],
              ),
            ),

            // ── Main Pure Text Content Editor Body ──────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: <Widget>[
                  // User Header Row (Avatar + username + pronouns)
                  Row(
                    children: <Widget>[
                      ClipOval(
                        child: Image.asset(
                          AppImages.user1,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'ashinorbit',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'she/they',
                            style: AppTextStyles.caption.copyWith(
                              color: context.themeTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Pure Text Post Input Field using standard AppTextField
                  AppTextField(
                    controller: _contentController,
                    hintText: "What's on your mind..?",
                    maxLines: 6,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // ── Bottom Fixed Options Section (Tags & Visibility) ─────────────
            // Only visible when user types content into the text post field (matching Image 4!)
            if (hasContent)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Tags Row
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
                              color: context.themeCardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // + Add tag button -> opens AddTagBottomSheet
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
                              color: context.themeChipBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Text(
                              '+ Add tag',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Visibility Bar Card (opens WhoCanSeeThisBottomSheet)
                    GestureDetector(
                      onTap: () async {
                        final PostVisibility? result =
                            await WhoCanSeeThisBottomSheet.show(
                          context,
                          currentVisibility: provider.visibility,
                        );
                        if (result != null) {
                          provider.setVisibility(result);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: context.themeCardBackground,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: context.themeBorder,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.language_rounded,
                              color: context.themeIconMuted,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _visibilityLabel(provider.visibility),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.themeIconMuted,
                              size: 20,
                            ),
                          ],
                        ),
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
