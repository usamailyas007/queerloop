import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';

class FilterCommunitiesBottomSheet extends StatefulWidget {
  const FilterCommunitiesBottomSheet({
    required this.selectedCommunity,
    required this.onApply,
    super.key,
  });

  final String selectedCommunity;
  final ValueChanged<String> onApply;

  @override
  State<FilterCommunitiesBottomSheet> createState() =>
      _FilterCommunitiesBottomSheetState();
}

class _FilterCommunitiesBottomSheetState
    extends State<FilterCommunitiesBottomSheet> {
  late String _selected;

  final List<String> _communitiesList = <String>[
    'All Communities',
    'Lesbian',
    'Bisexual',
    'Non-binary',
    'Gay',
    'Queer',
    'Transgender',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCommunity;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12101A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.white24,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              l10n.filterCommunitiesSub,
              style: const TextStyle(
                color: Colors.white54,
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
                itemCount: _communitiesList.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final String communityName = _communitiesList[index];
                  final bool isSelected = _selected == communityName;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = communityName;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B26),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gradientCyan
                              : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            communityName,
                            style: TextStyle(
                              color: Colors.white,
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
                widget.onApply(_selected);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
