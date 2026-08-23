import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';

class AdminInviteModeratorScreen extends StatefulWidget {
  const AdminInviteModeratorScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<AdminInviteModeratorScreen> createState() =>
      _AdminInviteModeratorScreenState();
}

class _AdminInviteModeratorScreenState
    extends State<AdminInviteModeratorScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Set<String> _selectedCommunities = <String>{'Lesbian', 'Transgender'};

  static const List<String> _communities = <String>[
    'Lesbian',
    'Gay',
    'Bisexual',
    'Transgender',
    'Non-binary',
    'Queer',
    'General',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleCommunity(String name) {
    setState(() {
      if (_selectedCommunities.contains(name)) {
        _selectedCommunities.remove(name);
      } else {
        _selectedCommunities.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Moderators /',
                          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Invite moderator',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 40,
                      onPressed: widget.onBack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                width: 440,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.adminSurface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.adminBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Work email',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _emailController,
                      hintText: 'name@queerloop.app',
                      keyboardType: TextInputType.emailAddress,
                      fillColor: AppColors.adminSurfaceAlt,
                      prefixIcon: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.adminTextMuted, size: 20),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Password',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter password',
                      isPassword: true,
                      fillColor: AppColors.adminSurfaceAlt,
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.adminTextMuted, size: 20),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Assign communities',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final String name in _communities)
                          AppTagChip(
                            label: name,
                            isSelected: _selectedCommunities.contains(name),
                            onTap: () => _toggleCommunity(name),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Cancel',
                            onPressed: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Send invite',
                            onPressed: widget.onBack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
