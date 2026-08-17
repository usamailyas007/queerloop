import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../widgets/identity_bottom_sheet.dart';
import '../widgets/interests_bottom_sheet.dart';
import '../widgets/pronouns_bottom_sheet.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Ash Mercado');
  final TextEditingController _usernameController =
      TextEditingController(text: '@ashinorbit');
  final TextEditingController _bioController = TextEditingController(
    text: 'Film nerd, softball catcher, chronically making playlists.',
  );

  List<String> _pronouns = <String>['she / her', 'they / them'];
  List<String> _identity = <String>['Lesbian', 'Bisexual', 'Non-binary'];
  List<String> _interests = <String>[
    'Music',
    'Gaming',
    'Fashion',
    'Fitness',
    'Travel',
    'Photography',
    'Cooking',
  ];
  final String _dateOfBirth = '14 June 1998';

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Widget _buildFieldBox({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white54,
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md - 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSelectableBox({
    required String label,
    required String valueText,
    required VoidCallback onTap,
  }) {
    return _buildFieldBox(
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pronounsDisplay = _pronouns.join(', ');
    final String identityDisplay = _identity.join(', ');
    final String interestsDisplay = '${_interests.length} selected';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Edit profile',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final ScaffoldMessengerState messenger =
                          ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      AppSnackBar.show(
                        context,
                        messenger: messenger,
                        title: 'Profile updated',
                        subtitle: 'Your profile changes have been saved',
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.gradientCyan,
                          size: 18,
                        ),
                        actionLabel: null,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradientButton,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.sm),

                  // Avatar Change Photo Section
                  Center(
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: 88,
                          height: 88,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradientButton,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppImages.user1,
                              width: 82,
                              height: 82,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Change photo',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gradientPink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 1. DISPLAY NAME
                  _buildFieldBox(
                    label: 'DISPLAY NAME',
                    child: TextField(
                      controller: _nameController,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // 2. USERNAME
                  _buildFieldBox(
                    label: 'USERNAME',
                    child: TextField(
                      controller: _usernameController,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // 3. BIO
                  _buildFieldBox(
                    label: 'BIO',
                    child: TextField(
                      controller: _bioController,
                      maxLines: 3,
                      minLines: 2,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // 4. PRONOUNS
                  _buildSelectableBox(
                    label: 'PRONOUNS',
                    valueText: pronounsDisplay,
                    onTap: () {
                      PronounsBottomSheet.show(
                        context,
                        selectedPronouns: _pronouns,
                        onSave: (List<String> updated) {
                          setState(() => _pronouns = updated);
                        },
                      );
                    },
                  ),

                  // 5. IDENTITY
                  _buildSelectableBox(
                    label: 'IDENTITY',
                    valueText: identityDisplay,
                    onTap: () {
                      IdentityBottomSheet.show(
                        context,
                        selectedIdentities: _identity,
                        onSave: (List<String> updated) {
                          setState(() => _identity = updated);
                        },
                      );
                    },
                  ),

                  // 6. INTERESTS
                  _buildSelectableBox(
                    label: 'INTERESTS',
                    valueText: interestsDisplay,
                    onTap: () {
                      InterestsBottomSheet.show(
                        context,
                        selectedInterests: _interests,
                        onSave: (List<String> updated) {
                          setState(() => _interests = updated);
                        },
                      );
                    },
                  ),

                  // 7. COMMUNITIES
                  _buildSelectableBox(
                    label: 'COMMUNITIES',
                    valueText: '3 joined',
                    onTap: () {},
                  ),

                  // 8. DATE OF BIRTH (Locked)
                  _buildFieldBox(
                    label: 'DATE OF BIRTH',
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.gradientCyan,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _dateOfBirth,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
