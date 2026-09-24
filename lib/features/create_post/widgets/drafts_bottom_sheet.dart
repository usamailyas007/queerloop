import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../models/create_post_models.dart';
import '../models/post_draft_model.dart';
import '../provider/create_post_provider.dart';
import '../screens/new_post_form_screen.dart';
import '../services/draft_service.dart';

class DraftsBottomSheet extends StatefulWidget {
  const DraftsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const DraftsBottomSheet(),
    );
  }

  @override
  State<DraftsBottomSheet> createState() => _DraftsBottomSheetState();
}

class _DraftsBottomSheetState extends State<DraftsBottomSheet> {
  List<PostDraft> _drafts = <PostDraft>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final List<PostDraft> list = await DraftService.getDrafts();
    if (mounted) {
      setState(() {
        _drafts = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDraft(PostDraft draft) async {
    await DraftService.deleteDraft(draft.id);
    await _loadDrafts();
    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        title: 'Draft Deleted',
        subtitle: 'The draft has been removed.',
      );
    }
  }

  void _openDraft(PostDraft draft) {
    final CreatePostProvider provider = context.read<CreatePostProvider>();
    provider.loadFromDraft(draft);
    Navigator.pop(context);

    // If we're not already on NewPostFormScreen, push it
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const NewPostFormScreen(),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final Duration diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? const Color(0xFF161822) : const Color(0xFFFFFFFF);
    final Color cardColor =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F8FA);
    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ── Drag Handle ───────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Saved Drafts',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (_drafts.isNotEmpty)
                  Text(
                    '${_drafts.length} draft${_drafts.length > 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gradientCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(color: borderColor, height: 1),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.gradientCyan,
                    ),
                  )
                : _drafts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.drafts_outlined,
                                size: 52,
                                color: context.themeIconMuted,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'No drafts saved yet',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap "Draft" when creating a post or video to save it here for later.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _drafts.length,
                        separatorBuilder: (BuildContext _, int index) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (BuildContext ctx, int index) {
                          final PostDraft draft = _drafts[index];
                          final bool hasFile = draft.mediaPath != null &&
                              File(draft.mediaPath!).existsSync();
                          final String? remoteThumb = draft.thumbnailUrl ??
                              (draft.mediaType == MediaType.photo
                                  ? draft.mediaUrl
                                  : null);
                          final bool hasRemoteThumb =
                              remoteThumb != null && remoteThumb.isNotEmpty;

                          return InkWell(
                            onTap: () => _openDraft(draft),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: <Widget>[
                                  // Media Thumbnail or Icon
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      image: hasFile &&
                                              draft.mediaType == MediaType.photo
                                          ? DecorationImage(
                                              image: FileImage(
                                                  File(draft.mediaPath!)),
                                              fit: BoxFit.cover,
                                            )
                                          : (hasRemoteThumb
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      remoteThumb),
                                                  fit: BoxFit.cover,
                                                )
                                              : null),
                                    ),
                                    child: (!hasFile && !hasRemoteThumb)
                                        ? Center(
                                            child: Icon(
                                              draft.mediaType == MediaType.video
                                                  ? Icons.videocam_rounded
                                                  : (draft.mediaType ==
                                                          MediaType.photo
                                                      ? Icons.image_rounded
                                                      : Icons.edit_note_rounded),
                                              color: AppColors.gradientCyan,
                                              size: 26,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: AppSpacing.md),

                                  // Caption & Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          draft.caption.isNotEmpty
                                              ? draft.caption
                                              : (draft.mediaType ==
                                                      MediaType.video
                                                  ? 'Untitled Video Draft'
                                                  : 'Untitled Draft'),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: <Widget>[
                                            if (draft.communityName != null) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.gradientPink
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  draft.communityName!,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.gradientPink,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              _formatDate(draft.createdAt),
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color:
                                                    context.themeTextSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Delete Draft Action
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteDraft(draft),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
