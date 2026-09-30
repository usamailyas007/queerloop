import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Widget _buildEmailCard({
    required BuildContext context,
    required String email,
    String label = 'Community Support',
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: email));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $email to clipboard'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.gradientCyan.withValues(
              alpha: context.isDarkMode ? 0.12 : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gradientCyan.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.gradientCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mail_rounded,
                  color: AppColors.gradientCyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      label.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gradientCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Copy Email',
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.gradientCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.gradientCyan,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String numberAndTitle,
    required String bodyText,
    bool isHighlight = false,
    Widget? customContent,
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
          if (customContent != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm + 2),
            customContent,
          ],
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
                      'Terms of Service',
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
                      'Terms of Service · Effective: September 30, 2026',
                      style: AppTextStyles.caption.copyWith(
                        color: context.themeTextMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 1. Acceptance of Terms & Contracting Party
                  _buildSection(
                    context: context,
                    numberAndTitle: '1. Acceptance of Terms & Contracting Party',
                    bodyText:
                        'These Terms of Service constitute a legally binding agreement between you ("User") and the individual developer and operator of QueerLoop+ ("Developer", "we", "us", or "our", trading as "QueerLoop+"), or any successor legal entity that may assume operations in the future. For users acquiring the App through the Apple App Store, Apple\'s standard Licensed Application End User License Agreement (EULA) applies in conjunction with these Terms. By downloading, installing, accessing, creating an account, or using the QueerLoop+ application (the "App"), you confirm that you have read, understood, and agreed to be bound by these terms. If you do not agree, you must not access or use the App.',
                  ),

                  // 2. Zero Tolerance for Objectionable Content & Abuse
                  _buildSection(
                    context: context,
                    isHighlight: true,
                    numberAndTitle: '2. Zero-Tolerance Policy for Objectionable Content & Abuse',
                    bodyText:
                        'QueerLoop+ strictly enforces a ZERO-TOLERANCE policy towards objectionable content and abusive users. There is no tolerance for hate speech, harassment, bullying, discrimination, threats of violence, non-consensual sexual content, explicit adult violence, doxxing, or defamatory conduct. Users who post objectionable material or engage in abusive behavior will have their content removed and face immediate, permanent account termination.',
                  ),

                  // 3. Prohibited Content and Conduct
                  _buildSection(
                    context: context,
                    numberAndTitle: '3. Prohibited Content and Conduct',
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

                  // 4. In-App Reporting & User Blocking Mechanisms
                  _buildSection(
                    context: context,
                    isHighlight: true,
                    numberAndTitle: '4. In-App Reporting & User Blocking Mechanisms',
                    bodyText:
                        'To safeguard our community, QueerLoop+ provides intuitive in-app moderation features:\n'
                        '• Reporting Content: You can report any post or reel via the Safety button, comments via the Report option on the comment, and direct message conversations via Chat Options (Report Conversation).\n'
                        '• Blocking Abusive Users: You can block any abusive user at any time from their profile or post options menu. Blocked users cannot message you, view your profile, or interact with your content.\n'
                        '• 24-Hour Moderation Commitment: Our moderation team investigates all reports promptly. Any content confirmed to be objectionable or in violation of these Terms will be removed within 24 hours of being reported, and the offending account will be penalized or permanently banned.',
                  ),

                  // 5. User-Generated Content & License Grant
                  _buildSection(
                    context: context,
                    numberAndTitle: '5. User-Generated Content (UGC) & Limited License',
                    bodyText:
                        'You retain all intellectual property ownership rights in the text, photos, videos, and reels you submit to QueerLoop+. By submitting content, you grant QueerLoop+ a worldwide, non-exclusive, royalty-free, transferable license to host, store, cache, encode, reproduce, display, and distribute your content solely for operating and improving the App in accordance with your chosen audience visibility settings (Everyone, Followers Only, or Community Only). To protect member safety, identity, and privacy, QueerLoop+ will NEVER use, feature, or display your posts, photos, reels, or identity in external advertising, marketing, or promotional campaigns without your express, prior written consent. You represent and warrant that you own or have obtained all necessary licenses and permissions for the content you upload.',
                  ),

                  // 6. Account Registration, Security & Termination
                  _buildSection(
                    context: context,
                    numberAndTitle: '6. Account Security & Termination',
                    bodyText:
                        'You are responsible for maintaining the confidentiality of your login credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use. QueerLoop+ reserves the absolute right to suspend, restrict, or terminate your account and access to the App at any time, with or without notice, if you violate these Terms, our Community Guidelines, or pose a safety or legal risk to the community.',
                  ),

                  // 7. Account Deletion Rights
                  _buildSection(
                    context: context,
                    numberAndTitle: '7. Account Deletion Rights',
                    bodyText:
                        'You have the unconditional right to delete your QueerLoop+ account and all associated personal data at any time directly within the App via Settings → Delete account. Upon request, all personal data (profile, posts, reels, comments, photos, videos, and messages) is permanently erased from active servers within 30 days. Any safety reports you submitted remain with moderation in an anonymized form without your name or identifying details to maintain community safety.',
                  ),

                  // 8. Intellectual Property
                  _buildSection(
                    context: context,
                    numberAndTitle: '8. QueerLoop+ Intellectual Property',
                    bodyText:
                        'All rights, title, and interest in and to the QueerLoop+ platform—including the software, user interface design, logos, brand elements, graphics, and underlying source code—are the exclusive property of QueerLoop+ and its licensors. You may not copy, modify, distribute, reverse-engineer, or create derivative works of our software without our prior written consent.',
                  ),

                  // 9. Disclaimers of Warranties
                  _buildSection(
                    context: context,
                    numberAndTitle: '9. Disclaimer of Warranties',
                    bodyText:
                        'QueerLoop+ is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, whether express, implied, statutory, or otherwise, including implied warranties of merchantability, fitness for a particular purpose, and non-infringement. We do not warrant that the service will be uninterrupted, error-free, secure, or free of harmful components.',
                  ),

                  // 10. Limitation of Liability
                  _buildSection(
                    context: context,
                    numberAndTitle: '10. Limitation of Liability',
                    bodyText:
                        'To the maximum extent permitted by applicable law, in no event shall QueerLoop+, its founders, directors, employees, or partners be liable for any indirect, incidental, special, consequential, or punitive damages, including loss of profits, data, goodwill, or personal injury, arising out of or related to your use of or inability to use the App, even if advised of the possibility of such damages.',
                  ),

                  // 11. Digital Millennium Copyright Act (DMCA) / IP Notice
                  _buildSection(
                    context: context,
                    numberAndTitle: '11. Copyright & Intellectual Property Claims',
                    bodyText:
                        'If you believe that your copyrighted work has been copied in a way that constitutes copyright infringement, please provide our designated copyright agent with written notice containing: a description of the copyrighted work, the location of the infringing material on QueerLoop+, and your contact information.',
                    customContent: _buildEmailCard(
                      context: context,
                      email: 'hello@queerloopplus.com',
                      label: 'DMCA / Copyright Inquiries',
                    ),
                  ),

                  // 12. Modifications to Terms
                  _buildSection(
                    context: context,
                    numberAndTitle: '12. Changes to These Terms',
                    bodyText:
                        'We may update these Terms from time to time. When we make material changes, we will notify you through the App or by other reasonable means. Your continued use of the App following the effective date of revised terms constitutes your acceptance of the updated Terms.',
                  ),

                  // 13. Governing Law & Jurisdiction
                  _buildSection(
                    context: context,
                    numberAndTitle: '13. Governing Law & Jurisdiction',
                    bodyText:
                        'These Terms and any dispute, claim, or controversy arising out of or relating to your use of the App shall be governed by and construed in accordance with the laws applicable to the Developer\'s primary jurisdiction of operation and residence, without regard to its conflict of law principles. You agree to submit to the personal and exclusive jurisdiction of the competent courts located within the Developer\'s jurisdiction for the resolution of any legal proceedings, except where prohibited by mandatory local consumer protection laws.',
                  ),

                  // 14. Contact Information
                  _buildSection(
                    context: context,
                    numberAndTitle: '14. Contact & Support',
                    bodyText:
                        'If you have questions, feedback, or need to report violations regarding these Terms of Service, please reach out to our team directly:',
                    customContent: _buildEmailCard(
                      context: context,
                      email: 'hello@queerloopplus.com',
                      label: 'Community Support',
                    ),
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
