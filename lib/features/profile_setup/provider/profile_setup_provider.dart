import 'package:flutter/foundation.dart';
import '../../../core/theme/app_images.dart';
import '../models/community_model.dart';

class ProfileSetupProvider extends ChangeNotifier {
  int _currentStep = 0; // 0..4 (Steps 1 to 5)

  String _displayName = '';
  String _username = '';
  String _bio = '';
  bool _isUsernameAvailable = false;

  String? _profilePhotoPath;

  final Set<String> _selectedPronouns = <String>{};
  final List<String> _availablePronouns = <String>[
    'she / her',
    'he / him',
    'they / them',
    'ze / zir',
    'xe / xem',
    'ey / em',
    'fae / faer',
    'any pronouns',
    'ask me',
  ];
  bool _isPronounsPrivate = false;

  final List<String> _secretTags = <String>[];

  final Set<String> _joinedCommunityIds = <String>{};

  String _communitySearchQuery = '';

  // ── Privacy Settings (Step 5) ──────────────────────────────────────────────
  bool _isPrivateAccount = true;
  bool _showInDiscover = false;
  bool _hideMyLikes = true;
  String _allowMessagesFrom = 'People you follow';
  String _profileVisibility = 'People you follow';

  final List<CommunityModel> _allCommunities = const <CommunityModel>[
    CommunityModel(
      id: 'lesbian',
      name: 'Lesbian',
      avatarAsset: AppImages.lesbian,
    ),
    CommunityModel(
      id: 'gay',
      name: 'Gay',
      avatarAsset: AppImages.gay,
    ),
    CommunityModel(
      id: 'bisexual',
      name: 'Bisexual',
      avatarAsset: AppImages.bisexual,
    ),
    CommunityModel(
      id: 'transgender',
      name: 'Transgender',
      avatarAsset: AppImages.transgender,
    ),
    CommunityModel(
      id: 'non_binary',
      name: 'Non-binary',
      avatarAsset: AppImages.nonBinary,
    ),
    CommunityModel(
      id: 'queer',
      name: 'Queer',
      avatarAsset: AppImages.queer,
    ),
    CommunityModel(
      id: 'pansexual',
      name: 'Pansexual',
      avatarAsset: AppImages.pansexual,
    ),
    CommunityModel(
      id: 'asexual',
      name: 'Asexual / Ace',
      avatarAsset: AppImages.asexual,
    ),
    CommunityModel(
      id: 'aromantic',
      name: 'Aromantic / Aro',
      avatarAsset: AppImages.aromantic,
    ),
    CommunityModel(
      id: 'intersex',
      name: 'Intersex',
      avatarAsset: AppImages.intersex,
    ),
    CommunityModel(
      id: 'genderfluid',
      name: 'Genderfluid',
      avatarAsset: AppImages.genderfluid,
    ),
    CommunityModel(
      id: 'transmasc',
      name: 'Transmasc',
      avatarAsset: AppImages.transmasc,
    ),
    CommunityModel(
      id: 'transfemme',
      name: 'Transfemme',
      avatarAsset: AppImages.transfemme,
    ),
    CommunityModel(
      id: 'allies',
      name: 'LGBTQ+ Allies',
      avatarAsset: AppImages.allies,
    ),
  ];

  // Getters
  int get currentStep => _currentStep;
  String get displayName => _displayName;
  String get username => _username;
  String get bio => _bio;
  bool get isUsernameAvailable => _isUsernameAvailable;

  String? get profilePhotoPath => _profilePhotoPath;

  Set<String> get selectedPronouns => _selectedPronouns;
  List<String> get availablePronouns => _availablePronouns;
  bool get isPronounsPrivate => _isPronounsPrivate;

  List<String> get secretTags => List<String>.unmodifiable(_secretTags);

  Set<String> get joinedCommunityIds => _joinedCommunityIds;
  int get joinedCount => _joinedCommunityIds.length;
  List<CommunityModel> get allCommunities => _allCommunities;
  String get communitySearchQuery => _communitySearchQuery;

  bool get isPrivateAccount => _isPrivateAccount;
  bool get showInDiscover => _showInDiscover;
  bool get hideMyLikes => _hideMyLikes;
  String get allowMessagesFrom => _allowMessagesFrom;
  String get profileVisibility => _profileVisibility;

  List<CommunityModel> get filteredCommunities {
    if (_communitySearchQuery.trim().isEmpty) {
      return _allCommunities;
    }
    return _allCommunities.where((CommunityModel item) {
      return item.name
          .toLowerCase()
          .contains(_communitySearchQuery.toLowerCase().trim());
    }).toList();
  }

  // Setters & Actions
  void setStep(int step) {
    if (step >= 0 && step <= 4) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void setDisplayName(String val) {
    _displayName = val;
    notifyListeners();
  }

  void setUsername(String val) {
    _username = val;
    _isUsernameAvailable = val.trim().isNotEmpty && !val.contains(' ');
    notifyListeners();
  }

  void setBio(String val) {
    _bio = val;
    notifyListeners();
  }

  void setProfilePhoto(String path) {
    _profilePhotoPath = path;
    notifyListeners();
  }

  void togglePronoun(String pronoun) {
    if (_selectedPronouns.contains(pronoun)) {
      _selectedPronouns.remove(pronoun);
    } else {
      _selectedPronouns.add(pronoun);
    }
    notifyListeners();
  }

  void addCustomPronoun(String pronoun) {
    final String trimmed = pronoun.trim();
    if (trimmed.isNotEmpty) {
      if (!_availablePronouns.contains(trimmed)) {
        _availablePronouns.add(trimmed);
      }
      _selectedPronouns.add(trimmed);
      notifyListeners();
    }
  }

  void togglePronounsPrivate(bool value) {
    _isPronounsPrivate = value;
    notifyListeners();
  }

  void addSecretTag(String tag) {
    final String trimmed = tag.trim().replaceAll('#', '');
    if (trimmed.isNotEmpty && !_secretTags.contains(trimmed)) {
      _secretTags.add(trimmed);
      notifyListeners();
    }
  }

  void removeSecretTag(String tag) {
    _secretTags.remove(tag);
    notifyListeners();
  }

  void toggleCommunity(String communityId) {
    if (_joinedCommunityIds.contains(communityId)) {
      _joinedCommunityIds.remove(communityId);
    } else {
      _joinedCommunityIds.add(communityId);
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _communitySearchQuery = query;
    notifyListeners();
  }

  // Privacy setters
  void togglePrivateAccount(bool val) {
    _isPrivateAccount = val;
    notifyListeners();
  }

  void toggleShowInDiscover(bool val) {
    _showInDiscover = val;
    notifyListeners();
  }

  void toggleHideMyLikes(bool val) {
    _hideMyLikes = val;
    notifyListeners();
  }

  void setAllowMessagesFrom(String val) {
    _allowMessagesFrom = val;
    notifyListeners();
  }

  void setProfileVisibility(String val) {
    _profileVisibility = val;
    notifyListeners();
  }
}
