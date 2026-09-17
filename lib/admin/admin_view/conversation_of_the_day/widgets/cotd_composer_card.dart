import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// "Today's question" composer — the publish form on the overview screen.
class CotdComposerCard extends StatelessWidget {
  const CotdComposerCard({
    required this.controller,
    required this.publishing,
    required this.onPublish,
    super.key,
  });

  final TextEditingController controller;
  final bool publishing;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Today's question",
            style: TextStyle(
              color: AppColors.adminTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Question',
            style: TextStyle(color: AppColors.adminTextPrimary, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: controller,
            enabled: !publishing,
            hintText: "What's a small moment that made you feel truly seen?",
            fillColor: AppColors.adminSurfaceAlt,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 259,
              height: 44,
              child: AppGradientButton(
                text: 'Publish to everyone',
                isLoading: publishing,
                textStyle: const TextStyle(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                onPressed: publishing ? () {} : onPublish,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
