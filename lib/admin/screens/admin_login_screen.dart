import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_auth_provider.dart';

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
      backgroundColor: const Color(0xFF0F0D15),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFF16131D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: AppSpacing.sm),

                // Brand Logo (Infinity Symbol)
                CustomPaint(
                  size: const Size(48, 24),
                  painter: _InfinityLogoPainter(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Title: Sign in
                Text(
                  'Sign in',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'Enter your email and password to continue.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Email Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Email',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _emailController,
                      hintText: 'you@queerloop.app',
                      keyboardType: TextInputType.emailAddress,
                      fillColor: const Color(0xFF1D1927),
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Password',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter your password',
                      isPassword: true,
                      fillColor: const Color(0xFF1D1927),
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: Colors.white38,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Sign in Button
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[
                          Color(0xFFFF4B8B),
                          Color(0xFF9D4EDD),
                          Color(0xFF00E5FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFFF4B8B).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Sign in →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfinityLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF00E5FF),
          Color(0xFFFF4B8B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(w * 0.5, h * 0.5);
    path.cubicTo(w * 0.7, 0, w, 0, w, h * 0.5);
    path.cubicTo(w, h, w * 0.7, h, w * 0.5, h * 0.5);
    path.cubicTo(w * 0.3, 0, 0, 0, 0, h * 0.5);
    path.cubicTo(0, h, w * 0.3, h, w * 0.5, h * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
