import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
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

  Future<void> _handleContinue() async {
    final ProfileSetupProvider provider =
        context.read<ProfileSetupProvider>();
    final String displayName = _displayNameController.text.trim();
    final String username = _usernameController.text.trim();
    final String bio = _bioController.text.trim();

    if (displayName.isEmpty) {
      AppSnackBar.showError(
        context,
        title: 'Name Required',
        subtitle: 'Please enter your display name.',
      );
      return;
    }

    if (username.isEmpty) {
      AppSnackBar.showError(
        context,
        title: 'Username Required',
        subtitle: 'Please enter a username.',
      );
      return;
    }

    if (provider.isUsernameAvailable == false) {
      AppSnackBar.showError(
        context,
        title: 'Username Unavailable',
        subtitle: 'Username is already taken. Please choose another one.',
      );
      return;
    }

    if (provider.checkingUsername) {
      AppSnackBar.showInfo(
        context,
        title: 'Checking Availability',
        subtitle: 'Checking username availability, please wait...',
      );
      return;
    }

    provider.setDisplayName(displayName);
    provider.setUsername(username);
    provider.setBio(bio);

    final String? userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) {
      widget.onNext();
      return;
    }

    final bool ok = await provider.saveStep1(userId);
    if (ok && mounted) {
      widget.onNext();
    } else if (mounted) {
      final String? err = provider.error;
      if (err != null && err.isNotEmpty) {
        AppSnackBar.showError(
          context,
          title: 'Setup Failed',
          subtitle: err,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int bioLength = _bioController.text.length;

    return Scaffold(
      backgroundColor: context.themeBackground,
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
                        style: AppTextStyles.authHeaderTitle.copyWith(
                          color: context.themeTextPrimary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Subtitle
                      Text(
                        l10n.profileSetupStep1Sub,
                        style: AppTextStyles.authHeaderSub.copyWith(
                          color: context.themeTextSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── 1. DISPLAY NAME ───────────────────────────────────────
                      Text(
                        l10n.profileDisplayNameLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.themeTextMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppTextField(
                        controller: _displayNameController,
                        hintText: l10n.profileDisplayNameHint,
                        onChanged: (String val) {
                          context.read<ProfileSetupProvider>().setDisplayName(val);
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── 2. USERNAME ───────────────────────────────────────────
                      Text(
                        l10n.profileUsernameLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: context.themeTextMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Selector<ProfileSetupProvider, ({bool checking, bool? available})>(
                        selector: (_, ProfileSetupProvider p) =>
                            (checking: p.checkingUsername, available: p.isUsernameAvailable),
                        builder: (BuildContext context, ({bool checking, bool? available}) status, _) {
                          Widget? suffixIcon;
                          if (status.checking) {
                            suffixIcon = const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                                ),
                              ),
                            );
                          } else if (status.available == true) {
                            suffixIcon = const Icon(
                              Icons.check_rounded,
                              color: AppColors.gradientCyan,
                              size: AppSizes.iconMd,
                            );
                          } else if (status.available == false) {
                            suffixIcon = const Icon(
                              Icons.close_rounded,
                              color: AppColors.danger,
                              size: AppSizes.iconMd,
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AppTextField(
                                controller: _usernameController,
                                hintText: l10n.profileUsernameHint,
                                prefixText: '@ ',
                                suffixIcon: suffixIcon,
                                onChanged: (String val) {
                                  context.read<ProfileSetupProvider>().setUsername(val);
                                },
                              ),
                              if (status.checking) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  'Checking availability...',
                                  style: TextStyle(
                                    color: context.themeTextMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else if (status.available == true) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.profileUsernameAvailable,
                                  style: const TextStyle(
                                    color: AppColors.gradientCyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else if (status.available == false) ...<Widget>[
                                const SizedBox(height: 6),
                                const Text(
                                  'Username is already taken',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── 3. BIO (Dynamic Character Counter: BIO · 150 / 250) ───
                      Row(
                        children: <Widget>[
                          Text(
                            l10n.profileBioLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: context.themeTextMuted,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            ' · $bioLength / 250',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: context.themeTextMuted,
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
                          context.read<ProfileSetupProvider>().setBio(val);
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
