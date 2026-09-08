import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';

class MediaProcessingDialog extends StatefulWidget {
  const MediaProcessingDialog({
    required this.isVideo,
    super.key,
  });

  final bool isVideo;

  static Future<bool> show(
    BuildContext context, {
    required bool isVideo,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (BuildContext ctx) => MediaProcessingDialog(isVideo: isVideo),
    );
    return result ?? false;
  }

  @override
  State<MediaProcessingDialog> createState() => _MediaProcessingDialogState();
}

class _MediaProcessingDialogState extends State<MediaProcessingDialog> {
  bool _hasFailed = false;
  bool _isNavigating = false;
  CreatePostProvider? _provider;
  DateTime? _openedAt;

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider = context.read<CreatePostProvider>();
      _provider?.addListener(_onStatusChanged);
      _checkOrStart();
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_onStatusChanged);
    if (_provider != null &&
        _provider!.uploadStatus != MediaUploadStatus.ready) {
      _provider!.cancelMediaUpload();
    }
    super.dispose();
  }

  void _onStatusChanged() {
    if (!mounted || _provider == null || _isNavigating) return;
    final MediaUploadStatus status = _provider!.uploadStatus;
    if (status == MediaUploadStatus.ready) {
      _completeAndClose();
    } else if (status == MediaUploadStatus.failed) {
      if (!_hasFailed) {
        setState(() {
          _hasFailed = true;
        });
      }
    }
  }

  Future<void> _completeAndClose() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Guarantee the processing dialog is visible for at least 1400ms
    // so the user clearly sees "Processing this image/video..." before moving forward
    if (_openedAt != null) {
      final int elapsed =
          DateTime.now().difference(_openedAt!).inMilliseconds;
      final int remaining = 1400 - elapsed;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _cancelAndClose() {
    _provider?.cancelMediaUpload();
    Navigator.pop(context, false);
  }

  void _checkOrStart() {
    if (_provider == null || _isNavigating) return;
    if (_provider!.uploadStatus == MediaUploadStatus.ready) {
      _completeAndClose();
      return;
    }

    if (_provider!.uploadStatus == MediaUploadStatus.idle ||
        _provider!.uploadStatus == MediaUploadStatus.failed) {
      setState(() {
        _hasFailed = false;
      });
      _provider!.startMediaUpload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final String title = widget.isVideo
        ? 'Processing this video...'
        : 'Processing this image...';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          if (_provider != null &&
              _provider!.uploadStatus != MediaUploadStatus.ready) {
            _provider!.cancelMediaUpload();
          }
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.themeBorder,
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Top close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _cancelAndClose,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: context.themeIconMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (_hasFailed) ...<Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.danger,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Processing Failed',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      provider.uploadError ?? 'Could not upload media. Please try again.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: context.themeTextMuted,
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: _cancelAndClose,
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: context.themeTextMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Retry',
                            height: 40,
                            onPressed: _checkOrStart,
                          ),
                        ),
                      ],
                    ),
                  ] else ...<Widget>[
                    // Glowing Circular Progress Indicator
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            AppColors.gradientPink.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: AppColors.gradientPink,
                            strokeWidth: 3.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Main Text requested by User
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        decoration: TextDecoration.none,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      'Please wait a moment...',
                      style: AppTextStyles.caption.copyWith(
                        color: context.themeTextMuted,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
