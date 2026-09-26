import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchQuery = '';
    _searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileSetupProvider>().setSearchQuery('');
        context.read<ProfileSetupProvider>().fetchCommunities();
      }
    });
  }

  @override
  void deactivate() {
    context.read<ProfileSetupProvider>().setSearchQuery('');
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final ProfileSetupProvider provider =
        context.read<ProfileSetupProvider>();
    if (provider.joinedCount < 1) {
      AppSnackBar.showError(
        context,
        title: 'Community Required',
        subtitle: 'At least 1 community must remain selected.',
      );
      return;
    }

    final bool ok = await provider.saveStep4();
    if (ok && mounted) {
      widget.onNext();
    } else if (mounted) {
      final String? err = provider.error;
      if (err != null && err.isNotEmpty) {
        AppSnackBar.showError(
          context,
          title: 'Join Failed',
          subtitle: err,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider =
        context.watch<ProfileSetupProvider>();
    final String query = _searchQuery.trim().toLowerCase();
    final List<CommunityModel> communities = query.isEmpty
        ? provider.allCommunities
        : provider.allCommunities
            .where((CommunityModel c) =>
                c.name.toLowerCase().contains(query))
            .toList();
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
                currentStep: 4,
                totalSteps: 5,
                onBack: widget.onBack,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.profileStep4Title,
                        style: AppTextStyles.authHeaderTitle.copyWith(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileStep4Sub,
                        style: AppTextStyles.authHeaderSub.copyWith(
                          color: context.themeTextSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Search Field using AppTextField with searchSvg ────────
                      AppTextField(
                        controller: _searchController,
                        hintText: l10n.profileSearchCommunities,
                        prefixIconPath: AppIcons.searchSvg,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: context.themeIconMuted,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                  context
                                      .read<ProfileSetupProvider>()
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                        onChanged: (String val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                          provider.setSearchQuery(val);
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Community Tiles ───────────────────────────────────────
                      if (provider.isLoadingCommunities && communities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gradientPink,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      else if (communities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No communities found',
                              style: TextStyle(
                                color: context.themeTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
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
                              onTap: () {
                                final bool toggled =
                                    provider.toggleCommunity(item.id);
                                if (!toggled) {
                                  AppSnackBar.showError(
                                    context,
                                    title: 'Action Not Allowed',
                                    subtitle:
                                        'At least 1 community must remain selected.',
                                  );
                                }
                              },
                            );
                          },
                        ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── View All Communities Link ────────────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () async {
                            final NavigatorState nav = Navigator.of(context);
                            final ProfileSetupProvider setupProvider =
                                context.read<ProfileSetupProvider>();
                            await nav.pushNamed(AppRoutes.allCommunities);
                            if (!mounted) return;
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            setupProvider.setSearchQuery('');
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
                child: Selector<ProfileSetupProvider, ({bool isBusy, int joinedCount})>(
                  selector: (_, ProfileSetupProvider p) =>
                      (isBusy: p.isBusy, joinedCount: p.joinedCount),
                  builder: (BuildContext context,
                      ({bool isBusy, int joinedCount}) data, _) {
                    return AppGradientButton(
                      text: data.joinedCount > 0
                          ? '${l10n.profileContinueBtn} · ${data.joinedCount} joined'
                          : l10n.profileContinueBtn,
                      isEnabled: data.joinedCount > 0,
                      isLoading: data.isBusy,
                      onPressed: data.isBusy ? () {} : _handleContinue,
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
