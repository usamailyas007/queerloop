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
import '../../../core/widgets/app_text_field.dart';
import '../../auth/auth_provider.dart';
import '../../auth/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    this.username = '',
    super.key,
  });

  final String username;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedReason = 'I no longer want to use this service';

  final List<String> _reasons = [
    'I no longer want to use this service',
    'I have a privacy concern',
    'The app is not useful for me',
    'I want to create a new account',
    'Other',
  ];

  @override
  void dispose() {
    _passwordController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text.trim().isEmpty) {
      AppSnackBar.showError(
        context,
        title: 'Password Required',
        subtitle: 'Please enter your password to confirm deletion.',
      );
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    final AccountDeletionResult? result = await auth.requestAccountDeletion(
      password: _passwordController.text.trim(),
      reason: _selectedReason,
      feedback: _feedbackController.text.trim().isEmpty
          ? null
          : _feedbackController.text.trim(),
    );

    if (!mounted) return;

    if (result != null) {
      AppSnackBar.show(
        context,
        title: 'Deletion Requested',
        subtitle: 'You have 30 days to log back in and cancel.',
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (Route<dynamic> r) => false,
      );
    } else {
      final String? err = auth.error;
      if (err != null && err.isNotEmpty) {
        AppSnackBar.showError(
          context,
          title: 'Failed',
          subtitle: err,
        );
        auth.clearError();
      }
    }
  }

  Widget _buildConsequenceCard(
    BuildContext context, {
    required Widget iconWidget,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.themeBorder,
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextPrimary,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        widget.username.startsWith('@') ? widget.username : '@${widget.username}';
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
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
                      'Delete account',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.lg),

                    // Icon badge
                    Container(
                      width: 56,
                      height: 56,
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
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gradientCyan,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Text(
                      "This can't be undone",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      "Here's exactly what happens when you confirm.",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    _buildConsequenceCard(
                      context,
                      iconWidget: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                        size: 18,
                      ),
                      text:
                          'All posts, comments and messages are erased within 30 days',
                    ),

                    _buildConsequenceCard(
                      context,
                      iconWidget: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                        size: 18,
                      ),
                      text:
                          '$cleanUsername is released and can be claimed by someone else',
                    ),

                    _buildConsequenceCard(
                      context,
                      iconWidget: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      text:
                          'Reports you filed stay with moderation, without your name',
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Reason dropdown
                    Text(
                      'Why are you leaving?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          dropdownColor: context.themeCardBackground,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.themeTextPrimary,
                            fontSize: 13,
                          ),
                          items: _reasons
                              .map(
                                (String r) => DropdownMenuItem<String>(
                                  value: r,
                                  child: Text(r),
                                ),
                              )
                              .toList(),
                          onChanged: (String? val) {
                            if (val != null) {
                              setState(() => _selectedReason = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Password confirmation
                    Text(
                      'Confirm with your password',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      isPassword: true,
                      prefixIconPath: AppIcons.password,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Optional Feedback
                    Text(
                      'Feedback (optional)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _feedbackController,
                      hintText: 'Help us improve (optional)',
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Submit button
                    Selector<AuthProvider, bool>(
                      selector: (_, AuthProvider p) => p.isBusy,
                      builder: (_, bool busy, _) => AppGradientButton(
                        text: 'Delete my account',
                        isLoading: busy,
                        onPressed: busy ? () {} : _submit,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
