import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile_setup/widgets/privacy_option_card.dart';

class WhoCanCommentScreen extends StatefulWidget {
  const WhoCanCommentScreen({
    this.initialSelection = 'People you follow',
    super.key,
  });

  final String initialSelection;

  @override
  State<WhoCanCommentScreen> createState() => _WhoCanCommentScreenState();
}

class _WhoCanCommentScreenState extends State<WhoCanCommentScreen> {
  late String _currentSelection;

  static const List<String> _options = <String>[
    'Everyone',
    'People you follow',
    'Mutual follows',
    'Nobody',
  ];

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.initialSelection;
  }

  bool _isMatch(String option, String selection) {
    final String o = option.toLowerCase().trim();
    final String s = selection.toLowerCase().trim();
    if (o == s) return true;
    if (o.contains('everyone') && s.contains('everyone')) return true;
    if (o.contains('nobody') && s.contains('nobody')) return true;

    final bool isOptMutual = o.contains('mutual');
    final bool isSelectedMutual = s.contains('mutual');
    if (isOptMutual && isSelectedMutual) return true;
    if (isOptMutual || isSelectedMutual) return false;

    final bool isOptFollow = o.contains('follow');
    final bool isSelectedFollow =
        s.contains('follow') || s.contains('following');
    if (isOptFollow && isSelectedFollow) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),

              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context, _currentSelection),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.12)
                          : context.themeBorder,
                      width: 1.1,
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: context.themeIcon,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Large Title (Left Aligned)
              Text(
                'Who Can Comment',
                style: AppTextStyles.headingMedium.copyWith(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Choose who can comment on your posts.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Options List
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _options.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (BuildContext context, int index) {
                    final String option = _options[index];
                    final bool isSelected = _isMatch(option, _currentSelection);
                    final bool isRecommended = option == 'People you follow';

                    return PrivacyOptionCard(
                      optionTitle: option,
                      isSelected: isSelected,
                      isRecommended: isRecommended,
                      onTap: () {
                        setState(() => _currentSelection = option);
                        Navigator.pop(context, option);
                      },
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
