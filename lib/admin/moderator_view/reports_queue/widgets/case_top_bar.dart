import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin_view/widgets/admin_badge.dart';
import '../../reports/models/mod_report.dart';

/// Case id + reason/status line + "Back to queue" button.
class CaseTopBar extends StatelessWidget {
  const CaseTopBar({required this.report, required this.onBack, super.key});

  final ModReport report;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    report.displayId,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.moderatorTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (report.badge != ReportBadge.none)
                    AdminBadge(text: report.badge.label, color: report.badge.color),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${report.reasonLabel} · ${report.status.label} · reported ${_ago(report.createdAt)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.moderatorTextMuted, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          TopBarButton(label: 'Back to queue', onTap: onBack),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class TopBarButton extends StatelessWidget {
  const TopBarButton({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.moderatorSurfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.moderatorInputBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
