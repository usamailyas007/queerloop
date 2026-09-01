// Profile Setup Provider — owns all wizard state and fires API calls per step.
//
// Selector-friendly design:
//   • Every async action calls notifyListeners() exactly ONCE at the end.
//   • _setBusy() only notifies when the value actually changes.
//   • Per-step error strings are distinct so screens only watch their own error.

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_images.dart';
import '../models/community_model.dart';
import '../models/profile_models.dart';
import '../profile_setup_service.dart';

class ProfileSetupProvider extends ChangeNotifier {
  ProfileSetupProvider({required ProfileSetupService service})
      : _service = service;

  final ProfileSetupService _service;

  // ── Wizard navigation ─────────────────────────────────────────────────────
  int _currentStep = 0; // 0-based, 0..4

  // ── Step 1 local state ────────────────────────────────────────────────────
  String _displayName = '';
  String _username = '';
  String _bio = '';

  /// null = not checked yet, true = available, false = taken
  bool? _isUsernameAvailable;
  bool _checkingUsername = false;

  // ── Step 2 local state ────────────────────────────────────────────────────
  String? _profilePhotoPath; // local file path (before upload)
  String? _avatarUrl; // remote URL after upload

  // ── Step 3 local state ────────────────────────────────────────────────────
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

  // ── Step 4 local state ────────────────────────────────────────────────────
  final Set<String> _joinedCommunityIds = <String>{};
  String _communitySearchQuery = '';

  final List<String> _secretTags = <String>[];

  // ── Step 5 local state ────────────────────────────────────────────────────
  bool _isPrivateAccount = true;
  bool _showInDiscover = false;
  bool _hideMyLikes = true;
  String _allowMessagesFrom = 'People you follow';
  String _profileVisibility = 'People you follow';

  // ── Async state shared across steps ──────────────────────────────────────
  bool _isBusy = false;
  String? _error;

  /// Accumulated server-confirmed profile (merged on each successful PATCH).
  UserProfile? _savedProfile;

  // ── Available communities ─────────────────────────────────────────────────
  final List<CommunityModel> _allCommunities = const <CommunityModel>[
    CommunityModel(id: 'lesbian', name: 'Lesbian', avatarAsset: AppImages.lesbian),
    CommunityModel(id: 'gay', name: 'Gay', avatarAsset: AppImages.gay),
    CommunityModel(id: 'bisexual', name: 'Bisexual', avatarAsset: AppImages.bisexual),
    CommunityModel(id: 'transgender', name: 'Transgender', avatarAsset: AppImages.transgender),
    CommunityModel(id: 'non_binary', name: 'Non-binary', avatarAsset: AppImages.nonBinary),
    CommunityModel(id: 'queer', name: 'Queer', avatarAsset: AppImages.queer),
    CommunityModel(id: 'pansexual', name: 'Pansexual', avatarAsset: AppImages.pansexual),
    CommunityModel(id: 'asexual', name: 'Asexual / Ace', avatarAsset: AppImages.asexual),
    CommunityModel(id: 'aromantic', name: 'Aromantic / Aro', avatarAsset: AppImages.aromantic),
    CommunityModel(id: 'intersex', name: 'Intersex', avatarAsset: AppImages.intersex),
    CommunityModel(id: 'genderfluid', name: 'Genderfluid', avatarAsset: AppImages.genderfluid),
    CommunityModel(id: 'transmasc', name: 'Transmasc', avatarAsset: AppImages.transmasc),
    CommunityModel(id: 'transfemme', name: 'Transfemme', avatarAsset: AppImages.transfemme),
    CommunityModel(id: 'allies', name: 'LGBTQ+ Allies', avatarAsset: AppImages.allies),
  ];

  // ── Public getters ────────────────────────────────────────────────────────

  int get currentStep => _currentStep;

  String get displayName => _displayName;
  String get username => _username;
  String get bio => _bio;
  bool? get isUsernameAvailable => _isUsernameAvailable;
  bool get checkingUsername => _checkingUsername;

  String? get profilePhotoPath => _profilePhotoPath;
  String? get avatarUrl => _avatarUrl;

