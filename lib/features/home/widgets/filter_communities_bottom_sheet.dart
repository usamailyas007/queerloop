import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';

class FilterCommunitiesBottomSheet extends StatefulWidget {
  const FilterCommunitiesBottomSheet({
    required this.selectedCommunity,
    required this.onApply,
    this.communities,
    super.key,
  });

  final String selectedCommunity;
  final void Function(String communityName, String? communityId) onApply;
  final List<CommunityModel>? communities;

  @override
  State<FilterCommunitiesBottomSheet> createState() =>
      _FilterCommunitiesBottomSheetState();
}

class _CommunityFilterOption {
  const _CommunityFilterOption({required this.name, this.id});
  final String name;
  final String? id;
}

class _FilterCommunitiesBottomSheetState
    extends State<FilterCommunitiesBottomSheet> {
  late String _selectedName;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.selectedCommunity;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final ProfileSetupProvider setup = context.read<ProfileSetupProvider>();
          if (setup.allCommunities.isEmpty) {
            setup.fetchCommunities();
          }
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final List<CommunityModel> availableComms = <CommunityModel>[];
    if (widget.communities != null && widget.communities!.isNotEmpty) {
      availableComms.addAll(widget.communities!);
    }
    try {
      final ProfileSetupProvider setup = context.watch<ProfileSetupProvider>();
      for (final CommunityModel c in setup.allCommunities) {
        if (!availableComms.any((existing) => existing.id == c.id)) {
          availableComms.add(c);
        }
      }
    } catch (_) {}
    try {
      final ProfileProvider profile = context.watch<ProfileProvider>();
      for (final CommunityModel c in profile.userCommunities) {
        if (!availableComms.any((existing) => existing.id == c.id)) {
          availableComms.add(c);
        }
      }
    } catch (_) {}

    final List<_CommunityFilterOption> options = <_CommunityFilterOption>[
      const _CommunityFilterOption(name: 'All Communities', id: null),
    ];
    for (final CommunityModel c in availableComms) {
      if (c.name.trim().isNotEmpty &&
          !options.any((o) => o.name.toLowerCase() == c.name.toLowerCase())) {
        options.add(_CommunityFilterOption(name: c.name, id: c.id));
      }
    }
    if (options.length == 1) {
      const List<String> defaultNames = <String>[
        'Lesbian',
        'Bisexual',
        'Non-binary',
        'Gay',
        'Queer',
        'Transgender',
      ];
      for (final String n in defaultNames) {
        options.add(_CommunityFilterOption(name: n, id: null));
      }
    }

    if (_selectedId == null &&
        _selectedName.toLowerCase() != 'all communities') {
      final int initialIdx = options.indexWhere(
        (o) => o.name.toLowerCase() == _selectedName.toLowerCase(),
      );
      if (initialIdx != -1 && options[initialIdx].id != null) {
        _selectedId = options[initialIdx].id;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Drag Handle Bar ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Header (Title + Close X Button) ──────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  l10n.filterCommunitiesTitle,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    color: context.themeIconMuted,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              l10n.filterCommunitiesSub,
              style: TextStyle(
                color: context.themeTextSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Community Options List ─────────────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final _CommunityFilterOption option = options[index];
                  final bool isSelected =
                      _selectedName.toLowerCase() == option.name.toLowerCase();

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedName = option.name;
                        _selectedId = option.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.themeCyanBadgeBackground
                            : context.themeCardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gradientCyan
                              : context.themeBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            option.name,
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.gradientCyan,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Bottom Apply Button ─────────────────────────────────────────
            AppGradientButton(
              text: l10n.filterApplyBtn,
              onPressed: () {
                widget.onApply(_selectedName, _selectedId);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
