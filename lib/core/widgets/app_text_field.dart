import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.labelText,
    this.prefixIconPath,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.fillColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final String? prefixIconPath;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final int? maxLines;
  final int? maxLength;
  final Color? fillColor;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = context.themeIconMuted;

    Widget? finalPrefix;
    if (widget.prefixIconPath != null) {
      final bool isSvg = widget.prefixIconPath!.endsWith('.svg');
      finalPrefix = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: isSvg
            ? SvgPicture.asset(
                widget.prefixIconPath!,
                width: AppSizes.iconMd,
                height: AppSizes.iconMd,
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              )
            : Image.asset(
                widget.prefixIconPath!,
                width: AppSizes.iconMd,
                height: AppSizes.iconMd,
                color: iconColor,
                errorBuilder: (context, error, stackTrace) =>
                    widget.prefixIcon ?? const SizedBox.shrink(),
              ),
      );
    } else if (widget.prefixIcon != null) {
      finalPrefix = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: widget.prefixIcon!,
      );
    }

    Widget? finalSuffix;
    if (widget.isPassword) {
      finalSuffix = GestureDetector(
        onTap: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Image.asset(
            _obscureText ? AppIcons.hide : AppIcons.visible,
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
            color: iconColor,
            errorBuilder: (context, error, stackTrace) => Icon(
              _obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: iconColor,
              size: AppSizes.iconMd,
            ),
          ),
        ),
      );
    } else if (widget.suffixIcon != null) {
      finalSuffix = widget.suffixIcon;
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      style: AppTextStyles.inputFieldText.copyWith(
        color: context.themeTextPrimary,
      ),
      cursorColor: AppColors.gradientCyan,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTextStyles.inputHintText.copyWith(
          color: context.themeTextMuted,
        ),
        prefixText: widget.prefixText,
        prefixStyle: TextStyle(
          color: context.themeTextMuted,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: widget.fillColor ?? context.themeInputBackground,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        prefixIcon: finalPrefix,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        suffixIcon: finalSuffix,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: context.themeBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: context.themeBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: Color(0xFF00E5FF),
            width: AppSizes.borderWidthFocused,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppSizes.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: AppSizes.borderWidthFocused,
          ),
        ),
        errorStyle: AppTextStyles.inputErrorText,
      ),
    );
  }
}
