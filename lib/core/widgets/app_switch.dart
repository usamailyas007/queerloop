import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.width = 48.0,
    this.height = 26.0,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: value ? AppColors.secondaryGradientButton : null,
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
            width: height - 5.0,
            height: height - 5.0,
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
