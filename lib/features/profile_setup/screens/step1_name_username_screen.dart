import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/step_progress_header.dart';

class Step1NameUsernameScreen extends StatefulWidget {
  const Step1NameUsernameScreen({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  State<Step1NameUsernameScreen> createState() =>
      _Step1NameUsernameScreenState();
}

class _Step1NameUsernameScreenState extends State<Step1NameUsernameScreen> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final ProfileSetupProvider provider = context.read<ProfileSetupProvider>();
    _displayNameController = TextEditingController(text: provider.displayName);
    _usernameController = TextEditingController(text: provider.username);
    _bioController = TextEditingController(text: provider.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider = context.watch<ProfileSetupProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isUsernameValid = _usernameController.text.trim().length >= 3;
    final int bioLength = _bioController.text.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            children: <Widget>[
              // Top Progress Header (Back, STEP 1 OF 5, Skip)
              StepProgressHeader(
                currentStep: 1,
                totalSteps: 5,
                onBack: () => Navigator.maybePop(context),
                onSkip: widget.onNext,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Main Title: "What should we call you?"
                      Text(
                        l10n.profileSetupStep1Title,
                        style: AppTextStyles.authHeaderTitle,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Subtitle
                      Text(
                        l10n.profileSetupStep1Sub,
                        style: AppTextStyles.authHeaderSub,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── 1. DISPLAY NAME ───────────────────────────────────────
                      Text(
                        l10n.profileDisplayNameLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _displayNameController,
                        hintText: l10n.profileDisplayNameHint,
                        onChanged: (String val) {
                          setState(() {});
                          provider.setDisplayName(val);
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── 2. USERNAME ───────────────────────────────────────────
                      Text(
                        l10n.profileUsernameLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white54,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _usernameController,
                        hintText: l10n.profileUsernameHint,
                        prefixText: '@ ',
                        suffixIcon: isUsernameValid
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.gradientCyan,
                                size: AppSizes.iconMd,
                              )
                            : null,
                        onChanged: (String val) {
                          setState(() {});
                          provider.setUsername(val);
                        },
                      ),

                      // Dynamic Status Text: "Available" in Cyan
                      if (isUsernameValid) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          l10n.profileUsernameAvailable,
                          style: const TextStyle(
                            color: AppColors.gradientCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // ── 3. BIO (Dynamic Character Counter: BIO · 150 / 250) ───
                      Row(
                        children: <Widget>[
                          Text(
                            l10n.profileBioLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            ' · $bioLength / 250',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white54,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _bioController,
                        hintText: l10n.profileBioHint,
                        maxLines: 4,
                        maxLength: 250,
                        onChanged: (String val) {
                          setState(() {});
                          provider.setBio(val);
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Fixed Bottom Button: Continue ───────────────────────────
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
