import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/step_progress_header.dart';

class Step3SelectPronounsScreen extends StatefulWidget {
  const Step3SelectPronounsScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<Step3SelectPronounsScreen> createState() =>
      _Step3SelectPronounsScreenState();
}

class _Step3SelectPronounsScreenState extends State<Step3SelectPronounsScreen> {
  final TextEditingController _customPronounController =
      TextEditingController();

  @override
  void dispose() {
    _customPronounController.dispose();
    super.dispose();
  }

  void _addCustom(ProfileSetupProvider provider) {
    final String text = _customPronounController.text.trim();
    if (text.isNotEmpty) {
      provider.addCustomPronoun(text);
      _customPronounController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider = context.watch<ProfileSetupProvider>();
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
                currentStep: 3,
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
                        l10n.profileStep3Title,
                        style: AppTextStyles.authHeaderTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileStep3Sub,
                        style: AppTextStyles.authHeaderSub,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Standard Pronouns Chips Grid ───────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: provider.availablePronouns.map((pronoun) {
                          final bool isSelected = provider.selectedPronouns
                              .contains(pronoun);

                          return GestureDetector(
                            onTap: () => provider.togglePronoun(pronoun),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppColors.secondaryGradientButton
                                    : null,
                                color: isSelected
                                    ? null
                                    : const Color(0xFF1E1B26),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                pronoun,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── ADD YOUR OWN Section ──────────────────────────────────
                      const Text(
                        'ADD YOUR OWN',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // ── AppTextField with Secondary Gradient Add Button ──────
                      AppTextField(
                        controller: _customPronounController,
                        hintText: l10n.profileCustomPronounHint,
                        onSubmitted: (_) => _addCustom(provider),
                        suffixIcon: GestureDetector(
                          onTap: () => _addCustom(provider),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 8.0,
                            ),
                            child: Container(
                              width: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: AppColors.secondaryGradientButton,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.profileAdd,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Privacy Toggle Card ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    "Turn this off if you'd prefer to keep your pronouns private.",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.isPronounsPrivate
                                        ? 'Only you can see them'
                                        : 'Off means only you can see them',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            AppSwitch(
                              value: provider.isPronounsPrivate,
                              onChanged: (bool val) =>
                                  provider.togglePronounsPrivate(val),
                            ),
                          ],
                        ),
                      ),
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
