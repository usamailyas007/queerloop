import 'package:flutter/foundation.dart';

/// Manages the onboarding PageView state.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({this.totalPages = 3});

  final int totalPages;
  int _currentPage = 0;

  int get currentPage => _currentPage;
  bool get isLastPage => _currentPage == totalPages - 1;

  void onPageChanged(int page) {
    if (page == _currentPage) return;
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (isLastPage) return;
    _currentPage++;
    notifyListeners();
  }
}
