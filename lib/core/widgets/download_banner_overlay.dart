import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DownloadBannerState {
  const DownloadBannerState({
    this.progress = 0.0,
    this.percentageText = '0%',
    this.statusText = 'Downloading...',
    this.isCompleted = false,
    this.isError = false,
    this.errorMessage,
  });

  final double progress; // 0.0 to 1.0
  final String percentageText;
  final String statusText;
  final bool isCompleted;
  final bool isError;
  final String? errorMessage;
}

class DownloadBannerOverlay {
  DownloadBannerOverlay._();

  static OverlayEntry? _currentEntry;

  /// Shows a non-blocking TikTok-style floating download pill at the top of the screen.
  /// Users can continue scrolling feeds and watching reels uninterrupted.
  static ValueNotifier<DownloadBannerState> show(
    BuildContext context, {
    required bool isVideo,
  }) {
    // Remove any existing banner
    dismiss();

    final ValueNotifier<DownloadBannerState> notifier =
        ValueNotifier<DownloadBannerState>(
      DownloadBannerState(
        progress: 0.0,
        percentageText: '0%',
        statusText: 'Downloading ${isVideo ? "video" : "photo"}... 0%',
      ),
    );

    final OverlayState? overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);

    if (overlay == null) {
      return notifier;
    }

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext ctx) => _DownloadBannerWidget(
        notifier: notifier,
        isVideo: isVideo,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
    return notifier;
  }

  /// Dismisses the banner immediately if present.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _DownloadBannerWidget extends StatefulWidget {
  const _DownloadBannerWidget({
    required this.notifier,
    required this.isVideo,
  });

  final ValueNotifier<DownloadBannerState> notifier;
  final bool isVideo;

  @override
  State<_DownloadBannerWidget> createState() => _DownloadBannerWidgetState();
}

class _DownloadBannerWidgetState extends State<_DownloadBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();
    widget.notifier.addListener(_handleStateChange);
  }

  void _handleStateChange() {
    final DownloadBannerState state = widget.notifier.value;
    if (state.isCompleted || state.isError) {
      // Keep showing for 2.2 seconds then fade out and auto-remove
      Future<void>.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          _animController.reverse().then((_) {
            DownloadBannerOverlay.dismiss();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_handleStateChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final double paddingBottom = MediaQuery.of(context).padding.bottom;
    final double systemBottomInset =
        viewPaddingBottom > paddingBottom ? viewPaddingBottom : paddingBottom;
    // Position comfortably at bottom (above nav bar if present, or bottom safe area)
    final double bottomOffset =
        systemBottomInset > 0 ? (systemBottomInset + 80) : 84;

    return ValueListenableBuilder<DownloadBannerState>(
      valueListenable: widget.notifier,
      builder: (BuildContext ctx, DownloadBannerState state, _) {
        return Positioned(
          bottom: bottomOffset,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDD12131A), // Sleek deep glassmorphism
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: state.isCompleted
                                ? Colors.greenAccent.withValues(alpha: 0.6)
                                : (state.isError
                                    ? Colors.redAccent.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.16)),
                            width: 1.2,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // Left Icon / Progress Indicator
                            if (state.isCompleted) ...<Widget>[
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF103828),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.greenAccent,
                                  size: 17,
                                ),
                              ),
                            ] else if (state.isError) ...<Widget>[
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF381018),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 17,
                                ),
                              ),
                            ] else ...<Widget>[
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    CircularProgressIndicator(
                                      value: state.progress.clamp(0.02, 1.0),
                                      strokeWidth: 2.5,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppColors.gradientCyan,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: AppColors.gradientCyan,
                                      size: 11,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(width: 10),

                            // Main Title / Status Text
                            Flexible(
                              child: Text(
                                state.isCompleted
                                    ? '${widget.isVideo ? "Video" : "Photo"} saved to album'
                                    : (state.isError
                                        ? (state.errorMessage ?? 'Download failed')
                                        : 'Downloading ${widget.isVideo ? "video" : "photo"}... ${state.percentageText}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),

                            // Mini percentage indicator on the right during download
                            if (!state.isCompleted && !state.isError) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gradientCyan
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  state.percentageText,
                                  style: const TextStyle(
                                    color: AppColors.gradientCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
