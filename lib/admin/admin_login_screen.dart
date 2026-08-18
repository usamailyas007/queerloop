import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_images.dart';
import '../core/widgets/app_gradient_button.dart';
import '../core/widgets/app_text_field.dart';
import 'admin_auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController =
      TextEditingController(text: 'you@queerloop.app');
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AdminAuthProvider>().signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: Stack(
        children: <Widget>[
          // Soft pink glow behind the card, top-center.
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
                        Color(0x21FF3B77),
                        Color(0x00FF3B77),
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
                    color: const Color(0xFF141119),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
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
                              color: Color(0xFFF3EFF7),
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              letterSpacing: -0.48,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            'Enter your email and password to continue.',
                            style: TextStyle(
                              color: Color(0xFFA79FB8),
                              fontSize: 12.5,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Email Input Field
                          const Text(
                            'Email',
                            style: TextStyle(
                              color: Color(0xFFF3EFF7),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppTextField(
                            controller: _emailController,
                            hintText: 'you@queerloop.app',
                            keyboardType: TextInputType.emailAddress,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFFA79FB8),
                              size: 17,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Password Input Field
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFFF3EFF7),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppTextField(
                            controller: _passwordController,
                            hintText: 'Enter your password',
                            isPassword: true,
                            fillColor: Colors.white.withValues(alpha: 0.04),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFFA79FB8),
                              size: 17,
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Sign in Button
                          AppGradientButton(
                            text: 'Sign in →',
                            height: 48,
                            borderRadius: BorderRadius.circular(13),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: <Color>[
                                Color(0xFFFF3B77),
                                Color(0xFF8B5CFF),
                              ],
                            ),
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.14,
                            ),
                            onPressed: _submit,
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
