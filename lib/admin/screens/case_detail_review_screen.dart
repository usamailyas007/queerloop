import 'package:flutter/material.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';

class CaseDetailReviewScreen extends StatefulWidget {
  const CaseDetailReviewScreen({
    this.caseId = 'QL-84213',
    this.reason = 'Harassment',
    this.reportedBy = '@ashinorbit',
    this.reportedUser = '@dg_returns',
    this.onBack,
    super.key,
  });

  final String caseId;
  final String reason;
  final String reportedBy;
  final String reportedUser;
  final VoidCallback? onBack;

  @override
  State<CaseDetailReviewScreen> createState() => _CaseDetailReviewScreenState();
}

class _CaseDetailReviewScreenState extends State<CaseDetailReviewScreen> {
  int _selectedDecisionIndex = 1; // Default to Option 2: Warn the account
  final TextEditingController _noteController = TextEditingController();

  final List<_DecisionOption> _decisionOptions = const <_DecisionOption>[
    _DecisionOption(
      title: 'Hide the content',
      subtitle: 'Removed from all feeds',
    ),
    _DecisionOption(
      title: 'Warn the account',
      subtitle: 'Second warning → 7-day suspension',
    ),
    _DecisionOption(
      title: 'Mute for 7 days',
      subtitle: "Can read, can't post",
    ),
    _DecisionOption(
      title: 'Escalate to admin',
      subtitle: 'For bans and legal cases',
    ),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildTopButton(String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF191622),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121019),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Bar ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.caseId,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.reason} · reported 14 hours ago by ${widget.reportedBy}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildTopButton('Skip'),
                  const SizedBox(width: 8),
                  _buildTopButton('Previous', onTap: widget.onBack),
                  const SizedBox(width: 8),
                  _buildTopButton('Next'),
                ],
              ),
            ),

            // ── Main 2 Column Content ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Left Column: Reported Content & Thread Context ──────
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16131D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Reported content',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Content Card
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D1927),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        ClipOval(
                                          child: Image.asset(
                                            AppImages.user1,
                                            width: 38,
                                            height: 38,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                widget.reportedUser,
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                "Comment on @rowankeeps' video · 2 Aug 21:14",
                                                style: TextStyle(
                                                  color: Colors.white38,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Comment',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      '"honestly nobody asked, go be miserable somewhere else"',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              Text(
                                'Thread context',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Context Inset 1
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                margin:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D1927),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  '@rowankeeps · "Six months post-op. Read the caption before you comment 🤍"',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              // Context Inset 2
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D1927),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  '@jules.does · "Six months looks so good on you."',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xl),

                    // ── Right Column: Account History & Decision ─────────────
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16131D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Account History Section
                              Text(
                                'Account history · ${widget.reportedUser}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const <Widget>[
                                  Text('Joined',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                  Text('11 Mar 2026',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const <Widget>[
                                  Text('Reports against',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                  Text('6 in 30 days',
                                      style: TextStyle(
                                          color: Color(0xFFFF4B8B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const <Widget>[
                                  Text('Previous actions',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                  Text('1 warning · 1 comment removed',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const <Widget>[
                                  Text('Blocked by',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 12)),
                                  Text('23 people',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Decision Section
                              Text(
                                'Decision',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Decision Radio Options
                              for (int i = 0; i < _decisionOptions.length; i++)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedDecisionIndex = i),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: AppSpacing.sm),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.md - 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D1927),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedDecisionIndex == i
                                            ? const Color(0xFFFF4B8B)
                                            : Colors.white
                                                .withValues(alpha: 0.08),
                                        width:
                                            _selectedDecisionIndex == i ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          _decisionOptions[i].title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                _selectedDecisionIndex == i
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          _decisionOptions[i].subtitle,
                                          style: TextStyle(
                                            color: _selectedDecisionIndex == i
                                                ? const Color(0xFFFF4B8B)
                                                : Colors.white38,
                                            fontSize: 12,
                                            fontWeight:
                                                _selectedDecisionIndex == i
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: AppSpacing.md),

                              // Note for the log input field using AppTextField
                              AppTextField(
                                controller: _noteController,
                                hintText: 'Note for the log (required)',
                                fillColor: const Color(0xFF1D1927),
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Bottom Buttons Row
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: widget.onBack,
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D1927),
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'No action needed',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: widget.onBack,
                                      child: Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: <Color>[
                                              Color(0xFFFF4B8B),
                                              Color(0xFF9D4EDD),
                                              Color(0xFF00E5FF),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(23),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                              color: const Color(0xFFFF4B8B)
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Apply decision',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _DecisionOption {
  const _DecisionOption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
