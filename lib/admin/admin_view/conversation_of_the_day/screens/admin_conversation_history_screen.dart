import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';
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
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.adminSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.adminBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      const _HistoryHeaderRow(),
                      Expanded(
                        child: Consumer<CotdProvider>(
                          builder: (_, CotdProvider provider, _) => _HistoryBody(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.provider,
    required this.search,
    required this.onOpenAnswers,
  });

  final CotdProvider provider;
  final String search;
  final ValueChanged<CotdQuestion> onOpenAnswers;

  static final DateFormat _date = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingHistory && provider.history.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.adminPink,
          ),
        ),
      );
    }
    if (provider.historyError != null && provider.history.isEmpty) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.historyError!,
        onRetry: provider.refreshHistory,
      );
    }
    if (provider.isHistoryEmpty) {
      return const _CenteredMessage(
        icon: Icons.forum_outlined,
        message: 'No questions published yet.',
      );
    }

    final List<CotdQuestion> items = provider.history
        .where((CotdQuestion q) =>
            search.isEmpty ||
            q.question.toLowerCase().contains(search.toLowerCase()))
        .toList();

    if (items.isEmpty) {
      return const _CenteredMessage(
        icon: Icons.search_off_rounded,
        message: 'No questions match your search.',
      );
    }

    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refreshHistory,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (_, int index) {
          final CotdQuestion q = items[index];
          final Color chip =
              q.isLive ? AppColors.adminTeal : AppColors.adminTextSecondary;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      q.question,
                      style: const TextStyle(
                        color: AppColors.adminTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _date.format(q.publishedAt),
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormat.decimalPattern().format(q.answerCount),
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '${q.reports}',
                    style: TextStyle(
                      color: q.reports > 0
                          ? AppColors.adminOrange
                          : AppColors.adminTextSecondary,
                      fontWeight:
                          q.reports > 0 ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: chip.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: chip.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        q.status.label,
                        style: TextStyle(
                          color: chip,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 116,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onOpenAnswers(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurfaceAlt,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.adminBorder),
                        ),
                        child: const Text(
                          'View answers',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryHeaderRow extends StatelessWidget {
  const _HistoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 4, child: _Header('QUESTION')),
          Expanded(flex: 2, child: _Header('PUBLISHED')),
          Expanded(flex: 2, child: _Header('ANSWERS')),
          Expanded(flex: 1, child: _Header('REPORTS')),
          Expanded(flex: 2, child: _Header('STATUS')),
          SizedBox(width: 116),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppColors.adminTextMuted, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 120,
              child: AppOutlineButton(
                text: 'Retry',
                height: 38,
                onPressed: onRetry!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.adminTextMuted,
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
