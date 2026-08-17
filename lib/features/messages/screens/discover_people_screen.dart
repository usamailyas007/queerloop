import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';
import 'chat_screen.dart';
import '../../profile/screens/user_profile_screen.dart';

class DiscoverPeopleScreen extends StatefulWidget {
  const DiscoverPeopleScreen({super.key});

  @override
  State<DiscoverPeopleScreen> createState() => _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends State<DiscoverPeopleScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<ConversationModel> _peopleYouFollow = <ConversationModel>[
    ConversationModel(
      id: 'c4',
      username: 'theo.vance',
      avatarAsset: AppImages.user4,
      lastMessage: 'You follow each other',
      timeAgo: '',
    ),
    ConversationModel(
      id: 'c2',
      username: 'rowankeeps',
      avatarAsset: AppImages.user1,
      lastMessage: 'You follow each other',
      timeAgo: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final MessagesProvider provider = context.watch<MessagesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Top Header Bar (Back button + Title "Discover people") ─────────
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Discover people',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Search Input Field ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Search by name or @username',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── PEOPLE YOU FOLLOW Section Header ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'PEOPLE YOU FOLLOW',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── List of People ─────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _peopleYouFollow.length,
                itemBuilder: (BuildContext context, int index) {
                  final ConversationModel person = _peopleYouFollow[index];

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        // Avatar & Info (Tap -> Open UserProfileScreen)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => UserProfileScreen(
                                    username: person.username,
                                    name: person.username.split('.').first,
                                    avatarAsset: person.avatarAsset,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Image.asset(
                                    person.avatarAsset,
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
                                        person.username,
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        person.lastMessage,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: Colors.white54,
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

                        const SizedBox(width: AppSpacing.md),

                        // Pink Message Button
                        AppGradientButton(
                          text: 'Message',
                          height: 32,
                          width: 84,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ChangeNotifierProvider<MessagesProvider>.value(
                                  value: provider,
                                  child: ChatScreen(conversation: person),
                                ),
                              ),
                            );
                          },
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
