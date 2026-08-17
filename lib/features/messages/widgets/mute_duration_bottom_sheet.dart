import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';

class MuteDurationBottomSheet extends StatefulWidget {
  const MuteDurationBottomSheet({
    required this.username,
    required this.onConfirmMute,
    super.key,
  });

  final String username;
  final void Function(String durationLabel) onConfirmMute;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required void Function(String durationLabel) onConfirmMute,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MuteDurationBottomSheet(
        username: username,
        onConfirmMute: onConfirmMute,
      ),
    );
  }

  @override
  State<MuteDurationBottomSheet> createState() =>
      _MuteDurationBottomSheetState();
}

class _MuteDurationBottomSheetState extends State<MuteDurationBottomSheet> {
  int _selectedDurationIndex = 1; // Default: 7 days

  bool _hidePosts = true;
  bool _hideComments = true;
  bool _hideMessages = false;

  static const List<String> _durations = <String>[
    '24 hours',
    '7 days',
    '30 days',
    'Until I undo it',
  ];

  String get _buttonText {
    switch (_selectedDurationIndex) {
      case 0:
        return 'Mute for 24 hours';
      case 1:
        return 'Mute for 7 days';
      case 2:
        return 'Mute for 30 days';
      case 3:
        return 'Mute until turned off';
      default:
        return 'Mute';
    }
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          CustomGradientSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        widget.username.startsWith('@') ? widget.username : '@${widget.username}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title Row (Mute Speaker Icon + Title "Mute @username")
              Row(
                children: <Widget>[
                  SvgPicture.asset(
                    AppIcons.mute,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white70,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Mute $cleanUsername',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                "You'll stay following each other and they can still see your posts. They won't know.",
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Section Label: MUTE FOR
              Text(
                'MUTE FOR',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Duration Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List<Widget>.generate(_durations.length, (int index) {
                    final String label = _durations[index];
                    final bool isSelected = _selectedDurationIndex == index;

                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedDurationIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gradientCyan
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gradientCyan
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF0F172A)
                                : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Section Label: WHAT TO HIDE
              Text(
                'WHAT TO HIDE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Toggles List
              _buildToggleTile(
                title: 'Posts and videos',
                value: _hidePosts,
                onChanged: (bool val) => setState(() => _hidePosts = val),
              ),
              _buildToggleTile(
                title: 'Comments on my posts',
                value: _hideComments,
                onChanged: (bool val) => setState(() => _hideComments = val),
              ),
              _buildToggleTile(
                title: 'Messages',
                value: _hideMessages,
                onChanged: (bool val) => setState(() => _hideMessages = val),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action Buttons Row (Cancel + Mute for [Duration])
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppGradientButton(
                      text: _buttonText,
                      onPressed: () {
                        final ScaffoldMessengerState messenger =
                            ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        widget.onConfirmMute(
                          _durations[_selectedDurationIndex],
                        );

                        AppSnackBar.show(
                          context,
                          messenger: messenger,
                          title: '$cleanUsername muted for ${_durations[_selectedDurationIndex]}',
                          subtitle: 'Manage anytime in Settings → Muted accounts',
                          icon: SvgPicture.asset(
                            AppIcons.mute,
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gradientCyan,
                              BlendMode.srcIn,
                            ),
                          ),
                          actionLabel: 'Undo',
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
