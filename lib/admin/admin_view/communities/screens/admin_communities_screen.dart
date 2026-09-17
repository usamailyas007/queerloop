import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../provider/communities_provider.dart';
import '../widgets/communities_table.dart';
import 'admin_add_community_screen.dart';

class AdminCommunitiesScreen extends StatefulWidget {
  const AdminCommunitiesScreen({super.key});

  @override
  State<AdminCommunitiesScreen> createState() => _AdminCommunitiesScreenState();
}

class _AdminCommunitiesScreenState extends State<AdminCommunitiesScreen> {
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunitiesProvider>().loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return AdminAddCommunityScreen(
        onBack: () => setState(() => _isAdding = false),
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
                          'Communities',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Selector<CommunitiesProvider, (int, bool)>(
                          selector: (_, CommunitiesProvider p) => (p.count, p.isLoading),
                          builder: (_, (int, bool) data, _) {
                            final (int count, bool loading) = data;
                            return Text(
                              loading && count == 0
                                  ? 'Loading…'
                                  : '$count group${count == 1 ? '' : 's'} · '
                                      'each becomes a tab in the app',
                              style: const TextStyle(
                                color: AppColors.adminTextSecondary,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: AppGradientButton(
                      text: 'Add community',
                      height: 44,
                      onPressed: () => setState(() => _isAdding = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<CommunitiesProvider>(
                  builder: (_, CommunitiesProvider provider, _) =>
                      CommunitiesTable(provider: provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
