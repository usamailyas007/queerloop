import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../widgets/admin_field_label.dart';
import '../models/announcement.dart';
import 'announcement_card.dart';
import 'announcement_community_picker.dart';

class AnnouncementComposeCard extends StatelessWidget {
  const AnnouncementComposeCard({
    required this.titleController,
    required this.messageController,
    required this.audience,
    required this.onAudienceChanged,
    required this.communityId,
    required this.onCommunitySelected,
    required this.sending,
    required this.onSend,
    super.key,
  });

  final TextEditingController titleController;
  final TextEditingController messageController;
  final AnnouncementAudience audience;
  final ValueChanged<AnnouncementAudience> onAudienceChanged;
  final String? communityId;
  final ValueChanged<String> onCommunitySelected;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return AnnouncementCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AnnouncementCardTitle('Compose'),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: titleController,
              enabled: !sending,
              hintText: 'Title',
              fillColor: AppColors.adminSurfaceAlt,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: messageController,
              enabled: !sending,
              hintText: 'Message',
              fillColor: AppColors.adminSurfaceAlt,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AdminFieldLabel('Audience', bottomSpacing: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final AnnouncementAudience a in AnnouncementAudience.values)
                  AppTagChip(
                    label: a.label,
                    isSelected: audience == a,
                    onTap: sending ? null : () => onAudienceChanged(a),
                  ),
              ],
            ),
            if (audience == AnnouncementAudience.community) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              const AdminFieldLabel('Community', bottomSpacing: AppSpacing.sm),
              AnnouncementCommunityPicker(selectedId: communityId, onSelect: onCommunitySelected),
            ],
            const SizedBox(height: AppSpacing.xxl),
            AppGradientButton(text: 'Send', isLoading: sending, onPressed: sending ? () {} : onSend),
          ],
        ),
      ),
    );
  }
}
