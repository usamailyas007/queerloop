import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../provider/profile_setup_provider.dart';
import 'step1_name_username_screen.dart';
import 'step2_add_photo_screen.dart';
import 'step3_select_pronouns_screen.dart';
import 'step4_choose_communities_screen.dart';
import 'step5_your_privacy_screen.dart';

class ProfileSetupFlowScreen extends StatefulWidget {
  const ProfileSetupFlowScreen({super.key});

  @override
  State<ProfileSetupFlowScreen> createState() => _ProfileSetupFlowScreenState();
}

class _ProfileSetupFlowScreenState extends State<ProfileSetupFlowScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final int initialStep = context.read<ProfileSetupProvider>().currentStep;
    _pageController = PageController(initialPage: initialStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final ProfileSetupProvider provider = context.read<ProfileSetupProvider>();
    if (provider.currentStep < 4) {
      provider.nextStep();
      _pageController.animateToPage(
        provider.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _previousPage() {
    final ProfileSetupProvider provider = context.read<ProfileSetupProvider>();
    if (provider.currentStep > 0) {
      provider.previousStep();
      _pageController.animateToPage(
        provider.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  void _finish() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.interestsOnboarding,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider =
        context.watch<ProfileSetupProvider>();

    // Smoothly animate if provider step changes from external screen without post-frame flicker
    if (_pageController.hasClients &&
        _pageController.page?.round() != provider.currentStep) {
      _pageController.animateToPage(
        provider.currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          Step1NameUsernameScreen(onNext: _nextPage),
          Step2AddPhotoScreen(onNext: _nextPage, onBack: _previousPage),
          Step3SelectPronounsScreen(onNext: _nextPage, onBack: _previousPage),
          Step4ChooseCommunitiesScreen(onNext: _nextPage, onBack: _previousPage),
          Step5YourPrivacyScreen(onFinish: _finish, onBack: _previousPage),
        ],
      ),
    );
  }
}