  Set<String> get selectedPronouns => Set<String>.unmodifiable(_selectedPronouns);
  List<String> get availablePronouns =>
      List<String>.unmodifiable(_availablePronouns);
  bool get isPronounsPrivate => _isPronounsPrivate;

  List<String> get secretTags => List<String>.unmodifiable(_secretTags);

  Set<String> get joinedCommunityIds =>
      Set<String>.unmodifiable(_joinedCommunityIds);
  int get joinedCount => _joinedCommunityIds.length;
  List<CommunityModel> get allCommunities => _allCommunities;
  String get communitySearchQuery => _communitySearchQuery;

  bool get isPrivateAccount => _isPrivateAccount;
  bool get showInDiscover => _showInDiscover;
  bool get hideMyLikes => _hideMyLikes;
  String get allowMessagesFrom => _formatPrivacyLabel(_allowMessagesFrom);
  String get profileVisibility => _formatPrivacyLabel(_profileVisibility);

  static String _formatPrivacyLabel(String val) {
    final String lower = val.toLowerCase().trim();
    if (lower == 'everyone') return 'Everyone';
    if (lower == 'followers' ||
        lower == 'people_you_follow' ||
        lower == 'people you follow') {
      return 'People you follow';
    }
    if (lower == 'mutuals' ||
        lower == 'mutual_follows' ||
        lower == 'mutual follows') {
      return 'Mutual follows';
    }
    if (lower == 'nobody') return 'Nobody';
    return val;
  }

  bool get isBusy => _isBusy;
  String? get error => _error;
  UserProfile? get savedProfile => _savedProfile;

  List<CommunityModel> get filteredCommunities {
    final String q = _communitySearchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return _allCommunities;
    }
    return _allCommunities
        .where((CommunityModel c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  // ── Wizard navigation ─────────────────────────────────────────────────────

  void setStep(int step) {
    if (step >= 0 && step <= 4 && step != _currentStep) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() => setStep(_currentStep + 1);
  void previousStep() => setStep(_currentStep - 1);

  // ── Step 1 local setters & Debounced Username check ────────────────────────
  Timer? _usernameDebounceTimer;

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel();
    super.dispose();
  }

  void setDisplayName(String val) {
    if (_displayName == val) return;
    _displayName = val;
    notifyListeners();
  }

  void setUsername(String val) {
    final String trimmed = val.trim();
    if (_username == trimmed) return;
    _username = trimmed;
    _usernameDebounceTimer?.cancel();

    if (trimmed.length < 3) {
      _isUsernameAvailable = null;
      _checkingUsername = false;
      notifyListeners();
      return;
    }

    _checkingUsername = true;
    _isUsernameAvailable = null;
    notifyListeners();

    // ⏱️ Debounce: Wait 500ms after user pauses typing before calling GET /users/username-available
    _usernameDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      checkUsername(trimmed);
    });
  }

  void setBio(String val) {
    if (_bio == val) return;
    _bio = val;
    notifyListeners();
  }

  // ── Step 1 — API: check username ──────────────────────────────────────────

  Future<void> checkUsername(String username) async {
    final String trimmed = username.trim();
    if (trimmed.length < 3) {
      _isUsernameAvailable = null;
      _checkingUsername = false;
      notifyListeners();
      return;
    }

    _checkingUsername = true;
    notifyListeners();

    try {
      final bool available =
          await _service.checkUsernameAvailable(trimmed);
      // Only apply if user hasn't changed the input in the meantime
      if (_username == trimmed) {
        _isUsernameAvailable = available;
      }
    } on ApiException catch (e) {
      _error = e.message;
      _isUsernameAvailable = null;
    } catch (_) {
      _isUsernameAvailable = null;
    } finally {
      _checkingUsername = false;
      notifyListeners();
    }
  }

  // ── Step 1 — API: save basic info ────────────────────────────────────────

