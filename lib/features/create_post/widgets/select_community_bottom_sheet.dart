import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';

class SelectCommunityBottomSheet extends StatefulWidget {
  const SelectCommunityBottomSheet({
    required this.selectedCommunity,
    required this.onSelect,
    this.selectedCommunityId,
    super.key,
  });

  final String selectedCommunity;
  final String? selectedCommunityId;
  final ValueChanged<CommunityModel> onSelect;

  static Future<CommunityModel?> show(
    BuildContext context, {
    required String currentCommunity,
    String? currentCommunityId,
  }) async {
    CommunityModel? selected;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectCommunityBottomSheet(
        selectedCommunity: currentCommunity,
        selectedCommunityId: currentCommunityId,
        onSelect: (CommunityModel c) => selected = c,
      ),
    );
    return selected;
  }

  @override
  State<SelectCommunityBottomSheet> createState() =>
      _SelectCommunityBottomSheetState();
}

class _SelectCommunityBottomSheetState
    extends State<SelectCommunityBottomSheet> {
  late String _tempSelected;
  late String? _tempSelectedId;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedCommunity;
    _tempSelectedId = widget.selectedCommunityId;
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ProfileSetupProvider setupProvider =
          context.read<ProfileSetupProvider>();
      if (setupProvider.allCommunities.isEmpty) {
        setupProvider.fetchCommunities();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(CommunityModel item) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return Image.network(
        item.imageUrl!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildLocalAvatar(item),
      );
    }
    return _buildLocalAvatar(item);
  }

  Widget _buildLocalAvatar(CommunityModel item) {
    if (item.avatarAsset.isNotEmpty) {
      return Image.asset(
        item.avatarAsset,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackAvatar(),
      );
    }
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.gradientCyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.group_rounded,
        color: AppColors.gradientCyan,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider setupProvider =
        context.watch<ProfileSetupProvider>();
    final List<CommunityModel> communities = setupProvider.allCommunities;
    final bool isLoading = setupProvider.isLoadingCommunities;

    final String query = _searchController.text.trim().toLowerCase();
    final List<CommunityModel> filtered = communities
        .where((CommunityModel c) =>
            query.isEmpty || c.name.toLowerCase().contains(query))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag handle
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

            const SizedBox(height: AppSpacing.lg),

            // Header (Title + Close X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Select Community',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: context.themeTextPrimary,
                    fontSize: 20,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: context.themeIconMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Search Bar using AppTextField
            AppTextField(
              controller: _searchController,
              hintText: 'Search communities...',
              prefixIconPath: AppIcons.search,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Content
            Expanded(
              child: isLoading && communities.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gradientPink,
                        strokeWidth: 2.5,
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.people_outline_rounded,
                                size: 40,
                                color: context.themeIconMuted,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No communities found',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.themeTextMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int index) {
                            final CommunityModel item = filtered[index];
                            final bool isSelected =
                                (_tempSelectedId != null &&
                                        _tempSelectedId == item.id) ||
                                    _tempSelected.trim().toLowerCase() ==
                                        item.name.trim().toLowerCase();

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _tempSelected = item.name;
                                  _tempSelectedId = item.id;
                                });
                                widget.onSelect(item);
                                Navigator.pop(context, item);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: context.themeCardBackground,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.card),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.gradientCyan
                                        : context.themeBorder,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: _buildAvatar(item),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.name,
                                            style: AppTextStyles.titleSmall
                                                .copyWith(
                                              color: context.themeTextPrimary,
                                              fontWeight: FontWeight.w700,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.description != null &&
                                                    item.description!.isNotEmpty
                                                ? item.description!
                                                : 'Community',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: context.themeTextMuted,
                                              fontSize: 12,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
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
          ],
        ),
      ),
    );
  }
}
