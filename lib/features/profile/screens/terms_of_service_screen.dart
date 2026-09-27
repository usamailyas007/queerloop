import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Widget _buildSection({
    required BuildContext context,
    required String numberAndTitle,
    required String bodyText,
    bool isHighlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: isHighlight ? const EdgeInsets.all(AppSpacing.md) : EdgeInsets.zero,
      decoration: isHighlight
          ? BoxDecoration(
              color: AppColors.gradientCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gradientCyan.withValues(alpha: 0.3),
                width: 1,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            numberAndTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: isHighlight ? AppColors.gradientCyan : context.themeTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bodyText,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.themeTextSecondary,
              fontSize: 13,
              height: 1.5,
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
                      'Terms of Service & EULA',
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

                  // Header Badge Notice
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.themeBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'End User License Agreement (EULA) · Effective: March 2026',
                      style: AppTextStyles.caption.copyWith(
                        color: context.themeTextMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 1. Acceptance of Terms & EULA
                  _buildSection(
                    context: context,
                    numberAndTitle: '1. Acceptance of Terms & License Agreement',
                    bodyText:
                        'These Terms of Service, incorporating this End User License Agreement ("EULA"), constitute a legally binding agreement between you and QueerLoop+ ("we", "us", or "our"). By downloading, installing, accessing, creating an account, or using the QueerLoop+ application (the "App"), you confirm that you have read, understood, and agreed to be bound by these terms. If you do not agree, you must not access or use the App.',
                  ),

                  // 2. Eligibility & Age Requirements (18+)
                  _buildSection(
                    context: context,
                    numberAndTitle: '2. Eligibility & Age Restriction (18+)',
                    bodyText:
                        'QueerLoop+ is designed exclusively as a safe space for adults. You must be at least 18 years of age (or the age of majority in your jurisdiction) to create an account and use the App. By registering, you warrant that you are 18 or older and that all information you provide, including age verification data, is accurate and truthful. Providing false age information is a direct violation of these Terms.',
                  ),

                  // 3. Zero Tolerance for Objectionable Content & Abuse (Apple Guideline 1.2 & Google Play UGC Mandate)
                  _buildSection(
                    context: context,
                    isHighlight: true,
                    numberAndTitle: '3. Zero-Tolerance Policy for Objectionable Content & Abuse',
                    bodyText:
                        'QueerLoop+ strictly enforces a ZERO-TOLERANCE policy towards objectionable content and abusive users. There is no tolerance for hate speech, harassment, bullying, discrimination, threats of violence, non-consensual sexual content, explicit adult violence, doxxing, or defamatory conduct. Users who post objectionable material or engage in abusive behavior will have their content removed and face immediate, permanent account termination.',
                  ),

                  // 4. Prohibited Content and Conduct
                  _buildSection(
                    context: context,
                    numberAndTitle: '4. Prohibited Content and Conduct',
                    bodyText:
                        'You agree that you will not post, upload, publish, transmit, or share any User-Generated Content (UGC) that:\n'
                        '• Promotes hate speech, violence, discrimination, or bigotry against any individual or protected group based on race, ethnicity, sexual orientation, gender identity, religion, age, or disability.\n'
                        '• Contains child sexual abuse material (CSAM) or any form of minor exploitation (which is immediately reported to NCMEC and relevant law enforcement authorities).\n'
                        '• Involves non-consensual intimate imagery, pornography, or sexually explicit violence.\n'
                        '• Threatens, stalks, harasses, degrades, or intimidates any individual.\n'
                        '• Shares private, confidential, or personally identifiable information of another person without their express written consent (doxxing).\n'
                        '• Infringes any third party\'s copyright, trademark, patent, trade secret, or other intellectual property rights.\n'
                        '• Promotes illegal acts, fraudulent schemes, unauthorized commercial advertising, spam, or malicious software.',
                  ),

                  // 5. In-App Reporting & User Blocking (Apple App Store Guideline 1.2)
                  _buildSection(
                    context: context,
                    isHighlight: true,
                    numberAndTitle: '5. In-App Reporting & User Blocking Mechanisms',
                    bodyText:
                        'To safeguard our community, QueerLoop+ provides intuitive in-app moderation features:\n'
                        '• Reporting Content: You can report any post, reel, comment, or chat message directly via the in-app options menu (Report button).\n'
                        '• Blocking Abusive Users: You can block any abusive user at any time from their profile or post menu. Blocked users cannot message you, view your profile, or interact with your content.\n'
                        '• 24-Hour Moderation Commitment: Our moderation team investigates all reports promptly. Any content confirmed to be objectionable or in violation of these Terms will be removed within 24 hours of being reported, and the offending account will be penalized or permanently banned.',
                  ),

                  // 6. User-Generated Content & License Grant
                  _buildSection(
                    context: context,
                    numberAndTitle: '6. User-Generated Content (UGC) & Limited License',
                    bodyText:
                        'You retain all intellectual property ownership rights in the text, photos, videos, and reels you submit to QueerLoop+. By submitting content, you grant QueerLoop+ a worldwide, non-exclusive, royalty-free, transferable license to host, store, cache, encode, reproduce, display, and distribute your content solely for operating, promoting, and improving the App in accordance with your chosen audience visibility settings (Everyone, Followers Only, or Community Only). You represent and warrant that you own or have obtained all necessary licenses and permissions for the content you upload.',
                  ),

                  // 7. Account Registration, Security & Termination
                  _buildSection(
                    context: context,
                    numberAndTitle: '7. Account Security & Termination',
                    bodyText:
                        'You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use. QueerLoop+ reserves the absolute right to suspend, restrict, or terminate your account and access to the App at any time, with or without notice, if you violate these Terms, our Community Guidelines, or pose a safety or legal risk to the community.',
                  ),

                  // 8. Account Deletion Rights (Apple 5.1.1(v) & Google Play Data Safety)
                  _buildSection(
                    context: context,
                    numberAndTitle: '8. Account Deletion Rights',
                    bodyText:
                        'You have the unconditional right to delete your QueerLoop+ account and all associated personal data at any time directly within the App via Settings → Account → Delete Account. Deleting your account initiates the permanent removal of your profile, posts, reels, comments, and messages from our active servers.',
                  ),

                  // 9. Intellectual Property
                  _buildSection(
                    context: context,
                    numberAndTitle: '9. QueerLoop+ Intellectual Property',
                    bodyText:
                        'All rights, title, and interest in and to the QueerLoop+ platform—including the software, user interface design, logos, brand elements, graphics, and underlying source code—are the exclusive property of QueerLoop+ and its licensors. You may not copy, modify, distribute, reverse-engineer, or create derivative works of our software without our prior written consent.',
                  ),

                  // 10. Disclaimers of Warranties
                  _buildSection(
                    context: context,
                    numberAndTitle: '10. Disclaimer of Warranties',
                    bodyText:
                        'QueerLoop+ is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, whether express, implied, statutory, or otherwise, including implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not warrant that the service will be uninterrupted, error-free, secure, or free of harmful components.',
                  ),

                  // 11. Limitation of Liability
                  _buildSection(
                    context: context,
                    numberAndTitle: '11. Limitation of Liability',
                    bodyText:
                        'To the maximum extent permitted by applicable law, in no event shall QueerLoop+, its founders, directors, employees, or partners be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, goodwill, or personal injury, arising out of or related to your use of or inability to use the App, even if advised of the possibility of such damages.',
                  ),

                  // 12. Digital Millennium Copyright Act (DMCA) / IP Notice
                  _buildSection(
                    context: context,
                    numberAndTitle: '12. Copyright & Intellectual Property Claims',
                    bodyText:
                        'If you believe that your copyrighted work has been copied in a way that constitutes copyright infringement, please provide our designated copyright agent with written notice containing: a description of the copyrighted work, the location of the infringing material on QueerLoop+, and your contact information at legal@queerloop.com.',
                  ),

                  // 13. Modifications to Terms
                  _buildSection(
                    context: context,
                    numberAndTitle: '13. Changes to These Terms',
                    bodyText:
                        'We may update these Terms and EULA from time to time. When we make material changes, we will notify you through the App or by other reasonable means. Your continued use of the App following the effective date of revised terms constitutes your acceptance of the updated Terms.',
                  ),

                  // 14. Contact Information
                  _buildSection(
                    context: context,
                    numberAndTitle: '14. Contact & Support',
                    bodyText:
                        'If you have questions, feedback, or need to report violations regarding these Terms of Service or EULA, please contact us:\n'
                        '• Legal & Compliance: legal@queerloop.com\n'
                        '• Community Support: support@queerloop.com\n'
                        '• In-App Support: Settings → Help & Support → Contact Support',
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
