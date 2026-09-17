import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../communities/models/community.dart';
import '../../communities/provider/communities_provider.dart';

class AnnouncementCommunityPicker extends StatelessWidget {
  const AnnouncementCommunityPicker({required this.selectedId, required this.onSelect, super.key});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (_, CommunitiesProvider provider, _) {
        if (provider.isLoading && provider.communities.isEmpty) {
          return const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
          );
        }
        if (provider.communities.isEmpty) {
          return const Text('No communities available.', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12));
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final Community c in provider.communities)
              AppTagChip(label: c.name, isSelected: selectedId == c.id, onTap: () => onSelect(c.id)),
          ],
        );
      },
    );
  }
}
