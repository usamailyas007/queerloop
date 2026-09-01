import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/auth_back_button.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/privacy_option_card.dart';

class AllowMessagesFromScreen extends StatelessWidget {
  const AllowMessagesFromScreen({super.key, this.initialSelection});

  final String? initialSelection;

  bool _isMatch(String opt, String selected) {
    final String o = opt.toLowerCase().trim();
    final String s = selected.toLowerCase().trim();
    if (o == s) return true;
    if (o.contains('everyone') && s.contains('everyone')) return true;
    if (o.contains('nobody') && s.contains('nobody')) return true;
    if (o.contains('mutual') && s.contains('mutual')) return true;
    if (o.contains('follow') && s.contains('follow')) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider? setupProvider =
        context.watch<ProfileSetupProvider?>();
    final String currentSelection =
        initialSelection ?? setupProvider?.allowMessagesFrom ?? 'everyone';
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<String> options = <String>[
      l10n.profileOptionEveryone,
      l10n.profileOptionPeopleYouFollow,
      l10n.profileOptionMutualFollows,
      l10n.profileOptionNobody,
    ];

    return Scaffold(
      backgroundColor: context.themeBackground,
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
                l10n.profileAllowMessageFromTitle,
                style: AppTextStyles.authHeaderTitle.copyWith(
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.profileAllowMessageFromSub,
                style: AppTextStyles.authHeaderSub.copyWith(
                  color: context.themeTextSecondary,
                ),
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
                  final bool isSelected = _isMatch(option, currentSelection);
                  final bool isRecommended =
                      option == l10n.profileOptionPeopleYouFollow;

                  return PrivacyOptionCard(
                    optionTitle: option,
                    isSelected: isSelected,
                    isRecommended: isRecommended,
                    onTap: () {
                      if (setupProvider != null) {
                        setupProvider.setAllowMessagesFrom(option);
                      }
                      Navigator.pop(context, option);
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
