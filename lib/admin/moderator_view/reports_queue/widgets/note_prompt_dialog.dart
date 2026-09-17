import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'wide_button.dart';

/// Themed text-note prompt used for actions like "Reopen report".
class NotePromptDialog extends StatefulWidget {
  const NotePromptDialog({required this.title, required this.subtitle, required this.hint, required this.confirmLabel, super.key});

  final String title;
  final String subtitle;
  final String hint;
  final String confirmLabel;

  @override
  State<NotePromptDialog> createState() => _NotePromptDialogState();
}

class _NotePromptDialogState extends State<NotePromptDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int len = _controller.text.trim().length;
    final bool valid = len >= 1 && len <= 1000;
    final bool focused = _focusNode.hasFocus;

    return Dialog(
      backgroundColor: AppColors.moderatorSurface,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.moderatorBorder)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.title,
                style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: AppColors.moderatorSurfaceAlt2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focused ? AppColors.gradientCyan : AppColors.moderatorInputBorder,
                    width: focused ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  cursorColor: AppColors.gradientCyan,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppColors.moderatorTextPrimary, fontSize: 14, height: 1.4),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(color: AppColors.moderatorTextFaint),
                    counterText: '',
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text('$len / 1000', style: const TextStyle(color: AppColors.moderatorTextFaint, fontSize: 11)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(child: WideButton(label: 'Cancel', onTap: () => Navigator.pop(context))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: WideButton(
                      label: widget.confirmLabel,
                      gradient: true,
                      onTap: valid ? () => Navigator.pop(context, _controller.text.trim()) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
