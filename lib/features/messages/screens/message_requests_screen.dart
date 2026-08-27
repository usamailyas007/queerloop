import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';

class MessageRequestsScreen extends StatelessWidget {
  const MessageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MessagesProvider provider = context.watch<MessagesProvider>();

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Top Header Bar (Back button + Title "Message requests") ───────
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
                      width: 36,
                      height: 36,
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Message requests',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle Info Text ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                "These people don't follow you. Accepting moves them to your main inbox — nothing sends until you reply.",
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── List of Message Request Cards ────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: provider.messageRequests.length,
                itemBuilder: (BuildContext context, int index) {
                  final MessageRequestModel req =
                      provider.messageRequests[index];
                  final String cleanUsername = req.username.startsWith('@')
                      ? req.username
                      : '@${req.username}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      children: <Widget>[
                        // Request Info Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => UserProfileScreen(
                                  username: req.username.replaceAll('@', ''),
                                  name: req.username
                                      .replaceAll('@', '')
                                      .split('.')
                                      .first,
                                  avatarAsset: req.avatarAsset,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Image.asset(
                                    req.avatarAsset,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        cleanUsername,
                                        style:
                                            AppTextStyles.titleSmall.copyWith(
                                          color: context.themeTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        req.previewMessage,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: context.themeTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        // Action Buttons Row (Accept, Delete, Block)
                        Row(
                          children: <Widget>[
                            // Accept (AppGradientButton)
                            Expanded(
                              flex: 3,
                              child: AppGradientButton(
                                text: 'Accept',
                                onPressed: () => provider.removeRequest(req.id),
                                height: 38,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),

                            // Delete (AppOutlineButton)
                            Expanded(
                              flex: 3,
                              child: AppOutlineButton(
                                text: 'Delete',
                                onPressed: () => provider.removeRequest(req.id),
                                height: 38,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),

                            // Block (AppOutlineButton with Cyan Border & Text)
                            Expanded(
                              flex: 2,
                              child: AppOutlineButton(
                                text: 'Block',
                                onPressed: () => provider.removeRequest(req.id),
                                height: 38,
                                borderColor: AppColors.gradientCyan,
                                textColor: AppColors.gradientCyan,
                              ),
                            ),
                          ],
                        ),
                      ],
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
