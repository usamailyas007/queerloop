import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../models/community_model.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/community_card_tile.dart';
import '../widgets/step_progress_header.dart';

class Step4ChooseCommunitiesScreen extends StatefulWidget {
  const Step4ChooseCommunitiesScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<Step4ChooseCommunitiesScreen> createState() =>
      _Step4ChooseCommunitiesScreenState();
}

class _Step4ChooseCommunitiesScreenState
    extends State<Step4ChooseCommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider =
        context.watch<ProfileSetupProvider>();
    final List<CommunityModel> communities = provider.filteredCommunities;
    final int joinedCount = provider.joinedCount;
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
                currentStep: 4,
                totalSteps: 5,
                onBack: widget.onBack,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.profileStep4Title,
                        style: AppTextStyles.authHeaderTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileStep4Sub,
                        style: AppTextStyles.authHeaderSub,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Search Field using AppTextField with searchSvg ────────
                      AppTextField(
                        controller: _searchController,
                        hintText: l10n.profileSearchCommunities,
                        prefixIconPath: AppIcons.searchSvg,
                        onChanged: (String val) => provider.setSearchQuery(val),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Community Tiles ───────────────────────────────────────
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: communities.length > 7
                            ? 7
                            : communities.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final CommunityModel item = communities[index];
                          final bool isJoined =
                              provider.joinedCommunityIds.contains(item.id);

                          return CommunityCardTile(
                            community: item,
                            isSelected: isJoined,
                            onTap: () => provider.toggleCommunity(item.id),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── View All Communities Link ────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                                context, AppRoutes.allCommunities);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                l10n.profileViewAllCommunities,
                                style: const TextStyle(
                                  color: AppColors.gradientPink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.gradientPink,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                child: AppGradientButton(
                  text: joinedCount > 0
                      ? '${l10n.profileContinueBtn} · $joinedCount joined'
                      : l10n.profileContinueBtn,
                  isEnabled: joinedCount > 0,
                  onPressed: () {
                    if (joinedCount == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.profileSelectCommunityRequired),
                          backgroundColor: AppColors.gradientPink,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      return;
                    }
                    widget.onNext();
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
