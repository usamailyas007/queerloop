import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/auth_provider.dart';
import '../../home/models/post_item_model.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/services/reel_video_preloader.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../services/draft_service.dart';
import '../widgets/add_tag_bottom_sheet.dart';
import '../widgets/drafts_bottom_sheet.dart';
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
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    DraftService.init();
    _contentController = TextEditingController(); // Starts empty, no static initial text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelVideoPreloader.instance.pauseAll();
      if (!mounted) return;
      final CreatePostProvider provider = context.read<CreatePostProvider>();
      provider.setMediaType(MediaType.text);
      provider.clearSelectedMedia();
      provider.setVisibility(PostVisibility.everyone);
      final String? uid = context.read<AuthProvider>().userId;
      final ProfileProvider profile = context.read<ProfileProvider>();
      if (uid != null && uid.isNotEmpty && profile.profile == null && !profile.isBusy) {
        profile.fetchProfile(uid).catchError((_) {});
      }
    });
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

  Widget _buildAvatar(String avatar) {
    final String clean = avatar.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          AppImages.user1,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      clean.startsWith('assets/') ? clean : AppImages.user1,
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        AppImages.user1,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final bool hasContent = _contentController.text.trim().isNotEmpty;

    final String resolvedUsername = (profileProvider.profile?.username != null &&
            profileProvider.profile!.username!.trim().isNotEmpty)
        ? profileProvider.profile!.username!.trim()
        : ((authProvider.user?.displayName != null &&
                authProvider.user!.displayName!.trim().isNotEmpty)
            ? authProvider.user!.displayName!.trim()
            : profileProvider.username);

    final String displayUsername = resolvedUsername.startsWith('@')
        ? resolvedUsername.substring(1)
        : resolvedUsername;

    final String displayPronouns = (profileProvider.profile != null)
        ? profileProvider.profile!.formattedPronouns
        : profileProvider.pronounsFormatted;

    final String resolvedAvatar = (profileProvider.profile?.avatarUrl != null &&
            profileProvider.profile!.avatarUrl!.trim().isNotEmpty)
        ? profileProvider.profile!.avatarUrl!.trim()
        : ((authProvider.user?.avatarUrl != null &&
                authProvider.user!.avatarUrl!.trim().isNotEmpty)
            ? authProvider.user!.avatarUrl!.trim()
            : (profileProvider.avatarUrl.isNotEmpty
                ? profileProvider.avatarUrl
                : AppImages.user1));

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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.themeTextMuted,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xl),

                  // Title
                  Text(
                    'Write a post',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const Spacer(),

                  // Drafts Button
                  ValueListenableBuilder<int>(
                    valueListenable: DraftService.draftCountNotifier,
                    builder: (BuildContext ctx, int count, _) {
                      return GestureDetector(
                        onTap: () {
                          DraftsBottomSheet.show(context);
                        },
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: count > 0
                                  ? AppColors.gradientCyan
                                  : (context.isDarkMode
                                      ? Colors.white12
                                      : context.themeBorder),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.drafts_outlined,
                                size: 15,
                                color: count > 0
                                    ? AppColors.gradientCyan
                                    : context.themeIcon,
                              ),
                              if (count > 0) ...<Widget>[
                                const SizedBox(width: 4),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: AppColors.gradientCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Post Button -> Navigates to PostSuccessScreen
                  AppGradientButton(
                    text: 'Post',
                    isEnabled: hasContent && !provider.isPublishing,
                    isLoading: provider.isPublishing,
                    onPressed: () async {
                      final String content = _contentController.text.trim();
                      if (content.isEmpty) return;

                      provider.updateCaption(content);
                      PostResponseModel? postResult;
                      try {
                        postResult = await provider.publishPost();
                      } catch (e) {
                        debugPrint('⚠️ [WritePostScreen] publishPost error: $e');
                        if (!context.mounted) return;
                        AppSnackBar.showError(
                          context,
                          title: 'Publish Failed',
                          subtitle: e.toString().replaceFirst('Exception: ', ''),
                        );
                        return;
                      }

                      if (!context.mounted) return;

                      final HomeFeedProvider homeProvider =
                          context.read<HomeFeedProvider>();
                      final String handle = displayUsername.startsWith('@')
                          ? displayUsername
                          : '@$displayUsername';
                      final String pronounsTime = displayPronouns.trim().isNotEmpty
                          ? '${displayPronouns.trim()} · just now'
                          : 'just now';

                      final PostItemModel newPost = PostItemModel(
                        id: postResult?.id ??
                            'post_${DateTime.now().millisecondsSinceEpoch}',
                        authorId: authProvider.userId,
                        authorDisplayName: profileProvider.displayName,
                        username: handle,
                        pronounsTime: pronounsTime,
                        avatarAsset: resolvedAvatar,
                        content: content,
                        likesCount: 0,
                        commentsCount: 0,
                        postType: 'TEXT',
                      );
                      homeProvider.addNewPost(newPost);
                      try {
                        context.read<ProfileProvider>().addUserPost(newPost);
                      } catch (_) {}

                      // Refresh live feed in background
                      homeProvider.loadFeed();

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
                        child: _buildAvatar(resolvedAvatar),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            displayUsername.isNotEmpty ? displayUsername : 'user',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (displayPronouns.trim().isNotEmpty)
                            Text(
                              displayPronouns.trim(),
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
