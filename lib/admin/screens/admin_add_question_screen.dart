import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_tag_chip.dart';
import '../../core/widgets/app_text_field.dart';

class AdminAddQuestionScreen extends StatefulWidget {
  const AdminAddQuestionScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<AdminAddQuestionScreen> createState() =>
      _AdminAddQuestionScreenState();
}

class _AdminAddQuestionScreenState extends State<AdminAddQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  int _audienceIndex = 0;

  static const List<String> _audiences = <String>['Everyone', 'One community'];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
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
                          'Conversation of the day /',
                          style: TextStyle(
                            color: Color(0xFF635C72),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Publish new question',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: const Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 40,
                      backgroundColor: const Color(0xFF1C1824),
                      onPressed: widget.onBack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                width: 440,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: const Color(0xFF141119),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Question',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _questionController,
                      hintText: "What's a queer joy moment from this week?",
                      fillColor: const Color(0xFF1C1824),
                      maxLines: 2,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Audience',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        for (int i = 0; i < _audiences.length; i++) ...<Widget>[
                          if (i > 0) const SizedBox(width: 8),
                          AppTagChip(
                            label: _audiences[i],
                            isSelected: _audienceIndex == i,
                            onTap: () => setState(() => _audienceIndex = i),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Cancel',
                            backgroundColor: const Color(0xFF1C1824),
                            onPressed: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Publish',
                            onPressed: widget.onBack,
                          ),
                        ),
                      ],
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
}
