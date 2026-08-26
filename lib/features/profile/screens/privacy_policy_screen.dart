import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSection({
    required BuildContext context,
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
              color: context.themeTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bodyText,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.themeTextSecondary,
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
      backgroundColor: context.themeBackground,
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
                  Expanded(
                    child: Text(
                      'Privacy policy',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
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
                      color: context.themeTextMuted,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 1. What we collect
                  _buildSection(
                    context: context,
                    numberAndTitle: '1. What we collect',
                    bodyText:
                        'Account details (email, password), profile info you choose to add (display name, pronouns, bio, communities), your date of birth for age verification, and content you post or send.',
                  ),

                  // 2. How we use it
                  _buildSection(
                    context: context,
                    numberAndTitle: '2. How we use it',
                    bodyText:
                        'To run your feed, show your posts to the audience you pick, keep the community safe (reports, blocks, moderation), and improve the app. We do not sell your data to advertisers.',
                  ),

                  // 3. Your date of birth
                  _buildSection(
                    context: context,
                    numberAndTitle: '3. Your date of birth',
                    bodyText:
                        "Stored encrypted and used only to confirm you're 18 or older. It is never shown on your public profile and is not shared outside QueerLoop+.",
                  ),

                  // 4. Who can see your information
                  _buildSection(
                    context: context,
                    numberAndTitle: '4. Who can see your information',
                    bodyText:
                        "Your visibility settings (Everyone, Followers, Community only) control who sees your posts. Guests can only see what's marked public. Moderators can see reported content during review.",
                  ),

                  // 5. Guest browsing
                  _buildSection(
                    context: context,
                    numberAndTitle: '5. Guest browsing',
                    bodyText:
                        "Guests can browse a limited feed without an account. We don't log search history or personal identifiers for guest sessions.",
                  ),

                  // 6. Your choices
                  _buildSection(
                    context: context,
                    numberAndTitle: '6. Your choices',
                    bodyText:
                        "You can edit or delete your profile information at any time in Settings, download a copy of your data, or delete your account entirely — see Delete account for what's erased and what's kept.",
                  ),

                  // 7. Contact
                  _buildSection(
                    context: context,
                    numberAndTitle: '7. Contact',
                    bodyText:
                        'Questions about this policy can be sent through Help & support → Contact support.',
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
