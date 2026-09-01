import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum SnackBarType { success, error, info }

class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    ScaffoldMessengerState? messenger,
    SnackBarType type = SnackBarType.info,
  }) {
    final ScaffoldMessengerState? targetMessenger =
        messenger ?? ScaffoldMessenger.maybeOf(context);

    if (targetMessenger == null) return;

    final bool isDark = context.isDarkMode;

    targetMessenger.hideCurrentSnackBar();

    Color badgeBg;
    Color badgeBorder;
    Widget defaultIcon;

    switch (type) {
      case SnackBarType.success:
        badgeBg = isDark
            ? const Color(0xFF0F2F34)
            : const Color(0xFFE6F8F6);
        badgeBorder = AppColors.gradientCyan.withValues(alpha: isDark ? 0.2 : 0.35);
        defaultIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppColors.gradientCyan,
          size: 18,
        );
      case SnackBarType.error:
        badgeBg = isDark
            ? const Color(0xFF331522)
            : const Color(0xFFFFE8EE);
        badgeBorder = AppColors.danger.withValues(alpha: isDark ? 0.3 : 0.4);
        defaultIcon = const Icon(
          Icons.error_outline_rounded,
          color: AppColors.danger,
          size: 18,
        );
      case SnackBarType.info:
        badgeBg = isDark
            ? const Color(0xFF192538)
            : context.themeCyanBadgeBackground;
        badgeBorder = AppColors.gradientCyan.withValues(alpha: isDark ? 0.2 : 0.35);
        defaultIcon = const Icon(
          Icons.info_outline_rounded,
          color: AppColors.gradientCyan,
          size: 18,
        );
    }

    targetMessenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF191622) : context.themeCardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : context.themeBorder,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              // Icon Badge Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeBorder),
                ),
                child: Center(
                  child: icon ?? defaultIcon,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle Column
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : context.themeTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : context.themeTextSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Right Action Button (Undo / Custom)
              if (actionLabel != null && actionLabel.isNotEmpty) ...<Widget>[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    targetMessenger.hideCurrentSnackBar();
                    onAction?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        color: AppColors.gradientCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? icon,
    Duration duration = const Duration(seconds: 4),
    ScaffoldMessengerState? messenger,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      type: SnackBarType.success,
      duration: duration,
      messenger: messenger,
    );
  }

  static void showError(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? icon,
    Duration duration = const Duration(seconds: 4),
    ScaffoldMessengerState? messenger,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      type: SnackBarType.error,
      duration: duration,
      messenger: messenger,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? icon,
    Duration duration = const Duration(seconds: 4),
    ScaffoldMessengerState? messenger,
  }) {
    show(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      type: SnackBarType.info,
      duration: duration,
      messenger: messenger,
    );
  }
}
