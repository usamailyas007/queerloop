// Builds the ThemeData for the user app and the admin console.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get app => dark;

  static ThemeData get dark => _buildTheme(
        scaffoldBackground: AppColors.background,
        cardBackground: AppColors.cardBackground,
        textPrimary: Colors.white,
        textSecondary: Colors.white70,
        textMuted: Colors.white54,
        borderColor: Colors.white12,
        dividerColor: AppColors.divider,
        brightness: Brightness.dark,
      );

  static ThemeData get light => _buildTheme(
        scaffoldBackground: AppColors.lightBackground,
        cardBackground: AppColors.lightCardBackground,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textMuted: AppColors.lightTextMuted,
        borderColor: AppColors.lightBorder,
        dividerColor: AppColors.lightDivider,
        brightness: Brightness.light,
      );

  static ThemeData get admin => _buildTheme(
        scaffoldBackground: AppColors.surfaceAlt,
        cardBackground: AppColors.adminSurface,
        textPrimary: AppColors.adminTextPrimary,
        textSecondary: AppColors.adminTextSecondary,
        textMuted: AppColors.adminTextMuted,
        borderColor: AppColors.adminBorder,
        dividerColor: AppColors.adminDivider,
        brightness: Brightness.dark,
      );

  static ThemeData _buildTheme({
    required Color scaffoldBackground,
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color borderColor,
    required Color dividerColor,
    required Brightness brightness,
  }) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: cardBackground,
      onSurface: textPrimary,
      surfaceContainerHighest:
          isDark ? AppColors.chipBackground : AppColors.lightChipBackground,
      outline: borderColor,
      outlineVariant:
          isDark ? Colors.white24 : AppColors.lightBorderStrong,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'HankenGrotesk',
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: scaffoldBackground,
      dialogTheme: DialogThemeData(
        backgroundColor: scaffoldBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerColor: dividerColor,

      // Smooth Page Transitions with Zero White Flicker
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.bottomSheetBackground
            : AppColors.lightBottomSheetBackground,
        modalBackgroundColor: isDark
            ? AppColors.bottomSheetBackground
            : AppColors.lightBottomSheetBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: textPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: textPrimary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textMuted),
        labelLarge: AppTextStyles.label.copyWith(color: textPrimary),
        labelSmall: AppTextStyles.caption.copyWith(color: textMuted),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textPrimary,
        elevation: AppSpacing.none,
        centerTitle: true,
        toolbarHeight: AppSizes.appBarHeight,
        titleTextStyle: AppTextStyles.titleSmall.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: AppSizes.dividerThickness,
        space: AppSizes.dividerThickness,
      ),

      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: AppSpacing.none,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: borderColor,
            width: AppSizes.borderWidth,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: textMuted,
          elevation: AppSpacing.none,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          textStyle: AppTextStyles.label,
          side: BorderSide(
            color: borderColor,
            width: AppSizes.borderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1E1B26)
            : AppColors.lightInputBackground,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: textMuted),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: borderColor,
            width: AppSizes.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(
            color: borderColor,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppSizes.borderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
    );
  }
}