  Future<bool> saveStep1(String userId) async {
    if (_isBusy) return false;
    _setBusy(true);

    try {
      final UserProfile result = await _service.saveBasicInfo(
        userId: userId,
        displayName: _displayName.trim(),
        username: _username.trim(),
        bio: _bio.trim(),
      );
      _savedProfile = (_savedProfile ?? UserProfile(id: userId)).merge(result);
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Step 2 local setter ───────────────────────────────────────────────────

  void setProfilePhoto(String path) {
    if (_profilePhotoPath == path) return;
    _profilePhotoPath = path;
    notifyListeners();
  }

  // ── Step 2 — API: save avatar URL ─────────────────────────────────────────

  Future<bool> saveStep2(String userId, {required String avatarUrl}) async {
    if (_isBusy) return false;
    _setBusy(true);

    try {
      final UserProfile result = await _service.saveAvatarUrl(
        userId: userId,
        avatarUrl: avatarUrl,
      );
      _avatarUrl = result.avatarUrl ?? avatarUrl;
      _savedProfile = (_savedProfile ?? UserProfile(id: userId)).merge(result);
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Step 3 local setters ──────────────────────────────────────────────────

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
    if (trimmed.isEmpty) return;
    if (!_availablePronouns.contains(trimmed)) {
      _availablePronouns.add(trimmed);
    }
    _selectedPronouns.add(trimmed);
    notifyListeners();
  }

  void togglePronounsPrivate(bool value) {
    if (_isPronounsPrivate == value) return;
    _isPronounsPrivate = value;
    notifyListeners();
  }

  // ── Step 3 — API: save pronouns ───────────────────────────────────────────

  Future<bool> saveStep3(String userId) async {
    if (_isBusy) return false;
    _setBusy(true);

    try {
      final UserProfile result = await _service.savePronouns(
        userId: userId,
        pronouns: _selectedPronouns.toList(),
        pronounsPrivate: _isPronounsPrivate,
      );
      _savedProfile = (_savedProfile ?? UserProfile(id: userId)).merge(result);
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Step 4 local setters ──────────────────────────────────────────────────

  void toggleCommunity(String communityId) {
    if (_joinedCommunityIds.contains(communityId)) {
      _joinedCommunityIds.remove(communityId);
    } else {
      _joinedCommunityIds.add(communityId);
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_communitySearchQuery == query) return;
    _communitySearchQuery = query;
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
    if (_secretTags.remove(tag)) {
      notifyListeners();
    }
  }

  // ── Step 4 — API: join selected communities ───────────────────────────────
  // Note: Backend join call is bypassed for now because communities are static.
  Future<bool> saveStep4() async {
    debugPrint(
      'ℹ️ [ProfileSetup] Step 4: Community join API skipped (communities are static). '
      'Selected: $_joinedCommunityIds',
    );
    return true;
  }

  // ── Step 5 local setters ──────────────────────────────────────────────────

  void togglePrivateAccount(bool val) {
    if (_isPrivateAccount == val) return;
    _isPrivateAccount = val;
    notifyListeners();
  }

  void toggleShowInDiscover(bool val) {
    if (_showInDiscover == val) return;
    _showInDiscover = val;
    notifyListeners();
  }

  void toggleHideMyLikes(bool val) {
    if (_hideMyLikes == val) return;
    _hideMyLikes = val;
    notifyListeners();
  }

  void setAllowMessagesFrom(String val) {
    if (_allowMessagesFrom == val) return;
    _allowMessagesFrom = val;
    notifyListeners();
  }

  void setProfileVisibility(String val) {
    if (_profileVisibility == val) return;
    _profileVisibility = val;
    notifyListeners();
  }

  // ── Step 5 — API: save privacy settings ──────────────────────────────────

  Future<bool> saveStep5(String userId) async {
    if (_isBusy) return false;
    _setBusy(true);

    try {
      final UserProfile result = await _service.savePrivacySettings(
        userId: userId,
        isPrivate: _isPrivateAccount,
        showInDiscover: _showInDiscover,
        allowMessagesFrom: _allowMessagesFrom,
        hideMyLikes: _hideMyLikes,
        profileVisibility: _profileVisibility,
      );
      _savedProfile = (_savedProfile ?? UserProfile(id: userId)).merge(result);
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Error management ──────────────────────────────────────────────────────

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Only notifies when value actually changes — prevents redundant rebuilds.
  void _setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    notifyListeners();
  }
}
