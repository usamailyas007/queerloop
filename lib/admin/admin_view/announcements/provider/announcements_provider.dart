// Owns the announcements feed + compose flow.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../announcements_service.dart';
import '../models/announcement.dart';

class AnnouncementsProvider extends ChangeNotifier {
  AnnouncementsProvider({
    required ApiClient client,
    AnnouncementsService? service,
  }) : _service = service ?? AnnouncementsService(client);

  final AnnouncementsService _service;

  /// Backend returns the whole feed, so paging is done here on the client.
  static const int pageSize = 7;

  List<Announcement> _announcements = <Announcement>[];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  bool _hasLoadedOnce = false;
  int _page = 1;

  List<Announcement> get announcements =>
      List<Announcement>.unmodifiable(_announcements);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get isEmpty => _hasLoadedOnce && !_isLoading && _announcements.isEmpty;

  // ── Client-side pagination ────────────────────────────────────────────────

  int get page => _page;
  int get total => _announcements.length;
  int get pageCount =>
      _announcements.isEmpty ? 1 : (_announcements.length / pageSize).ceil();
  bool get canPrev => _page > 1;
  bool get canNext => _page < pageCount;
  int get rangeStart => _announcements.isEmpty ? 0 : (_page - 1) * pageSize + 1;
  int get rangeEnd =>
      ((_page - 1) * pageSize + pageSize).clamp(0, _announcements.length);

  /// The slice of announcements for the current page.
  List<Announcement> get pageItems {
    if (_announcements.isEmpty) {
      return const <Announcement>[];
    }
    final int start = (_page - 1) * pageSize;
    return _announcements.sublist(
      start,
      (start + pageSize).clamp(0, _announcements.length),
    );
  }

  void goToPage(int value) {
    final int target = value.clamp(1, pageCount);
    if (target == _page) {
      return;
    }
    _page = target;
    notifyListeners();
  }

  void nextPage() => goToPage(_page + 1);
  void prevPage() => goToPage(_page - 1);

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
      _announcements = await _service.fetchAnnouncements();
      _page = 1;
      _error = null;
    } on ApiException catch (failure) {
      _error = failure.message;
    } catch (_) {
      _error = 'Unable to load announcements. Please try again.';
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Returns the published announcement on success, null on failure (`error` set).
  Future<Announcement?> createAnnouncement({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    String? communityId,
  }) async {
    if (_isSending) {
      return null;
    }
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final Announcement created = await _service.createAnnouncement(
        title: title,
        body: body,
        audience: audience,
        communityId: communityId,
      );
      _announcements = <Announcement>[created, ..._announcements];
      _page = 1; // jump back so the new one is visible
      return created;
    } on ApiException catch (failure) {
      _error = failure.message;
      return null;
    } catch (_) {
      _error = 'Could not publish the announcement. Please try again.';
      return null;
    } finally {
      _isSending = false;
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
