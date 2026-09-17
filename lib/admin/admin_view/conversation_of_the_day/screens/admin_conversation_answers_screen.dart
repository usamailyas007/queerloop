import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';
import '../widgets/cotd_answers_table.dart';

class AdminConversationAnswersScreen extends StatefulWidget {
  const AdminConversationAnswersScreen({
    required this.onBack,
    required this.onPublishNew,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onPublishNew;

  @override
  State<AdminConversationAnswersScreen> createState() =>
      _AdminConversationAnswersScreenState();
}

class _AdminConversationAnswersScreenState
    extends State<AdminConversationAnswersScreen> {
  void _onError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<CotdProvider>().clearAnswersError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Consumer<CotdProvider>(
            builder: (_, CotdProvider provider, _) {
              final CotdQuestion? question = provider.selectedQuestion;
              if (provider.answersError != null && provider.answers.isNotEmpty) {
                _onError(provider.answersError!);
              }

              return Column(
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
                        child: Text(
                          'Answers',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: AppOutlineButton(
                          text: 'History',
                          height: 44,
                          backgroundColor: AppColors.adminSurfaceAlt,
                          onPressed: widget.onBack,
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
                          onPressed: widget.onPublishNew,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.adminBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            question == null ? 'Answers' : "Answers · '${question.question}'",
                            style: const TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Shown to users as comments under the question',
                            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Expanded(child: CotdAnswersTable(provider: provider)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
