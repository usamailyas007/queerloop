import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../provider/moderators_provider.dart';
import '../widgets/moderators_table.dart';
import 'admin_invite_moderator_screen.dart';

class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({super.key});

  @override
  State<AdminModeratorsScreen> createState() => _AdminModeratorsScreenState();
}

class _AdminModeratorsScreenState extends State<AdminModeratorsScreen> {
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ModeratorsProvider>().loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInviting) {
      return AdminInviteModeratorScreen(
        onBack: () => setState(() => _isInviting = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Moderators',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Selector<ModeratorsProvider, (int, int, bool)>(
                          selector: (_, ModeratorsProvider p) =>
                              (p.activeCount, p.pendingCount, p.isLoading),
                          builder: (_, (int, int, bool) data, _) {
                            final (int active, int pending, bool loading) = data;
                            return Text(
                              loading && active == 0 && pending == 0
                                  ? 'Loading…'
                                  : '$active active${pending > 0 ? ' · $pending pending' : ''}',
                              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 170,
                    child: AppGradientButton(
                      text: 'Invite moderator',
                      height: 44,
                      onPressed: () => setState(() => _isInviting = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<ModeratorsProvider>(
                  builder: (_, ModeratorsProvider provider, _) => ModeratorsTable(provider: provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
