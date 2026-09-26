import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../../auth/widgets/auth_back_button.dart';
import '../../profile/provider/profile_provider.dart';
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
  String _searchQuery = '';
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _searchQuery = '';
    _searchController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ProfileProvider profile = context.read<ProfileProvider>();
      final ProfileSetupProvider setupProvider =
          context.read<ProfileSetupProvider>();
      final AuthProvider auth = context.read<AuthProvider>();

      setupProvider.setSearchQuery('');
      setupProvider.fetchCommunities();

      final String? uid = auth.userId ?? auth.user?.id;
      if (profile.userCommunities.isEmpty && uid != null && uid.isNotEmpty) {
        await profile.fetchUserCommunities(uid);
      }
      if (mounted) {
        setupProvider.syncJoinedCommunities(
          profile.userCommunities,
          force: true,
        );
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

  Future<void> _handleJoin() async {
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
    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() => _isJoining = true);
    final bool ok = await provider.saveStep4();
    if (!mounted) return;
    setState(() => _isJoining = false);
    if (ok) {
      final String? uid = auth.userId ?? auth.user?.id;
      if (uid != null && uid.isNotEmpty) {
        try {
          await profileProvider.fetchUserCommunities(uid, forceRefresh: true);
        } catch (_) {}
      }
      provider.setStep(4);
      navigator.pop();
    } else {
      final String? err = provider.error;
      AppSnackBar.showError(
        context,
        title: 'Join Failed',
        subtitle: err ?? 'Failed to join communities.',
        messenger: messenger,
      );
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
    final int joinedCount = provider.joinedCount;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          context.read<ProfileSetupProvider>().setSearchQuery('');
        }
      },
      child: Scaffold(
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
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
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
                            context
                                .read<ProfileSetupProvider>()
                                .setSearchQuery(val);
                          },
                        ),

                      const SizedBox(height: AppSpacing.lg),

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
                      ? 'Save $joinedCount ${joinedCount == 1 ? 'Community' : 'Communities'}'
                      : 'Select at least 1 community',
                  isLoading: _isJoining,
                  isEnabled: joinedCount >= 1 && !_isJoining,
                  onPressed: _handleJoin,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
