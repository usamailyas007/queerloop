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
      backgroundColor: AppColors.background,
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
                        style: AppTextStyles.authHeaderTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileStep2Sub,
                        style: AppTextStyles.authHeaderSub,
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
                            decoration: const BoxDecoration(
                              color: AppColors.background,
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
                                      color: const Color(0xFF2C1929),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        color: Colors.white70,
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
                                    color: const Color(0xFF1E1B26),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        AppIcons.cameraSvg,
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.profileTakePhoto,
                                        style: const TextStyle(
                                          color: Colors.white,
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
                                    color: const Color(0xFF1E1B26),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      SvgPicture.asset(
                                        AppIcons.uploadSvg,
                                        width: 18,
                                        height: 18,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.profileUpload,
                                        style: const TextStyle(
                                          color: Colors.white,
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

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Fixed Bottom Button ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
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
