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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Large Title (Left Aligned)
              Text(
                'Who Can Comment',
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Choose who can comment on your posts.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
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
                    final bool isSelected = _currentSelection == option;
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
