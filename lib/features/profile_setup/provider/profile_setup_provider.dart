// Profile Setup Provider — owns all wizard state and fires API calls per step.
//
// Selector-friendly design:
//   • Every async action calls notifyListeners() exactly ONCE at the end.
//   • _setBusy() only notifies when the value actually changes.
//   • Per-step error strings are distinct so screens only watch their own error.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/config/api_endpoints.dart';
import '../models/community_model.dart';
import '../models/profile_models.dart';
import '../profile_setup_service.dart';

class ProfileSetupProvider extends ChangeNotifier {
  ProfileSetupProvider({required ProfileSetupService service})
      : _service = service {
    _loadCachedCommunities();
  }

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
  final Set<String> _initialJoinedCommunityIds = <String>{};
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
  List<CommunityModel> _allCommunities = const <CommunityModel>[];
  bool _isLoadingCommunities = false;

  void _loadCachedCommunities() {
    try {
      final dynamic cached = CacheManager.instance.get(ApiEndpoints.communities);
      if (cached != null) {
        List<dynamic> rawList = <dynamic>[];
        if (cached is List) {
          rawList = cached;
        } else if (cached is Map<String, dynamic>) {
          if (cached['data'] is List) {
            rawList = cached['data'] as List<dynamic>;
          } else if (cached['communities'] is List) {
            rawList = cached['communities'] as List<dynamic>;
          } else if (cached['items'] is List) {
            rawList = cached['items'] as List<dynamic>;
          }
        }
        if (rawList.isNotEmpty) {
          _allCommunities = rawList
              .map((dynamic item) =>
                  CommunityModel.fromJson(item as Map<String, dynamic>))
              .where((CommunityModel c) => c.name.isNotEmpty)
              .toList();
          _remapJoinedCommunityIdsToRemote();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ProfileSetup] Error reading cached communities: $e');
    }
  }

  // ── Public getters ────────────────────────────────────────────────────────
  bool get isLoadingCommunities => _isLoadingCommunities;

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

  static String _formatPrivacyLabel(String? val) {
    if (val == null || val.isEmpty) return 'Everyone';
    final String lower = val.toLowerCase().trim();
    if (lower.contains('everyone')) return 'Everyone';
    if (lower.contains('nobody')) return 'Nobody';
    if (lower.contains('mutual')) return 'Mutual follows';
    if (lower.contains('follow')) return 'People you follow';
    return 'Everyone';
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

  // ── Step 2 — API: save avatar (Base64) ───────────────────────────────────

  Future<bool> saveStep2(String userId, {String? avatarBase64}) async {
    if (_isBusy) return false;
    _setBusy(true);

    try {
      String? base64String = avatarBase64;
      if (base64String == null || base64String.isEmpty) {
        if (_profilePhotoPath != null) {
          final File file = File(_profilePhotoPath!);
          if (await file.exists()) {
            final Uint8List bytes = await file.readAsBytes();
            base64String = base64Encode(bytes);
          }
        }
      }

      base64String ??=
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

      final UserProfile result = await _service.saveAvatar(
        userId: userId,
        avatarBase64: base64String,
      );
      _avatarUrl = result.avatarUrl ?? _avatarUrl;
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
  List<CommunityModel>? _syncUserCommunities;

  /// Synchronize joined communities from user profile.
  /// If [force] is true, overrides any current local selections.
  void syncJoinedCommunities(List<CommunityModel> userCommunities, {bool force = false}) {
    _syncUserCommunities = List<CommunityModel>.from(userCommunities);
    if (force || _joinedCommunityIds.isEmpty) {
      _resolveJoinedCommunities();
      _initialJoinedCommunityIds.clear();
      _initialJoinedCommunityIds.addAll(_joinedCommunityIds);
    }
  }

  void _resolveJoinedCommunities() {
    if (_syncUserCommunities == null || _syncUserCommunities!.isEmpty) return;

    final Set<String> matchedIds = <String>{};
    for (final CommunityModel userComm in _syncUserCommunities!) {
      // 1. Direct ID match in _allCommunities
      final CommunityModel? matchById = _allCommunities
          .cast<CommunityModel?>()
          .firstWhere((c) => c != null && c.id.isNotEmpty && c.id == userComm.id, orElse: () => null);
      if (matchById != null && matchById.id.isNotEmpty) {
        matchedIds.add(matchById.id);
        continue;
      }

      // 2. Name match in _allCommunities (case-insensitive)
      final CommunityModel? matchByName = _allCommunities
          .cast<CommunityModel?>()
          .firstWhere(
            (c) => c != null && c.name.trim().toLowerCase() == userComm.name.trim().toLowerCase(),
            orElse: () => null,
          );
      if (matchByName != null && matchByName.id.isNotEmpty) {
        matchedIds.add(matchByName.id);
        continue;
      }

      // 3. Fallback: preserve userComm.id
      if (userComm.id.isNotEmpty) {
        matchedIds.add(userComm.id);
      }
    }

    if (matchedIds.isNotEmpty) {
      _joinedCommunityIds.clear();
      _joinedCommunityIds.addAll(matchedIds);
      notifyListeners();
    }
  }

  void _remapJoinedCommunityIdsToRemote() {
    if (_allCommunities.isEmpty) return;

    if (_joinedCommunityIds.isEmpty && _syncUserCommunities != null && _syncUserCommunities!.isNotEmpty) {
      _resolveJoinedCommunities();
      _initialJoinedCommunityIds.clear();
      _initialJoinedCommunityIds.addAll(_joinedCommunityIds);
      return;
    }

    final Set<String> updated = <String>{};
    for (final String id in _joinedCommunityIds) {
      final bool directMatch = _allCommunities.any((c) => c.id == id);
      if (directMatch) {
        updated.add(id);
        continue;
      }

      final CommunityModel? match = _allCommunities.cast<CommunityModel?>().firstWhere(
        (c) =>
            c != null &&
            (c.name.trim().toLowerCase() == id.trim().toLowerCase() ||
                (c.slug != null && c.slug!.trim().toLowerCase() == id.trim().toLowerCase())),
        orElse: () => null,
      );
      if (match != null && match.id.isNotEmpty) {
        updated.add(match.id);
      } else {
        updated.add(id);
      }
    }
    _joinedCommunityIds.clear();
    _joinedCommunityIds.addAll(updated);

    final Set<String> updatedInitial = <String>{};
    for (final String id in _initialJoinedCommunityIds) {
      final bool directMatch = _allCommunities.any((c) => c.id == id);
      if (directMatch) {
        updatedInitial.add(id);
        continue;
      }

      final CommunityModel? match = _allCommunities.cast<CommunityModel?>().firstWhere(
        (c) =>
            c != null &&
            (c.name.trim().toLowerCase() == id.trim().toLowerCase() ||
                (c.slug != null && c.slug!.trim().toLowerCase() == id.trim().toLowerCase())),
        orElse: () => null,
      );
      if (match != null && match.id.isNotEmpty) {
        updatedInitial.add(match.id);
      } else {
        updatedInitial.add(id);
      }
    }
    _initialJoinedCommunityIds.clear();
    _initialJoinedCommunityIds.addAll(updatedInitial);
  }

  /// Toggles community selection.
  /// Returns `false` if unselecting is blocked because at least 1 community must remain joined.
  bool toggleCommunity(String communityId) {
    if (_joinedCommunityIds.contains(communityId)) {
      if (_joinedCommunityIds.length <= 1) {
        return false;
      }
      _joinedCommunityIds.remove(communityId);
    } else {
      _joinedCommunityIds.add(communityId);
    }
    notifyListeners();
    return true;
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

  // ── Step 4 — API: fetch communities ───────────────────────────────────────

  Future<void> fetchCommunities() async {
    _isLoadingCommunities = true;
    notifyListeners();

    try {
      final List<CommunityModel> remote = await _service.getCommunities();
      if (remote.isNotEmpty) {
        _allCommunities = remote;
      }
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      debugPrint('⚠️ [ProfileSetup] Failed to fetch communities: ${e.message}');
    } catch (e) {
      debugPrint('⚠️ [ProfileSetup] Failed to fetch communities: $e');
    } finally {
      _isLoadingCommunities = false;
      _remapJoinedCommunityIdsToRemote();
      notifyListeners();
    }
  }

  // ── Step 4 — API: join selected communities ───────────────────────────────

  Future<bool> saveStep4() async {
    if (_isBusy) return false;
    _setBusy(true);

    try {
      final Set<String> toJoin =
          _joinedCommunityIds.difference(_initialJoinedCommunityIds);
      final Set<String> toLeave =
          _initialJoinedCommunityIds.difference(_joinedCommunityIds);

      final Set<String> finalJoin =
          _initialJoinedCommunityIds.isEmpty ? _joinedCommunityIds : toJoin;

      if (toLeave.isNotEmpty) {
        debugPrint(
            '🚀 [ProfileSetup] Leaving ${toLeave.length} communities: $toLeave');
        await _service.leaveCommunities(toLeave);
      }

      if (finalJoin.isNotEmpty) {
        debugPrint(
            '🚀 [ProfileSetup] Joining ${finalJoin.length} communities: $finalJoin');
        await _service.joinCommunities(finalJoin);
      }

      _initialJoinedCommunityIds.clear();
      _initialJoinedCommunityIds.addAll(_joinedCommunityIds);

      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update communities.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
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

  // ── Full reset (call on logout / new sign-up) ─────────────────────────────

  /// Resets all wizard state so the next sign-up starts from Step 1.
  void reset() {
    _currentStep = 0;
    _displayName = '';
    _username = '';
    _bio = '';
    _isUsernameAvailable = null;
    _checkingUsername = false;
    _profilePhotoPath = null;
    _avatarUrl = null;
    _selectedPronouns.clear();
    _isPronounsPrivate = false;
    _joinedCommunityIds.clear();
    _initialJoinedCommunityIds.clear();
    _communitySearchQuery = '';
    _secretTags.clear();
    _syncUserCommunities = null;
    _isPrivateAccount = true;
    _showInDiscover = false;
    _hideMyLikes = true;
    _allowMessagesFrom = 'People you follow';
    _profileVisibility = 'People you follow';
    _isBusy = false;
    _error = null;
    _savedProfile = null;
    _usernameDebounceTimer?.cancel();
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
