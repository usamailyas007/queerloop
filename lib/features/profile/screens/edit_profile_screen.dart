import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
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
  String? _profilePhotoPath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _profilePhotoPath = image.path);
      }
    } catch (_) {}
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.themeBottomSheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: ctx.themeBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Change Photo',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: ctx.themeTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Camera option
                _PhotoOptionTile(
                  icon: Icons.camera_alt_rounded,
                  label: 'Take a photo',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // Gallery option
                _PhotoOptionTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from gallery',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // Cancel
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: ctx.themeCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ctx.themeBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: ctx.themeTextMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldBox({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: context.themeTextMuted,
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
            color: context.themeInputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.themeBorder,
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
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeIconMuted,
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
      backgroundColor: context.themeBackground,
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
                        color: context.themeTextMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Edit profile',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
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
                            child: _profilePhotoPath != null
                                ? Image.file(
                                    File(_profilePhotoPath!),
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    AppImages.user1,
                                    width: 82,
                                    height: 82,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        GestureDetector(
                          onTap: _showPhotoOptions,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'DISPLAY NAME',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.themeTextMuted,
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _nameController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),

                  // 2. USERNAME
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'USERNAME',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.themeTextMuted,
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _usernameController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),

                  // 3. BIO
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'BIO',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.themeTextMuted,
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _bioController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
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
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.allCommunities);
                    },
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
                            color: context.themeTextPrimary,
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

// ── Photo Option Tile ──────────────────────────────────────────────────────

class _PhotoOptionTile extends StatelessWidget {
  const _PhotoOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.themeChipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.themeIcon, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeIconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
