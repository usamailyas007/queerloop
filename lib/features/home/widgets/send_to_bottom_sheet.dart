import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';

class SendToBottomSheet extends StatefulWidget {
  const SendToBottomSheet({super.key});

  @override
  State<SendToBottomSheet> createState() => _SendToBottomSheetState();
}

class _SendToBottomSheetState extends State<SendToBottomSheet> {
  final TextEditingController _searchController =
      TextEditingController(text: 'jul');
  final TextEditingController _messageController = TextEditingController();

  final Set<String> _selectedUserIds = <String>{'jules'};

  void _toggleUser(String id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // ── Drag Handle Bar ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Header (Back Arrow + "Send to" + "1 selected") ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: context.themeIcon,
                      size: AppSizes.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.sendToTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.sendToSelected,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Scrollable Body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // ── Attached Post Preview Card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.themeBorder,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            AppImages.forYouImg,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "@ashinorbit's post",
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Binder fit check · 12.4K views',
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Search Field with Reusable AppTextField Component ──────
                  AppTextField(
                    controller: _searchController,
                    hintText: l10n.sendToSearchHint,
                    prefixIconPath: AppIcons.search,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── TOP CONNECTIONS Subheader ──────────────────────────────
                  Text(
                    l10n.sendToTopConnections,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Contact Item 1: jules.does (Checked) ───────────────────
                  _ContactListTile(
                    avatarAsset: AppImages.user1,
                    handle: 'jules.does',
                    subText: 'Jules · you talk often',
                    isSelected: _selectedUserIds.contains('jules'),
                    onTap: () => _toggleUser('jules'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Contact Item 2: rowankeeps ─────────────────────────────
                  _ContactListTile(
                    avatarAsset: AppImages.user2,
                    handle: 'rowankeeps',
                    subText: 'Rowan',
                    isSelected: _selectedUserIds.contains('rowan'),
                    onTap: () => _toggleUser('rowan'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Contact Item 3: moss.and.oat ───────────────────────────
                  _ContactListTile(
                    avatarAsset: AppImages.user3,
                    handle: 'moss.and.oat',
                    subText: 'Moss',
                    isSelected: _selectedUserIds.contains('moss'),
                    onTap: () => _toggleUser('moss'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Contact Item 4: theo.vance ─────────────────────────────
                  _ContactListTile(
                    avatarAsset: AppImages.user4,
                    handle: 'theo.vance',
                    subText: 'Theo',
                    isSelected: _selectedUserIds.contains('theo'),
                    onTap: () => _toggleUser('theo'),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Contact Item 5: kit.lumen (Disabled / Lock Icon) ──────
                  Opacity(
                    opacity: 0.4,
                    child: Row(
                      children: <Widget>[
                        ClipOval(
                          child: Image.asset(
                            AppImages.user1,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'kit.lumen',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Private account · can't receive posts",
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.lock_outline_rounded,
                          color: context.themeIconMuted,
                          size: AppSizes.iconSm,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),

            // ── Bottom Fixed Message Input & Send Button Row ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  // Reusable AppTextField Component for Message Input
                  Expanded(
                    child: AppTextField(
                      controller: _messageController,
                      hintText: l10n.sendToWriteMessageHint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message sent successfully!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradientButton,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        l10n.sendToBtn,
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactListTile extends StatelessWidget {
  const _ContactListTile({
    required this.avatarAsset,
    required this.handle,
    required this.subText,
    required this.isSelected,
    required this.onTap,
  });

  final String avatarAsset;
  final String handle;
  final String subText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            ClipOval(
              child: Image.asset(
                avatarAsset,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    handle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.gradientPink : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.gradientPink
                      : (context.isDarkMode ? Colors.white38 : AppColors.lightBorderStrong),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
