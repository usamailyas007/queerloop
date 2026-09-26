// Owns Community Spotlight: the feed, the create / edit / rerun flows.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/spotlight.dart';
import '../spotlights_service.dart';

class SpotlightsProvider extends ChangeNotifier {
  SpotlightsProvider({required ApiClient client, SpotlightsService? service})
      : _service = service ?? SpotlightsService(client);

  final SpotlightsService _service;

  static const Duration _searchDebounce = Duration(milliseconds: 400);

  List<Spotlight> _spotlights = <Spotlight>[];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _hasLoadedOnce = false;
  String _search = '';
  Timer? _searchTimer;
  final Set<String> _rerunningIds = <String>{};
  final Set<String> _deletingIds = <String>{};

  List<Spotlight> get spotlights => List<Spotlight>.unmodifiable(_spotlights);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get search => _search;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get isEmpty =>
      _hasLoadedOnce && !_isLoading && _spotlights.isEmpty;
  bool isRerunning(String id) => _rerunningIds.contains(id);
  bool isDeleting(String id) => _deletingIds.contains(id);

  Spotlight? get liveSpotlight {
    for (final Spotlight s in _spotlights) {
      if (s.live) return s;
    }
    return _spotlights.isNotEmpty ? _spotlights.first : null;
  }

  List<Spotlight> get pastSpotlights =>
      _spotlights.where((Spotlight s) => !s.live).toList();

  Future<void> loadInitial() async {
    if (_hasLoadedOnce || _isLoading) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _spotlights = await _service.fetchSpotlights(search: _search);
      _error = null;
    } on ApiException catch (failure) {
      _error = failure.message;
    } catch (_) {
      _error = 'Unable to load spotlights. Please try again.';
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    final String next = value.trim();
    if (next == _search) {
      return;
    }
    _search = next;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, refresh);
  }

  /// Create (targetId == null) or edit an existing spotlight.
  /// Returns the saved spotlight on success, null on failure (`error` set).
  Future<Spotlight?> saveSpotlight({
    String? targetId,
    required String title,
    required String body,
    String? imageBase64,
  }) async {
    if (_isSaving) {
      return null;
    }
    if (title.trim().isEmpty || body.trim().isEmpty) {
      _error = 'Headline and description are required.';
      notifyListeners();
      return null;
    }
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final Spotlight saved = targetId == null
          ? await _service.createSpotlight(
              title: title.trim(),
              body: body.trim(),
              imageBase64: imageBase64,
            )
          : await _service.updateSpotlight(
              id: targetId,
              title: title.trim(),
              body: body.trim(),
              imageBase64: imageBase64,
            );
      _spotlights = await _service.fetchSpotlights(search: _search);
      return saved;
    } on ApiException catch (failure) {
      _error = failure.message;
      return null;
    } catch (_) {
      _error = 'Could not save the spotlight. Please try again.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Returns true on success (`error` set on failure).
  Future<bool> rerunSpotlight(String id) async {
    if (_rerunningIds.contains(id)) {
      return false;
    }
    _rerunningIds.add(id);
    notifyListeners();
    try {
      await _service.rerunSpotlight(id);
      _spotlights = await _service.fetchSpotlights(search: _search);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      return false;
    } catch (_) {
      _error = 'Could not re-run this spotlight. Please try again.';
      return false;
    } finally {
      _rerunningIds.remove(id);
      notifyListeners();
    }
  }

  /// Returns true on success (`error` set on failure).
  Future<bool> deleteSpotlight(String id) async {
    if (_deletingIds.contains(id)) {
      return false;
    }
    _deletingIds.add(id);
    notifyListeners();
    try {
      await _service.deleteSpotlight(id);
      _spotlights = _spotlights.where((Spotlight s) => s.id != id).toList();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      return false;
    } catch (_) {
      _error = 'Could not delete this spotlight. Please try again.';
      return false;
    } finally {
      _deletingIds.remove(id);
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
