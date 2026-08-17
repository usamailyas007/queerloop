import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
    Widget? icon,
    String? actionLabel = 'Undo',
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    ScaffoldMessengerState? messenger,
  }) {
    final ScaffoldMessengerState? targetMessenger =
        messenger ?? ScaffoldMessenger.maybeOf(context);

    if (targetMessenger == null) return;

    targetMessenger.hideCurrentSnackBar();

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
            color: const Color(0xFF191622),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
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
                  color: const Color(0xFF0F2F34),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gradientCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: icon ??
                      const Icon(
                        Icons.block_rounded,
                        color: AppColors.gradientCyan,
                        size: 18,
                      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
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
}
