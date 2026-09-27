import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/auth_provider.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/services/reel_video_preloader.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';
import '../models/create_post_models.dart';
import '../models/post_draft_model.dart';
import '../provider/create_post_provider.dart';
import '../services/draft_service.dart';
import '../widgets/add_tag_bottom_sheet.dart';
import '../widgets/custom_gradient_switch.dart';
import '../widgets/drafts_bottom_sheet.dart';
import '../widgets/media_processing_dialog.dart';
import '../widgets/media_thumbnail_widget.dart';
import '../widgets/select_community_bottom_sheet.dart';
import 'post_success_screen.dart';

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
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    final CreatePostProvider provider = context.read<CreatePostProvider>();
    _captionController =
        _HashtagTextEditingController(text: provider.caption);
    DraftService.init();

    // Auto-start upload if media is selected and in idle status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelVideoPreloader.instance.pauseAll();
      if (!mounted) return;
      if (provider.selectedMedia != null &&
          provider.uploadStatus == MediaUploadStatus.idle) {
        provider.startMediaUpload();
      }

      final ProfileSetupProvider setupProvider =
          context.read<ProfileSetupProvider>();
      if (setupProvider.allCommunities.isEmpty) {
        setupProvider.fetchCommunities();
      }

      if (provider.selectedCommunityId == null) {
        final ProfileProvider profile = context.read<ProfileProvider>();
        if (profile.userCommunities.isNotEmpty) {
          final CommunityModel first = profile.userCommunities.first;
          provider.setSelectedCommunity(first.name, id: first.id);
        } else if (setupProvider.allCommunities.isNotEmpty) {
          final CommunityModel first = setupProvider.allCommunities.first;
          provider.setSelectedCommunity(first.name, id: first.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _publishPost(
      BuildContext context, CreatePostProvider provider) async {
    // 1. Client-side gating: ensure media is ready
    if (provider.selectedMedia != null && !provider.isMediaReady) {
      final bool isVideo = provider.selectedMedia!.isVideo;
      final bool success = await MediaProcessingDialog.show(
        context,
        isVideo: isVideo,
      );
      if (!success || !context.mounted) {
        return;
      }
    }

    // 2. Video 60-second limit check
    if (provider.selectedMedia != null &&
        provider.selectedMedia!.isVideo &&
        !provider.isDurationWithinLimit) {
      AppSnackBar.showError(
        context,
        title: 'Video Too Long',
        subtitle:
            'Video limit is 60 seconds for testing. Please adjust trimming.',
      );
      return;
    }

    try {
      final PostResponseModel? postResult = await provider.publishPost();

      if (!context.mounted) return;

      final HomeFeedProvider homeProvider = context.read<HomeFeedProvider>();
      final GalleryMediaItem? item = provider.selectedMedia;
      final bool isVideo = provider.mediaType == MediaType.video &&
          (item == null || item.isVideo);

      final ProfileProvider profile = context.read<ProfileProvider>();
      final AuthProvider auth = context.read<AuthProvider>();

      final String resolvedUsername = (profile.profile?.username != null &&
              profile.profile!.username!.trim().isNotEmpty)
          ? profile.profile!.username!.trim()
          : ((auth.user?.displayName != null &&
                  auth.user!.displayName!.trim().isNotEmpty)
              ? auth.user!.displayName!.trim()
              : (profile.username.isNotEmpty ? profile.username : 'you'));
      final String handle = resolvedUsername.startsWith('@')
          ? resolvedUsername
          : '@$resolvedUsername';

      final String pronouns = (profile.profile != null)
          ? profile.profile!.formattedPronouns
          : profile.pronounsFormatted;
      final String pronounsTime = pronouns.isNotEmpty ? '$pronouns · just now' : 'just now';

      final String avatar = (profile.profile?.avatarUrl != null &&
              profile.profile!.avatarUrl!.trim().isNotEmpty)
          ? profile.profile!.avatarUrl!.trim()
          : ((auth.user?.avatarUrl != null &&
                  auth.user!.avatarUrl!.trim().isNotEmpty)
              ? auth.user!.avatarUrl!.trim()
              : (profile.avatarUrl.isNotEmpty ? profile.avatarUrl : AppImages.user1));

      if (isVideo) {
        final ReelItemModel newReel = ReelItemModel(
          id: postResult?.id ?? 'reel_${DateTime.now().millisecondsSinceEpoch}',
          username: handle,
          pronounsTime: pronounsTime,
          avatarAsset: avatar,
          videoAsset: item?.videoAsset ?? '',
          videoFilePath: item?.filePath,
          videoUrl: provider.uploadResult?.downloadUrl ?? provider.uploadResult?.url,
          thumbnailUrl: provider.uploadResult?.thumbnailUrl ??
              (provider.uploadedMediaId != null && provider.uploadedMediaId!.isNotEmpty
                  ? '${AppConfig.cdnUrl}/videos/processed/${provider.uploadedMediaId}/thumb.0000000.jpg'
                  : null),
          caption: provider.caption,
          likesCount: 0,
          commentsCount: 0,
          tags: provider.tags.isNotEmpty
              ? provider.tags
              : <String>[provider.selectedCommunity],
          durationText:
              '0:${provider.selectedDurationSeconds.toString().padLeft(2, '0')}',
          allowDownloads: provider.allowDownloads,
        );
        homeProvider.addNewReel(newReel);
        try {
          context.read<ProfileProvider>().addUserReel(newReel);
        } catch (_) {}
      } else {
        final String? localPath = (item != null && item.filePath != null && item.filePath!.isNotEmpty)
            ? item.filePath
            : null;
        final PostItemModel newPost = PostItemModel(
          id: postResult?.id ?? 'post_${DateTime.now().millisecondsSinceEpoch}',
          authorId: auth.userId,
          authorDisplayName: profile.displayName,
          username: handle,
          pronounsTime: pronounsTime,
          avatarAsset: avatar,
          content: provider.caption,
          likesCount: 0,
          commentsCount: 0,
          postImageAsset: localPath,
          postImageUrl: provider.uploadResult?.downloadUrl ??
              provider.uploadResult?.url ??
              localPath,
          postType: provider.mediaType == MediaType.text ? 'TEXT' : 'PHOTO',
          allowDownloads: provider.allowDownloads,
        );
        homeProvider.addNewPost(newPost);
        try {
          context.read<ProfileProvider>().addUserPost(newPost);
        } catch (_) {}
      }

      // If this post was loaded from a draft, delete the draft
      if (provider.currentDraftId != null) {
        await DraftService.deleteDraft(provider.currentDraftId!);
      }

      // Refresh live feed in background
      homeProvider.loadFeed();

      provider.resetPostForm();

      if (!context.mounted) return;
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const PostSuccessScreen(),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        title: 'Publish Failed',
        subtitle: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final GalleryMediaItem? selectedItem = provider.selectedMedia;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
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
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.themeIcon,
                        size: 24,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      'New post',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  ValueListenableBuilder<int>(
                    valueListenable: DraftService.draftCountNotifier,
                    builder: (BuildContext ctx, int count, _) {
                      return GestureDetector(
                        onTap: () => DraftsBottomSheet.show(context),
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(18),
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
                                size: 16,
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
                            color: context.themeBorder,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.card - 1),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              MediaThumbnailWidget(item: selectedItem),

                              if (provider.mediaType == MediaType.video &&
                                  (selectedItem?.isVideo ?? true)) ...<Widget>[
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
                                      '${provider.selectedDurationSeconds}s',
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
                          color: context.themeTextMuted,
                        ),
                      ),
                      Text(
                        '${provider.captionCharCount} / ${CreatePostProvider.maxCaptionLength}',
                        style: AppTextStyles.caption.copyWith(
                          color: context.themeTextMuted,
                        ),
                      ),
                    ],
                  ),

                   const SizedBox(height: AppSpacing.lg),

                  // ── Form Option 1: Community ─────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      final CommunityModel? selected =
                          await SelectCommunityBottomSheet.show(
                        context,
                        currentCommunity: provider.selectedCommunity,
                        currentCommunityId: provider.selectedCommunityId,
                      );
                      if (selected != null) {
                        provider.setSelectedCommunity(
                          selected.name,
                          id: selected.id,
                        );
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
                            Icons.people_outline_rounded,
                            color: context.themeIconMuted,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Community',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: context.themeTextPrimary,
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
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.themeIconMuted,
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
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: context.themeBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.visibility_outlined,
                              color: context.themeIconMuted,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Who can see this',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: context.themeTextPrimary,
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
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: context.themeBorder,
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
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Filtered for slurs automatically',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextMuted,
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
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: context.themeBorder,
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
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Off keeps the video inside the app',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextMuted,
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
                            color: context.themeCardBackground,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: context.themeBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                tag,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => provider.removeTag(tag),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: context.themeIconMuted,
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
                      onPressed: () async {
                        final PostDraft draft = provider.toDraft(
                          caption: _captionController.text.trim(),
                        );
                        await DraftService.saveDraft(draft);
                        if (!context.mounted) return;
                        AppSnackBar.showSuccess(
                          context,
                          title: 'Draft Saved',
                          subtitle: 'Your post has been saved to drafts.',
                        );
                        Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppGradientButton(
                      text: provider.isPublishing
                          ? 'Publishing...'
                          : (provider.uploadStatus == MediaUploadStatus.transcoding
                              ? 'Transcoding...'
                              : (provider.uploadStatus == MediaUploadStatus.uploading ||
                                      provider.uploadStatus == MediaUploadStatus.requestingUrl
                                  ? 'Uploading...'
                                  : 'Upload')),
                      isEnabled: provider.canPublish,
                      isLoading: provider.isPublishing,
                      onPressed: () => _publishPost(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          color: isSelected ? null : context.themeChipBackground,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isSelected
              ? null
              : Border.all(color: context.themeBorder),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : context.themeTextSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

