import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/auth_provider.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../profile/provider/profile_provider.dart';

class InterestsOnboardingScreen extends StatefulWidget {
  const InterestsOnboardingScreen({super.key});

  @override
  State<InterestsOnboardingScreen> createState() =>
      _InterestsOnboardingScreenState();
}

class _InterestsOnboardingScreenState extends State<InterestsOnboardingScreen> {
  final Set<String> _selected = <String>{};
  bool _isSaving = false;

  static const List<String> _allInterests = <String>[
    'Pride Events',
    'Trans Health',
    'Coming Out',
    'Drag & Performance',
    'Dating',
    'Mental Health',
    'Books & Reading',
    'Gaming',
    'Fitness',
    'Music',
    'Art & Design',
    'Activism',
    'Queer Parenting',
    'Fashion',
    'Comedy',
    'Movies & TV',
    'Food & Cooking',
    'Travel',
    'Photography',
    'Tech',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with existing interests if already in profile
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    if (profileProvider.interests.isNotEmpty) {
      _selected.addAll(profileProvider.interests);
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selected.contains(interest)) {
        _selected.remove(interest);
      } else {
        _selected.add(interest);
      }
    });
  }

  Future<void> _handleContinue() async {
    if (_selected.length < 3) {
      AppSnackBar.showError(
        context,
        title: 'Selection Required',
        subtitle: 'Please select at least 3 interests to continue.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final String? userId = context.read<AuthProvider>().userId;

    if (userId != null && userId.isNotEmpty) {
      final bool ok = await context.read<ProfileProvider>().updateProfile(
            userId,
            interests: _selected.toList(),
          );
      if (!ok && mounted) {
        setState(() => _isSaving = false);
        final String? err = context.read<ProfileProvider>().error;
        AppSnackBar.showError(
          context,
          title: 'Save Failed',
          subtitle: err ?? 'Failed to save interests.',
        );
        return;
      }
    }

    if (!mounted) return;
    context.read<HomeFeedProvider>().resetToHome();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
  }

  void _handleSkip() {
    context.read<HomeFeedProvider>().resetToHome();
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Navigation (Skip Button) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  GestureDetector(
                    onTap: _handleSkip,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Main Content (Title, Subtitle & Interests Wrap) ───────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'What are you into?',
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Pick a few so we can shape your feed and suggest people to follow. You can change these anytime from your profile.',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Wrap of Interest Pills ───────────────────────────
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: _allInterests.map((String item) {
                        final bool isSelected = _selected.contains(item);
                        return _InterestPill(
                          label: item,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => _toggleInterest(item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Area ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.sm,
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Pick at least 3',
                    style: TextStyle(
                      color: context.themeTextMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppGradientButton(
                    text: 'Enter QueerLoop+',
                    isEnabled: _selected.length >= 3,
                    isLoading: _isSaving,
                    onPressed: _handleContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestPill extends StatelessWidget {
  const _InterestPill({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Border border;

    if (isSelected) {
      if (isDark) {
        bgColor = const Color(0xFF092228);
        textColor = Colors.white;
        border = Border.all(color: const Color(0xFF00E5FF), width: 1.5);
      } else {
        bgColor = const Color(0xFFD4FAFF);
        textColor = const Color(0xFF0D1E24);
        border = Border.all(color: const Color(0xFF00E5FF), width: 1.5);
      }
    } else {
      if (isDark) {
        bgColor = const Color(0xFF1E1D27);
        textColor = const Color(0xFFE4E2ED);
        border = Border.all(color: const Color(0xFF2A2837), width: 1);
      } else {
        bgColor = const Color(0xFFF2F1F7);
        textColor = const Color(0xFF262432);
        border = Border.all(color: const Color(0xFFEBEAEF), width: 1);
      }
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 15 : 18,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
            if (isSelected) ...<Widget>[
              const SizedBox(width: 8),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: Color(0xFF081419),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
