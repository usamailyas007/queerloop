class OnboardingPageModel {
  const OnboardingPageModel({
    required this.imagePath,
    required this.title,
    required this.description,
    this.tags = const <String>[],
  });

  final String imagePath;
  final String title;
  final String description;

  final List<String> tags;

  bool get hasTags => tags.isNotEmpty;
}
