import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';

class DeleteReelBottomSheet extends StatefulWidget {
  const DeleteReelBottomSheet({
    required this.reel,
    super.key,
  });

  final ReelItemModel reel;

  static Future<bool?> show(
    BuildContext context, {
    required ReelItemModel reel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeleteReelBottomSheet(reel: reel),
    );
  }

  @override
  State<DeleteReelBottomSheet> createState() => _DeleteReelBottomSheetState();
}

class _DeleteReelBottomSheetState extends State<DeleteReelBottomSheet> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      final ProfileProvider profile = context.read<ProfileProvider>();
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();

      final bool ok1 = await profile.deletePost(widget.reel.id);
      final bool ok2 = await homeFeed.deletePost(widget.reel.id);

      if (!mounted) return;

      Navigator.pop(context, true);

      if (ok1 || ok2) {
        AppSnackBar.showSuccess(
          context,
          title: 'Reel Deleted',
          subtitle: 'Your video was successfully removed.',
        );
      } else {
        AppSnackBar.show(
          context,
          title: 'Error',
          subtitle: 'Failed to delete video. Please try again.',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        AppSnackBar.show(
          context,
          title: 'Error',
          subtitle: 'Something went wrong: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // ── Drag Handle Bar ──────────────────────────────────────────────
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: context.themeBorderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Trash Icon with Red Tint Background ──────────────────────────
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 30,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              'Delete Video',
              style: TextStyle(
                color: context.themeTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            // ── Subtitle ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Are you sure you want to delete this reel? It will be permanently removed from your profile and feed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Delete Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _handleDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.delete_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete Reel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Cancel Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: context.themeTextSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: context.themeTextSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
