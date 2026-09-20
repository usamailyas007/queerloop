import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../auth_provider.dart';

/// Shown when login returns ACCOUNT_PENDING_DELETION.
class AccountPendingDeletionScreen extends StatelessWidget {
  const AccountPendingDeletionScreen({
    required this.restorationToken,
    this.scheduledFor,
    super.key,
  });

  final String restorationToken;
  final String? scheduledFor;

  String _formatScheduledDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Within 30 days';
    try {
      final DateTime dt = DateTime.parse(raw).toLocal();
      final Duration remaining = dt.difference(DateTime.now());
      final int days = remaining.inDays;
      final String formattedDate =
          '${dt.day} ${_monthName(dt.month)} ${dt.year}';
      if (days > 0) {
        return '$formattedDate ($days days remaining)';
      } else if (days == 0) {
        return '$formattedDate (today)';
      }
      return formattedDate;
    } catch (_) {
      return raw;
    }
  }

  static String _monthName(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  Future<void> _cancelDeletion(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.cancelAccountDeletion(
      restorationToken: restorationToken,
    );

    if (!context.mounted) return;

    if (ok) {
      AppSnackBar.show(
        context,
        title: 'Account Restored!',
        subtitle: 'Welcome back! Your deletion request has been cancelled.',
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
    } else {
      final String? err = auth.error;
      AppSnackBar.showError(
        context,
        title: 'Restore Failed',
        subtitle: err ?? 'Could not restore account. The token may have expired.',
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final String formattedDate = _formatScheduledDate(scheduledFor);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.xxxlg),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'STATUS: PENDING DELETION',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Icon badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF003840).withValues(alpha: 0.45)
                      : const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.gradientCyan.withValues(
                      alpha: isDark ? 0.3 : 0.35,
                    ),
                    width: 1.1,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppIcons.delete,
                    width: 26,
                    height: 26,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gradientCyan,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Account scheduled\nfor deletion',
                style: AppTextStyles.titleLarge.copyWith(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Your account deletion request is currently pending. You can cancel this request and restore your account before the scheduled deletion takes effect.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Info card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF003840).withValues(alpha: 0.35)
                      : const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gradientCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.gradientCyan,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Scheduled Deletion Date',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: Color(0x2200D2C4)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.gradientCyan,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Once the date passes, all your profile data, posts, and messages will be permanently deleted and cannot be recovered.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.gradientCyan,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Selector<AuthProvider, bool>(
                selector: (_, AuthProvider p) => p.isBusy,
                builder: (_, bool busy, _) => AppGradientButton(
                  text: 'Cancel Deletion & Restore Account',
                  isLoading: busy,
                  onPressed: busy ? () {} : () => _cancelDeletion(context),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (Route<dynamic> route) => false,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: context.themeCardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.themeBorder,
                      width: 1.1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Return to Login',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
