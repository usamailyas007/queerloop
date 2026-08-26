import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CustomGradientSwitch extends StatelessWidget {
  const CustomGradientSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 48,
        height: 26,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: value ? AppColors.primaryGradientButton : null,
          color: value
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white),
          border: value
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : context.themeBorder,
                  width: 1.2,
                ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? Colors.white
                  : (isDark ? const Color(0xFF8E8B98) : const Color(0xFF64748B)),
              boxShadow: value
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
