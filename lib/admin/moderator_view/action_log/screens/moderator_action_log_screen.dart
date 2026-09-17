import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/provider/admin_auth_provider.dart';
import '../../reports/provider/mod_reports_provider.dart';
import '../widgets/action_log_header.dart';
import '../widgets/action_log_table.dart';

class ModeratorActionLogScreen extends StatefulWidget {
  const ModeratorActionLogScreen({super.key});

  @override
  State<ModeratorActionLogScreen> createState() =>
      _ModeratorActionLogScreenState();
}

class _ModeratorActionLogScreenState extends State<ModeratorActionLogScreen> {
  bool _mineOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ModReportsProvider>().loadActionLog();
      }
    });
  }

  /// Reset the filter toggle and re-pull the log.
  void _refresh() {
    setState(() => _mineOnly = false);
    context.read<ModReportsProvider>().refreshActionLog();
  }

  @override
  Widget build(BuildContext context) {
    final String? myId = context.select<AdminAuthProvider, String?>(
      (AdminAuthProvider p) => p.user?.id,
    );

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ActionLogHeader(onRefresh: _refresh),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<ModReportsProvider>(
                  builder: (_, ModReportsProvider provider, _) => ActionLogTable(
                    provider: provider,
                    mineOnly: _mineOnly,
                    myId: myId,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
