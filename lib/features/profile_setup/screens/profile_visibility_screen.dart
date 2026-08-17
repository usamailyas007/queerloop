import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/auth_back_button.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/privacy_option_card.dart';

class ProfileVisibilityScreen extends StatelessWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider = context.watch<ProfileSetupProvider>();
    final String currentSelection = provider.profileVisibility;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<String> options = <String>[
      l10n.profileOptionEveryone,
      l10n.profileOptionPeopleYouFollow,
      l10n.profileOptionMutualFollows,
      l10n.profileOptionNobody,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              AuthBackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(height: AppSpacing.xl),

              Text(
                l10n.profileVisibilityTitle,
                style: AppTextStyles.authHeaderTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.profileVisibilitySub,
                style: AppTextStyles.authHeaderSub,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Options List using PrivacyOptionCard Widget ────────────
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final String option = options[index];
                  final bool isSelected = currentSelection == option;
                  final bool isRecommended =
                      option == l10n.profileOptionPeopleYouFollow;

                  return PrivacyOptionCard(
                    optionTitle: option,
                    isSelected: isSelected,
                    isRecommended: isRecommended,
                    onTap: () {
                      provider.setProfileVisibility(option);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
