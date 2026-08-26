// Welcome / Onboarding screen shown after the splash to first-time users.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../models/onboarding_page_model.dart';
import '../provider/onboarding_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onFinish});

  final VoidCallback? onFinish;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingProvider>(
      create: (_) => OnboardingProvider(totalPages: 3),
      child: _WelcomeScreenContent(
        pageController: _pageController,
        onFinish: widget.onFinish,
      ),
    );
  }
}

class _WelcomeScreenContent extends StatelessWidget {
  const _WelcomeScreenContent({required this.pageController, this.onFinish});

  final PageController pageController;
  final VoidCallback? onFinish;

  List<OnboardingPageModel> _buildPages(AppLocalizations l10n) {
    return <OnboardingPageModel>[
      OnboardingPageModel(
        imagePath: AppImages.onboardingFeed,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDesc1,
      ),
      OnboardingPageModel(
        imagePath: AppImages.onboardingCommunity,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDesc2,
        tags: const <String>[
          'Lesbian',
          'Gay',
          'Bisexual',
          'Transgender',
          'Non-binary',
          'Queer',
          'General',
        ],
      ),
      OnboardingPageModel(
        imagePath: AppImages.onboardingSafety,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDesc3,
      ),
    ];
  }

  void _handleNext(BuildContext context) {
    final OnboardingProvider provider = context.read<OnboardingProvider>();
    if (provider.isLastPage) {
      onFinish?.call();
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<OnboardingPageModel> pages = _buildPages(l10n);
    final OnboardingProvider provider = context.watch<OnboardingProvider>();
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Bar (page counter + skip) ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '0${provider.currentPage + 1} / 0${pages.length}',
                    style: AppTextStyles.timerText.copyWith(
                      color: context.themeTextMuted,
                    ),
                  ),
                  const Spacer(),
                  if (!provider.isLastPage)
                    GestureDetector(
                      onTap: onFinish,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2B2534).withValues(alpha: 0.8)
                              : const Color(0xFFEDEDF2),
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : context.themeBorder,
                            width: 1.1,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: AppTextStyles.onboardingSkipText.copyWith(
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Scrollable pages ────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (int page) {
                  context.read<OnboardingProvider>().onPageChanged(page);
                },
                itemCount: pages.length,
                itemBuilder: (BuildContext ctx, int index) {
                  return _OnboardingPage(model: pages[index]);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _DotsIndicator(
                count: pages.length,
                currentIndex: provider.currentPage,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: AppGradientButton(
                text: provider.isLastPage
                    ? l10n.onboardingGetStarted
                    : l10n.onboardingNext,
                onPressed: () => _handleNext(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single Onboarding Page ──────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.model});

  final OnboardingPageModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Image card
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(
                model.imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: context.themeCardBackground,
                  child: Icon(
                    Icons.image_outlined,
                    color: context.themeIconMuted,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            model.title,
            style: AppTextStyles.onboardingTitle.copyWith(
              color: context.themeTextPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            model.description,
            style: AppTextStyles.onboardingDesc.copyWith(
              color: context.themeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive ? AppSpacing.lg : AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradientButton : null,
            color: isActive
                ? null
                : (isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}
