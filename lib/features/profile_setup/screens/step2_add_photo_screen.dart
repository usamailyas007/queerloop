import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/step_progress_header.dart';

class Step2AddPhotoScreen extends StatefulWidget {
  const Step2AddPhotoScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<Step2AddPhotoScreen> createState() => _Step2AddPhotoScreenState();
}

class _Step2AddPhotoScreenState extends State<Step2AddPhotoScreen> {
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
        context.read<ProfileSetupProvider>().setProfilePhoto(image.path);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider = context.watch<ProfileSetupProvider>();
    final String? photoPath = provider.profilePhotoPath;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            children: <Widget>[
              StepProgressHeader(
                currentStep: 2,
                totalSteps: 5,
                onBack: widget.onBack,
                onSkip: widget.onNext,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.profileStep2Title,
                        style: AppTextStyles.authHeaderTitle.copyWith(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileStep2Sub,
                        style: AppTextStyles.authHeaderSub.copyWith(
                          color: context.themeTextSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Gradient Circle Avatar Preview ─────────────────────────
                      Center(
                        child: Container(
                          width: 124,
                          height: 124,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: <Color>[
                                AppColors.gradientPink,
                                AppColors.gradientCyan,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.themeBackground,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: ClipOval(
                              child: photoPath != null && photoPath.isNotEmpty
                                  ? Image.file(
                                      File(photoPath),
                                      width: 112,
                                      height: 112,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: context.isDarkMode
                                          ? const Color(0xFF2C1929)
                                          : const Color(0xFFFFEBF2),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: context.isDarkMode
                                            ? Colors.white70
                                            : AppColors.gradientPink,
                                        size: 56,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Compact Take Photo & Upload Action Buttons ────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Row(
                          children: <Widget>[
                            // Take Photo
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickImage(ImageSource.camera),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.themeCardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: context.themeBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        AppIcons.cameraSvg,
                                        width: 18,
                                        height: 18,
                                        colorFilter: ColorFilter.mode(
                                          context.themeIcon,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.profileTakePhoto,
                                        style: TextStyle(
                                          color: context.themeTextPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: AppSpacing.md),

                            // Upload
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickImage(ImageSource.gallery),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.themeCardBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: context.themeBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        AppIcons.uploadSvg,
                                        width: 18,
                                        height: 18,
                                        colorFilter: ColorFilter.mode(
                                          context.themeIcon,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.profileUpload,
                                        style: TextStyle(
                                          color: context.themeTextPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // ── Bottom Fixed Button ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AppGradientButton(
                  text: l10n.profileContinueBtn,
                  onPressed: widget.onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
