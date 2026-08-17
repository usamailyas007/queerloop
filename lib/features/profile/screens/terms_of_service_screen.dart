import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Widget _buildSection({
    required String numberAndTitle,
    required String bodyText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            numberAndTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bodyText,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  Expanded(
                    child: Text(
                      'Terms of service',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38), // Balance spacing
                ],
              ),
            ),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xs),

                  // Timestamp Notice
                  Text(
                    'Last updated 1 January 2026 · Placeholder copy for handover',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 1. Acceptance of terms
                  _buildSection(
                    numberAndTitle: '1. Acceptance of terms',
                    bodyText:
                        'By creating an account or browsing as a guest, you agree to these Terms and to our Community Rules. If you do not agree, please do not use QueerLoop+.',
                  ),

                  // 2. Your content
                  _buildSection(
                    numberAndTitle: '2. Your content',
                    bodyText:
                        'You keep ownership of what you post. By publishing, you grant QueerLoop+ a limited licence to host, display and distribute it within the app so other members can see it, based on the visibility you choose.',
                  ),

                  // 3. Community conduct
                  _buildSection(
                    numberAndTitle: '3. Community conduct',
                    bodyText:
                        "Harassment, hate speech, doxxing and content that endangers a member's safety are never allowed. Violations may lead to content removal, a warning or account suspension — see Moderation & appeals.",
                  ),

                  // 4. Account termination
                  _buildSection(
                    numberAndTitle: '4. Account termination',
                    bodyText:
                        'You can delete your account at any time from Settings. We may suspend or remove accounts that violate these Terms or put other members at risk.',
                  ),

                  // 5. Disclaimers & liability
                  _buildSection(
                    numberAndTitle: '5. Disclaimers & liability',
                    bodyText:
                        'QueerLoop+ is provided "as is." We work to keep the community safe but cannot guarantee it is free of errors, downtime or content that violates our rules before it\'s reviewed.',
                  ),

                  // 6. Changes to these terms
                  _buildSection(
                    numberAndTitle: '6. Changes to these terms',
                    bodyText:
                        "We'll notify members in-app before material changes take effect. Continuing to use QueerLoop+ after that point means you accept the updated Terms.",
                  ),

                  // 7. Eligibility
                  _buildSection(
                    numberAndTitle: '7. Eligibility',
                    bodyText:
                        'QueerLoop+ is an 18+ space. You confirm you are at least 18 years old, and that any information you provide, including your date of birth in Profile settings, is accurate.',
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
