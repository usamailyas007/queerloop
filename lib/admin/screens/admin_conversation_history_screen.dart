import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_icons.dart';
import 'admin_conversation_answers_screen.dart';
import 'admin_conversation_overview_screen.dart';

class ConversationQuestion {
  const ConversationQuestion({
    required this.question,
    required this.sentLive,
    required this.answers,
    required this.topAnswerLikes,
    required this.reports,
    required this.isLive,
  });

  final String question;
  final String sentLive;
  final int answers;
  final int topAnswerLikes;
  final int reports;
  final bool isLive;
}

enum _ConversationView { overview, history, answers }

class AdminConversationHistoryScreen extends StatefulWidget {
  const AdminConversationHistoryScreen({super.key});

  @override
  State<AdminConversationHistoryScreen> createState() =>
      _AdminConversationHistoryScreenState();
}

class _AdminConversationHistoryScreenState
    extends State<AdminConversationHistoryScreen> {
  _ConversationView _view = _ConversationView.overview;
  ConversationQuestion? _selectedQuestion;
  String _searchQuery = '';

  static const List<ConversationQuestion> _questions = <ConversationQuestion>[
    ConversationQuestion(
      question: 'What does chosen family mean to you?',
      sentLive: '2 Aug',
      answers: 2140,
      topAnswerLikes: 412,
      reports: 0,
      isLive: true,
    ),
    ConversationQuestion(
      question: "What's a small act of pride you did today?",
      sentLive: '1 Aug',
      answers: 1804,
      topAnswerLikes: 296,
      reports: 1,
      isLive: false,
    ),
    ConversationQuestion(
      question: 'Who was your first queer friend?',
      sentLive: '31 Jul',
      answers: 2612,
      topAnswerLikes: 530,
      reports: 0,
      isLive: false,
    ),
    ConversationQuestion(
      question: 'What song makes you feel most yourself?',
      sentLive: '30 Jul',
      answers: 3108,
      topAnswerLikes: 601,
      reports: 0,
      isLive: false,
    ),
    ConversationQuestion(
      question: "What's one thing you wish people asked instead of assumed?",
      sentLive: '29 Jul',
      answers: 2977,
      topAnswerLikes: 488,
      reports: 4,
      isLive: false,
    ),
    ConversationQuestion(
      question: 'Where do you feel safest being fully yourself?',
      sentLive: '28 Jul',
      answers: 2340,
      topAnswerLikes: 377,
      reports: 0,
      isLive: false,
    ),
    ConversationQuestion(
      question: "What's a queer joy moment from this week?",
      sentLive: '27 Jul',
      answers: 1996,
      topAnswerLikes: 340,
      reports: 0,
      isLive: false,
    ),
  ];

  void _openAnswers(ConversationQuestion question) {
    setState(() {
      _selectedQuestion = question;
      _view = _ConversationView.answers;
    });
  }

  void _openOverview() {
    setState(() => _view = _ConversationView.overview);
  }

  void _openHistory() {
    setState(() => _view = _ConversationView.history);
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _ConversationView.overview:
        return AdminConversationOverviewScreen(
          liveQuestion: _questions.first,
          onOpenHistory: _openHistory,
        );
      case _ConversationView.answers:
        return AdminConversationAnswersScreen(
          question: _selectedQuestion!,
          onBack: _openHistory,
          onPublishNew: _openOverview,
        );
      case _ConversationView.history:
        return _buildHistory();
    }
  }

  Widget _buildHistory() {
    final List<ConversationQuestion> filtered = _questions
        .where(
          (ConversationQuestion q) =>
              _searchQuery.isEmpty ||
              q.question.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Conversation of the day /',
                style: TextStyle(color: Color(0xFF635C72), fontSize: 12),
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
                            color: Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Every question that's ever gone live, with how it performed",
                          style: TextStyle(
                            color: Color(0xFF948CA3),
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
                      fillColor: const Color(0xFF141119),
                      onChanged: (String val) =>
                          setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 90,
                    child: AppOutlineButton(
                      text: 'History',
                      height: 44,
                      backgroundColor: const Color(0xFF1C1824),
                      onPressed: _openHistory,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 160,
                    height: 44,
                    child: AppGradientButton(
                      text: 'Publish new question',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: _openOverview,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141119),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md - 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Expanded(flex: 4, child: _Header('QUESTION')),
                          Expanded(flex: 2, child: _Header('SENT LIVE')),
                          Expanded(flex: 2, child: _Header('ANSWERS')),
                          Expanded(
                            flex: 2,
                            child: _Header('TOP ANSWER LIKES'),
                          ),
                          Expanded(flex: 1, child: _Header('REPORTS')),
                          Expanded(flex: 2, child: _Header('STATUS')),
                          SizedBox(width: 90),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      itemBuilder: (_, int index) {
                        final ConversationQuestion q = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 4,
                                child: Text(
                                  q.question,
                                  style: const TextStyle(
                                    color: Color(0xFFF3EFF7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  q.sentLive,
                                  style: const TextStyle(
                                    color: Color(0xFF948CA3),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  NumberFormat.decimalPattern()
                                      .format(q.answers),
                                  style: const TextStyle(
                                    color: Color(0xFF948CA3),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  NumberFormat.decimalPattern()
                                      .format(q.topAnswerLikes),
                                  style: const TextStyle(
                                    color: Color(0xFF948CA3),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${q.reports}',
                                  style: TextStyle(
                                    color: q.reports > 0
                                        ? const Color(0xFFFFB45C)
                                        : const Color(0xFF948CA3),
                                    fontWeight: q.reports > 0
                                        ? FontWeight.w700
                                        : FontWeight.w400,
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
                                      color:
                                          (q.isLive
                                                  ? const Color(0xFF3FE0AE)
                                                  : const Color(0xFF948CA3))
                                              .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            (q.isLive
                                                    ? const Color(0xFF3FE0AE)
                                                    : const Color(0xFF948CA3))
                                                .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      q.isLive ? 'Live' : 'Ended',
                                      style: TextStyle(
                                        color: q.isLive
                                            ? const Color(0xFF3FE0AE)
                                            : const Color(0xFF948CA3),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 90,
                                child: GestureDetector(
                                  onTap: () => _openAnswers(q),
                                  child: const Text(
                                    'View answers',
                                    style: TextStyle(
                                      color: Color(0xFF4CC9FF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Showing ${filtered.length} of 66 questions',
                            style: const TextStyle(
                              color: Color(0xFF635C72),
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              _pageButton('Previous'),
                              const SizedBox(width: 8),
                              _pageButton('Next'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1824),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF948CA3),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
        color: Color(0xFF635C72),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
