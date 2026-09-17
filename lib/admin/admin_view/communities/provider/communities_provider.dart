// Owns the communities list + create flow.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../communities_service.dart';
import '../models/community.dart';

class CommunitiesProvider extends ChangeNotifier {
  CommunitiesProvider({required ApiClient client, CommunitiesService? service})
      : _service = service ?? CommunitiesService(client);

  final CommunitiesService _service;

  List<Community> _communities = <Community>[];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _error;
  bool _hasLoadedOnce = false;
  final Set<String> _deletingIds = <String>{};

  List<Community> get communities => List<Community>.unmodifiable(_communities);
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  String? get error => _error;
  int get count => _communities.length;
  bool get isEmpty => _hasLoadedOnce && !_isLoading && _communities.isEmpty;
  bool isDeleting(String id) => _deletingIds.contains(id);

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
      _communities = await _service.fetchCommunities();
      _error = null;
    } on ApiException catch (failure) {
      _error = failure.message;
    } catch (_) {
      _error = 'Unable to load communities. Please try again.';
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Returns the created community on success, null on failure (`error` is set).
  Future<Community?> createCommunity({
    required String name,
    required String slug,
    required String description,
    required CommunityVisibility visibility,
    String? imageBase64,
  }) async {
    if (_isCreating) {
      return null;
    }
    _isCreating = true;
    _error = null;
    notifyListeners();

    try {
      final Community created = await _service.createCommunity(
        name: name,
        slug: slug,
        description: description,
        visibility: visibility,
        imageBase64: imageBase64,
      );
      _communities = <Community>[created, ..._communities];
      return created;
    } on ApiException catch (failure) {
      _error = failure.message;
      return null;
    } catch (_) {
      _error = 'Could not create the community. Please try again.';
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  /// Returns true on success (`error` set on failure).
  Future<bool> deleteCommunity(String id) async {
    if (_deletingIds.contains(id)) {
      return false;
    }
    _deletingIds.add(id);
    notifyListeners();
    try {
      await _service.deleteCommunity(id);
      _communities = _communities.where((Community c) => c.id != id).toList();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      return false;
    } catch (_) {
      _error = 'Could not delete this community. Please try again.';
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
}
