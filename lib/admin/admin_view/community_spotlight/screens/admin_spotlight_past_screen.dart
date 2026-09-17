import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../models/spotlight.dart';
import '../provider/spotlights_provider.dart';
import '../widgets/spotlight_grid.dart';
import '../widgets/spotlight_preview_dialog.dart';

class AdminSpotlightPastScreen extends StatefulWidget {
  const AdminSpotlightPastScreen({
    required this.onNew,
    required this.onEdit,
    super.key,
  });

  final VoidCallback onNew;
  final ValueChanged<Spotlight> onEdit;

  @override
  State<AdminSpotlightPastScreen> createState() =>
      _AdminSpotlightPastScreenState();
}

class _AdminSpotlightPastScreenState extends State<AdminSpotlightPastScreen> {
  void _onError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<SpotlightsProvider>().clearError();
    });
  }

  Future<void> _rerun(Spotlight s) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.adminSurfaceAlt,
            title: const Text('Re-run spotlight?',
                style: TextStyle(color: AppColors.adminTextPrimary)),
            content: Text(
              '“${s.title}” will be published again as this week\'s spotlight.',
              style: const TextStyle(color: AppColors.adminTextSecondary),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Re-run'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      await context.read<SpotlightsProvider>().rerunSpotlight(s.id);
    }
  }

  void _view(Spotlight s) =>
      showSpotlightPreviewDialog(context, s, onEdit: widget.onEdit, onRerun: _rerun);

  Future<void> _delete(Spotlight s) =>
      context.read<SpotlightsProvider>().deleteSpotlight(s.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Community spotlight /',
                style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Past spotlights',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Every weekly pick, with reach and click-through',
                          style: TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: AppTextField(
                      hintText: 'Search past spotlights',
                      prefixIconPath: AdminIcons.search,
                      fillColor: AppColors.adminSurface,
                      onChanged: (String v) => context.read<SpotlightsProvider>().setSearch(v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 130,
                    height: 44,
                    child: AppGradientButton(
                      text: 'New spotlight',
                      textStyle: const TextStyle(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: widget.onNew,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<SpotlightsProvider>(
                  builder: (_, SpotlightsProvider provider, _) {
                    if (provider.error != null && provider.spotlights.isNotEmpty) {
                      _onError(provider.error!);
                    }
                    return SpotlightGrid(
                      provider: provider,
                      onView: _view,
                      onEdit: widget.onEdit,
                      onRerun: _rerun,
                      onDelete: _delete,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
