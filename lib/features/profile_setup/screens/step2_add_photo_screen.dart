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
import '../../auth/auth_provider.dart';
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

  Future<void> _handleContinue() async {
    final ProfileSetupProvider provider =
        context.read<ProfileSetupProvider>();
    final String? userId = context.read<AuthProvider>().userId;
    if (userId != null &&
        userId.isNotEmpty &&
        provider.profilePhotoPath != null) {
      final String avatarUrl = provider.avatarUrl ??
          'https://picsum.photos/seed/${provider.username.isNotEmpty ? provider.username : "user"}/400';
      await provider.saveStep2(userId, avatarUrl: avatarUrl);
    }
    if (mounted) {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider =
        context.watch<ProfileSetupProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool hasPhoto = provider.profilePhotoPath != null;

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
                    children: <Widget>[
                      // ── Header Text (Centered) ─────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Avatar Display (Interactive) ───────────────────────
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            // Outer Gradient Ring or Dashed Border
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: hasPhoto
                                    ? AppColors.primaryGradientButton
                                    : null,
                                border: hasPhoto
                                    ? null
                                    : Border.all(
                                        color: context.themeBorder,
                                        width: 2,
                                      ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.themeBackground,
                                    image: hasPhoto
                                        ? DecorationImage(
                                            image: FileImage(
                                              File(provider.profilePhotoPath!),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: hasPhoto
                                      ? null
                                      : Center(
                                          child: SvgPicture.asset(
                                            AppIcons.user,
                                            width: 48,
                                            height: 48,
                                            colorFilter: ColorFilter.mode(
                                              context.themeIconMuted,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            // Small Camera Badge
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.primaryGradientButton,
                                ),
                                child: SvgPicture.asset(
                                  AppIcons.cameraSvg,
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Photo Selection Options Row (Camera & Upload) ──────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Row(
                          children: <Widget>[
                            // Camera
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
                child: Selector<ProfileSetupProvider, bool>(
                  selector: (_, ProfileSetupProvider p) => p.isBusy,
                  builder: (BuildContext context, bool isBusy, _) {
                    return AppGradientButton(
                      text: l10n.profileContinueBtn,
                      isLoading: isBusy,
                      onPressed: isBusy ? () {} : _handleContinue,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
