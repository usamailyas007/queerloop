import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';

class AdminConversationOverviewScreen extends StatefulWidget {
  const AdminConversationOverviewScreen({
    required this.onOpenHistory,
    required this.onPublished,
    super.key,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onPublished;

  @override
  State<AdminConversationOverviewScreen> createState() =>
      _AdminConversationOverviewScreenState();
}

class _AdminConversationOverviewScreenState
    extends State<AdminConversationOverviewScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CotdProvider>().loadHistory();
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final CotdProvider provider = context.read<CotdProvider>();
    final CotdQuestion? created =
        await provider.publishQuestion(_questionController.text);
    if (!mounted) {
      return;
    }
    if (created != null) {
      _questionController.clear();
      _snack('Published “${created.question}” to everyone.');
      widget.onPublished();
    } else {
      _snack(provider.historyError ?? 'Could not publish the question.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool publishing = context.select<CotdProvider, bool>(
      (CotdProvider p) => p.isPublishing,
    );

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Conversation of the day',
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
                      onPressed: publishing ? () {} : widget.onOpenHistory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 11, child: _composer(publishing)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(flex: 10, child: _livePanel()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(bool publishing) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "Today's question",
            style: TextStyle(
              color: AppColors.adminTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Question',
            style: TextStyle(color: AppColors.adminTextPrimary, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: _questionController,
            enabled: !publishing,
            hintText: "What's a small moment that made you feel truly seen?",
            fillColor: AppColors.adminSurfaceAlt,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 259,
              height: 44,
              child: AppGradientButton(
                text: 'Publish to everyone',
                isLoading: publishing,
                textStyle: const TextStyle(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                onPressed: publishing ? () {} : _publish,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _livePanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Consumer<CotdProvider>(
        builder: (_, CotdProvider provider, _) {
          final CotdQuestion? live = provider.liveQuestion;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Live now',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          live == null
                              ? 'Nothing is live'
                              : '${NumberFormat.decimalPattern().format(live.answerCount)} answers so far',
                          style: const TextStyle(
                            color: AppColors.adminTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (live != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.adminTeal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.adminTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: AppColors.adminTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(19),
                decoration: BoxDecoration(
                  color: AppColors.adminSurfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.adminHighlightBorder.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "TODAY'S QUESTION",
                      style: TextStyle(
                        color: AppColors.adminTextMuted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      live?.question ?? '—',
                      style: const TextStyle(
                        color: AppColors.adminTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Recent questions',
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              for (final CotdQuestion q
                  in provider.history.where((CotdQuestion q) => !q.isLive).take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          q.question,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        '${NumberFormat.compact().format(q.answerCount)} answers',
                        style: const TextStyle(
                          color: AppColors.adminTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
