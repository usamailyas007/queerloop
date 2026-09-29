import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                      'Privacy Policy',
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
                      'QueerLoop+ Data Protection & Privacy · Effective: September 30, 2026',
                      style: AppTextStyles.caption.copyWith(
                        color: context.themeTextMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 1. Introduction
                  _buildSection(
                    context: context,
                    numberAndTitle: '1. Introduction & Data Controller',
                    bodyText:
                        'QueerLoop+ ("we", "us", or "our", operated by the individual developer and proprietor trading as QueerLoop+, or any successor entity) is dedicated to protecting the privacy, identity, and personal data of our members. This Privacy Policy describes what information we collect, why we collect it, how it is secured, and how you can manage or delete your data across our mobile applications on iOS (Apple App Store) and Android (Google Play Store). By accessing or using QueerLoop+, you acknowledge the terms of this Privacy Policy.',
                  ),

                  // 2. Information We Collect
                  _buildSection(
                    context: context,
                    numberAndTitle: '2. Information We Collect',
                    bodyText:
                        'We collect the following categories of information to provide and safeguard our services:\n'
                        '• Account & Profile Information: Email address, username, display name, cryptographically hashed passwords, and profile details you choose to share (pronouns, bio, profile photo, and community affiliations).\n'
                        '• Sensitive Identity Labels & Interests (Voluntary): You may choose to select identity labels (such as Lesbian, Gay, Bisexual, Transgender, Non-Binary, Queer, etc.) and personal interests. Because identity labels reveal sexual orientation and gender identity—treated as sensitive or special category data under GDPR and privacy regulations—you provide this information voluntarily, and you can edit or remove these labels at any time in Edit Profile.\n'
                        '• Third-Party Sign-In Data: When you register or sign in using Apple or Google, we collect your name, authenticated email address, and authorized provider identifiers (such as Apple Private Relay IDs) to create and secure your account.\n'
                        '• User-Generated Content (UGC): Posts, photo uploads, video reels, captions, tags, comments, bookmarks, and direct messages that you post or send.\n'
                        '• Search & Interaction History: Searches, keywords, and hashtags you enter in Discover, along with post engagement history, to provide search results and relevant community content.\n'
                        '• Safety & Moderation Reports: Details of reports you file against abusive users or content (including reason and description), used strictly by human moderators to investigate safety violations.\n'
                        '• Activity Status & Read Receipts: Indicators showing when you are active and whether direct messages have been read (which you can toggle off at any time in Settings → Privacy).\n'
                        '• Device & Technical Data: IP address, device hardware model, operating system version, push notification tokens (Firebase Cloud Messaging / APNs), language preferences, and anonymized diagnostic crash logs.\n'
                        '• Guest Browsing: When using the App as a guest, you can view public content without creating an account. We do not track personal identities or link browsing history to guest sessions.',
                  ),

                  // 3. How We Use Information
                  _buildSection(
                    context: context,
                    numberAndTitle: '3. How We Use Your Information',
                    bodyText:
                        'We use your information strictly for legitimate operational purposes:\n'
                        '• To authenticate your account, maintain your session, and secure access.\n'
                        '• To publish, transcode, and deliver your posts, photos, and video reels according to your selected audience settings.\n'
                        '• To facilitate community connections, direct messaging, and interactive features.\n'
                        '• To enforce our Community Guidelines and Terms of Service, investigate reports, remove objectionable content, and ban abusive accounts. When a post, comment, or direct message conversation is reported for safety violations, our moderation team reviews the reported material—including the last 30 days of messages from a reported chat—strictly to investigate the report and safeguard user safety.\n'
                        '• To deliver important service updates, security notifications, and optional push notifications (which you can disable at any time in Settings).',
                  ),

                  // 4. We Do Not Sell Your Personal Data
                  _buildSection(
                    context: context,
                    isHighlight: true,
                    numberAndTitle: '4. We Do Not Sell Your Personal Information',
                    bodyText:
                        'QueerLoop+ does NOT sell, rent, lease, or trade your personal data, profile information, or usage habits to third-party data brokers, marketing agencies, or advertising networks. We believe in providing an ad-free, respectful, and private space for our community.',
                  ),

                  // 5. Data Sharing & Third-Party Service Providers
                  _buildSection(
                    context: context,
                    numberAndTitle: '5. Third-Party Service Providers & Cloud Hosting',
                    bodyText:
                        'We share information only with trusted third-party service providers bound by strict confidentiality and data protection agreements:\n'
                        '• Cloud Infrastructure: We utilize Amazon Web Services (AWS S3) and secure hosting infrastructure for secure cloud storage and media transcoding.\n'
                        '• Push Notifications: We use Firebase Cloud Messaging (Google) and Apple Push Notification service (APNs) to deliver instant notifications when you receive messages or engagement.\n'
                        '• Legal Compliance: We will disclose personal information to law enforcement only when strictly required by a binding court order, legal warrant, or to prevent imminent physical harm.',
                  ),

                  // 6. Privacy Settings & Visibility Controls
                  _buildSection(
                    context: context,
                    numberAndTitle: '6. Content Visibility & Privacy Settings',
                    bodyText:
                        'You maintain full granular control over your profile, content, and interactions directly under Settings → Privacy:\n'
                        '• Direct Messaging Controls: You choose who can send you direct messages with four distinct options: Everyone, People you follow, Mutual follows, or Nobody.\n'
                        '• Commenting Controls: You control who can comment on your posts and reels with the same four options: Everyone, People you follow, Mutual follows, or Nobody.\n'
                        '• Private Account: You can switch your account to Private, requiring you to approve any follow requests before other users can view your posts or followers.\n'
                        '• Profile Visibility: You can configure whether your profile is broadly visible or restricted to approved community connections.\n'
                        '• Appear in Discover: You can toggle whether your profile and content appear in the public Discover and search feeds.\n'
                        '• Hide Likes: You can choose to hide your liked posts so other users cannot see what content you have liked.\n'
                        '• Activity Status & Read Receipts: You can independently toggle whether others see when you are active and whether message read receipts are sent.\n'
                        '• Post Audience Visibility: When creating any post or reel, you can designate its individual audience as "Everyone", "Followers Only", or "Community Only".\n'
                        '• Blocking & Muting: You can block or mute any user instantly. Blocked users cannot see your profile, view your posts, or send you messages.',
                  ),

                  // 7. Account & Data Deletion
                  _buildSection(
                    context: context,
                    isHighlight: true,
                    numberAndTitle: '7. Account & Data Deletion Rights',
                    bodyText:
                        'QueerLoop+ empowers users to permanently delete their account and associated personal data directly within the App at any time:\n'
                        '• How to Delete: Navigate to Settings → Delete account and confirm your deletion request.\n'
                        '• Data Erasure: When account deletion is requested, all personal data associated with your account (profile, posts, reels, photos, videos, captions, comments, and messages) is permanently erased from active servers within 30 days.\n'
                        '• Anonymized Moderation Records: Safety and abuse reports you filed prior to deletion remain in moderation records to preserve community safety, but your name and identifying account details are permanently stripped and anonymized.',
                  ),

                  // 8. Data Security & Retention
                  _buildSection(
                    context: context,
                    numberAndTitle: '8. Data Security & Storage Standards',
                    bodyText:
                        'We implement industry-standard administrative, physical, and technical safeguards to protect your personal data:\n'
                        '• Encryption in Transit: All data transferred between your mobile device and our servers is encrypted using modern Transport Layer Security (HTTPS / TLS 1.3).\n'
                        '• Encryption at Rest: Media and database records are stored with advanced encryption standards (AES-256).\n'
                        '• Password Protection: All user passwords are encrypted using one-way cryptographic hashing algorithms and are never stored in plaintext.',
                  ),

                  // 9. Children's Privacy (Strict 18+ Policy)
                  _buildSection(
                    context: context,
                    numberAndTitle: '9. Children\'s Online Privacy Protection (18+ Only)',
                    bodyText:
                        'QueerLoop+ is strictly intended for adults who are 18 years of age or older. We do not knowingly solicit or collect personal information from children or minors under 18. If we learn that personal data of a user under 18 has been collected or that an account belongs to a minor, we will immediately deactivate the account and delete all associated information.',
                  ),

                  // 10. Your Rights (GDPR, CCPA / CPRA & Global Rights)
                  _buildSection(
                    context: context,
                    numberAndTitle: '10. Your Privacy Rights (GDPR & CCPA/CPRA)',
                    bodyText:
                        'Depending on your location, you may have specific statutory privacy rights:\n'
                        '• Right to Access: You can review all personal data stored in your profile at any time in Settings.\n'
                        '• Right to Rectification: You can update, correct, or edit your username, bio, and details directly in Edit Profile.\n'
                        '• Right to Erasure ("Right to be Forgotten"): You can permanently delete your account and data at any time via Settings.\n'
                        '• Right to Restrict or Object: You can restrict who can message you or view your content through in-app visibility toggles.',
                  ),

                  // 11. Changes to This Privacy Policy
                  _buildSection(
                    context: context,
                    numberAndTitle: '11. Changes to This Privacy Policy',
                    bodyText:
                        'We may update this Privacy Policy periodically to reflect changes in our practices or applicable legal requirements. When updates are published, the "Effective Date" at the top of this policy will be revised, and in-app notifications will be displayed for significant updates.',
                  ),

                  // 12. Contact Information & Data Protection Officer
                  _buildSection(
                    context: context,
                    numberAndTitle: '12. Contact Information & Data Inquiries',
                    bodyText:
                        'If you have any questions, concerns, or requests regarding this Privacy Policy or how your personal information is handled, please reach out to our team directly:',
                    customContent: _buildEmailCard(
                      context: context,
                      email: 'hello@queerloopplus.com',
                      label: 'Community Support & Privacy',
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
