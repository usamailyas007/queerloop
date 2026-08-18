import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_spacing.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    required this.label,
    required this.value,
    super.key,
    this.iconPath,
    this.iconColor = const Color(0xFF8B5CFF),
    this.valueColor = const Color(0xFFF3EFF7),
    this.delta,
    this.deltaColor = const Color(0xFF3FE0AE),
  });

  final String label;
  final String value;
  final String? iconPath;
  final Color iconColor;
  final Color valueColor;
  final String? delta;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 117,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141119),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF635C72),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              if (iconPath != null)
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    iconPath!,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.64,
            ),
          ),
          if (delta != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              delta!,
              style: TextStyle(
                color: deltaColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
