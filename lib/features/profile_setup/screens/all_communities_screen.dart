import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/widgets/auth_back_button.dart';
import '../models/community_model.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/community_card_tile.dart';

class AllCommunitiesScreen extends StatefulWidget {
  const AllCommunitiesScreen({super.key});

  @override
  State<AllCommunitiesScreen> createState() => _AllCommunitiesScreenState();
}

class _AllCommunitiesScreenState extends State<AllCommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileSetupProvider>().fetchCommunities();
      }
    });
  }

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
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  const AuthBackButton(),
                  const SizedBox(width: AppSpacing.lg),
                  Text(
                    l10n.profileAllCommunitiesTitle,
                    style: AppTextStyles.authHeaderTitle.copyWith(
                      fontSize: 22,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // ── Search Field using AppTextField with searchSvg ────────
                      AppTextField(
                        controller: _searchController,
                        hintText: l10n.profileSearchCommunities,
                        prefixIconPath: AppIcons.searchSvg,
                        onChanged: (String val) => provider.setSearchQuery(val),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Full Community Tiles List ─────────────────────────────
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: communities.length,
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
                  text: joinedCount > 0
                      ? '${l10n.profileContinueBtn} · $joinedCount joined'
                      : l10n.profileContinueBtn,
                  onPressed: () {
                    provider.setStep(4);
                    Navigator.pop(context);
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
