import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../provider/admin_auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: '',
  );
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await context.read<AdminAuthProvider>().signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -520,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                child: Container(
                  width: 1728,
                  height: 1192,
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.6,
                      colors: <Color>[
                        AppColors.adminPinkGlow,
                        AppColors.adminPinkTransparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 90),
                  decoration: BoxDecoration(
                    color: AppColors.adminSurface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.adminCardBorderStrong),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 90,
                        offset: const Offset(0, 40),
                        spreadRadius: -30,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Image.asset(AppImages.logo, width: 76, height: 29),
                          const SizedBox(height: 13),
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              letterSpacing: -0.48,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter your email and password to continue.',
                            style: TextStyle(
                              color: AppColors.adminTextFaint,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Selector<AdminAuthProvider, bool>(
                            selector: (_, AdminAuthProvider p) => p.isBusy,
                            builder: (_, bool busy, _) => AppTextField(
                              controller: _emailController,
                              enabled: !busy,
                              hintText: 'you@queerloop.app',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              fillColor: AppColors.adminRowDivider,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: AppColors.adminTextFaint,
                                size: 17,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Selector<AdminAuthProvider, bool>(
                            selector: (_, AdminAuthProvider p) => p.isBusy,
                            builder: (_, bool busy, _) => AppTextField(
                              controller: _passwordController,
                              enabled: !busy,
                              hintText: 'Enter your password',
                              isPassword: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              fillColor: AppColors.adminRowDivider,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.adminTextFaint,
                                size: 17,
                              ),
                            ),
                          ),

                          // ── Error banner — only this rebuilds on error ────
                          Selector<AdminAuthProvider, String?>(
                            selector: (_, AdminAuthProvider p) => p.error,
                            builder: (_, String? error, _) {
                              if (error == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 22),
                          Selector<AdminAuthProvider, bool>(
                            selector: (_, AdminAuthProvider p) => p.isBusy,
                            builder: (_, bool busy, _) => AppGradientButton(
                              text: 'Sign in →',
                              isLoading: busy,
                              shimmerLabelWhileLoading: true,
                              height: 48,
                              borderRadius: BorderRadius.circular(13),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: <Color>[
                                  AppColors.adminPink,
                                  AppColors.adminPurple,
                                ],
                              ),
                              textStyle: const TextStyle(
                                color: AppColors.textInverse,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: -0.14,
                              ),
                              onPressed: busy ? () {} : _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
