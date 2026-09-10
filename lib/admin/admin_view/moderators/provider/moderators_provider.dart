// Owns the moderator roster + invite flow.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../models/moderator.dart';
import '../moderators_service.dart';

class ModeratorsProvider extends ChangeNotifier {
  ModeratorsProvider({required ApiClient client, ModeratorsService? service})
      : _service = service ?? ModeratorsService(client);

  final ModeratorsService _service;

  List<Moderator> _moderators = <Moderator>[];
  bool _isLoading = false;
  bool _isInviting = false;
  String? _error;
  bool _hasLoadedOnce = false;
  final Set<String> _resendingIds = <String>{};

  List<Moderator> get moderators => List<Moderator>.unmodifiable(_moderators);
  bool get isLoading => _isLoading;
  bool get isInviting => _isInviting;
  String? get error => _error;
  bool get isEmpty => _hasLoadedOnce && !_isLoading && _moderators.isEmpty;
  bool isResending(String id) => _resendingIds.contains(id);

  int get activeCount =>
      _moderators.where((Moderator m) => !m.pending).length;
  int get pendingCount =>
      _moderators.where((Moderator m) => m.pending).length;

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
      _moderators = await _service.fetchModerators();
      _error = null;
    } on ApiException catch (failure) {
      _error = failure.message;
    } catch (_) {
      _error = 'Unable to load moderators. Please try again.';
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Returns true on success (`error` is set on failure).
  Future<bool> inviteModerator({
    required String email,
    required String password,
    required List<String> communityIds,
  }) async {
    if (_isInviting) {
      return false;
    }
    _isInviting = true;
    _error = null;
    notifyListeners();

    try {
      await _service.inviteModerator(
        email: email,
        password: password,
        communityIds: communityIds,
      );
      await refresh();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      return false;
    } catch (_) {
      _error = 'Could not send the invite. Please try again.';
      return false;
    } finally {
      _isInviting = false;
      notifyListeners();
    }
  }

  /// Re-sends the invite for a pending moderator. Returns the server's
  /// confirmation message on success, null on failure (`error` is set).
  Future<String?> resendInvite(String moderatorId) async {
    if (_resendingIds.contains(moderatorId)) {
      return null;
    }
    _resendingIds.add(moderatorId);
    _error = null;
    notifyListeners();
    try {
      final String? message = await _service.resendInvite(moderatorId);
      return message ?? 'Invite re-sent.';
    } on ApiException catch (failure) {
      _error = failure.message;
      return null;
    } catch (_) {
      _error = 'Could not re-send the invite. Please try again.';
      return null;
    } finally {
      _resendingIds.remove(moderatorId);
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
