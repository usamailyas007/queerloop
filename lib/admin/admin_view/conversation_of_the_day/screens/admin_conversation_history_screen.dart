import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';
import '../widgets/cotd_history_table.dart';
import 'admin_conversation_answers_screen.dart';
import 'admin_conversation_overview_screen.dart';

enum _CotdView { history, overview, answers }

class AdminConversationHistoryScreen extends StatefulWidget {
  const AdminConversationHistoryScreen({super.key});

  @override
  State<AdminConversationHistoryScreen> createState() =>
      _AdminConversationHistoryScreenState();
}

class _AdminConversationHistoryScreenState
    extends State<AdminConversationHistoryScreen> {
  _CotdView _view = _CotdView.history;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CotdProvider>().loadHistory();
      }
    });
  }

  void _go(_CotdView view) => setState(() => _view = view);

  Future<void> _openAnswers(CotdQuestion q) async {
    await context.read<CotdProvider>().openAnswers(q);
    if (mounted) {
      _go(_CotdView.answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _CotdView.overview:
        return AdminConversationOverviewScreen(
          onOpenHistory: () => _go(_CotdView.history),
          onPublished: () => _go(_CotdView.history),
        );
      case _CotdView.answers:
        return AdminConversationAnswersScreen(
          onBack: () => _go(_CotdView.history),
          onPublishNew: () => _go(_CotdView.overview),
        );
      case _CotdView.history:
        return _buildHistory(context);
    }
  }

  Widget _buildHistory(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Conversation of the day /',
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
                          'History',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Every question that's gone live, with how it performed",
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
                      hintText: 'Search past questions',
                      prefixIconPath: AdminIcons.search,
                      fillColor: AppColors.adminSurface,
                      onChanged: (String v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 170,
                    height: 44,
                    child: AppGradientButton(
                      text: 'Publish new question',
                      textStyle: const TextStyle(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: () => _go(_CotdView.overview),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<CotdProvider>(
                  builder: (_, CotdProvider provider, _) => CotdHistoryTable(
                    provider: provider,
                    search: _search,
                    onOpenAnswers: _openAnswers,
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
