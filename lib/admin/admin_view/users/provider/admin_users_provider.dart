// Owns the paginated admin user list: first-page load, infinite-scroll paging,
// server-side search + status filtering, and optimistic status updates.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../admin_users_service.dart';
import '../models/admin_user_account.dart';

class AdminUsersProvider extends ChangeNotifier {
  AdminUsersProvider({required ApiClient client, AdminUsersService? service})
      : _service = service ?? AdminUsersService(client);

  final AdminUsersService _service;

  static const int _pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 400);

  // ── State ─────────────────────────────────────────────────────────────────

  final List<AdminUserAccount> _users = <AdminUserAccount>[];

  bool _isLoading = false; // first page / refresh / filter change
  bool _isLoadingMore = false; // appending a subsequent page
  String? _error;
  bool _hasLoadedOnce = false;

  int _page = 0;
  int _total = 0;
  int _limit = _pageSize;

  String _search = '';
  AdminAccountStatus? _statusFilter; // null = all
  Timer? _searchTimer;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<AdminUserAccount> get users => List<AdminUserAccount>.unmodifiable(_users);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _users.length < _total;
  bool get isEmpty => _hasLoadedOnce && !_isLoading && _users.isEmpty;
  String get search => _search;
  AdminAccountStatus? get statusFilter => _statusFilter;

  int get suspendedCount =>
      _users.where((AdminUserAccount u) => u.status == AdminAccountStatus.suspended).length;

  // ── First load ────────────────────────────────────────────────────────────
  // Safe to call on every build; only the first call actually fetches.

  Future<void> loadInitial() async {
    if (_hasLoadedOnce || _isLoading) {
      return;
    }
    await _loadFirstPage();
  }

  Future<void> refresh() => _loadFirstPage();

  // ── Paging ────────────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final AdminUsersPage result = await _service.fetchUsers(
        page: _page + 1,
        limit: _limit,
        search: _search,
        status: _statusFilter,
      );
      _users.addAll(result.items);
      _page = result.page;
      _total = result.total;
      _error = null;
    } on ApiException catch (failure) {
      _error = failure.message;
    } catch (_) {
      _error = 'Unable to load more users.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSearch(String value) {
    final String next = value.trim();
    if (next == _search) {
      return;
    }
    _search = next;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _loadFirstPage);
  }

  void setStatusFilter(AdminAccountStatus? status) {
    if (status == _statusFilter) {
      return;
    }
    _statusFilter = status;
    _loadFirstPage();
  }

  // ── Optimistic status change ──────────────────────────────────────────────
  // TODO: call the admin status-mutation endpoint once it exists, then reconcile.

  void applyStatusLocally(
    String userId,
    AdminAccountStatus status, {
    DateTime? expiresAt,
  }) {
    final int index = _users.indexWhere((AdminUserAccount u) => u.id == userId);
    if (index == -1) {
      return;
    }
    _users[index]
      ..status = status
      ..statusExpiresAt = expiresAt;
    notifyListeners();
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _loadFirstPage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final AdminUsersPage result = await _service.fetchUsers(
        page: 1,
        limit: _pageSize,
        search: _search,
        status: _statusFilter,
      );
      _users
        ..clear()
        ..addAll(result.items);
      _page = result.page;
      _total = result.total;
      _limit = result.limit == 0 ? _pageSize : result.limit;
      _error = null;
    } on ApiException catch (failure) {
      _users.clear();
      _error = failure.message;
    } catch (_) {
      _users.clear();
      _error = 'Unable to load users. Please try again.';
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
