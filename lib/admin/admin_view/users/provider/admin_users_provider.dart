// Owns the admin Users tab: page-numbered list (10 per page), the stats card,
// server-side search + status filter, and suspend/reactivate mutations.
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

  static const int pageSize = 10;
  static const Duration _searchDebounce = Duration(milliseconds: 400);

  // ── State ─────────────────────────────────────────────────────────────────

  List<AdminUserAccount> _users = <AdminUserAccount>[];
  AdminUsersStats _stats = AdminUsersStats.empty;

  bool _isLoading = false;
  String? _error;
  bool _hasLoadedOnce = false;

  int _page = 1;
  int _total = 0;

  String _search = '';
  AdminAccountStatus? _statusFilter; // null = all
  Timer? _searchTimer;

  final Set<String> _mutatingIds = <String>{};

  // ── Getters ───────────────────────────────────────────────────────────────

  List<AdminUserAccount> get users => List<AdminUserAccount>.unmodifiable(_users);
  AdminUsersStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _hasLoadedOnce && !_isLoading && _users.isEmpty;

  int get page => _page;
  int get total => _total;
  int get pageCount => _total == 0 ? 1 : (_total / pageSize).ceil();
  bool get canPrev => _page > 1 && !_isLoading;
  bool get canNext => _page < pageCount && !_isLoading;

  /// Row index of the first / last account shown, 1-based (for "Showing x–y").
  int get rangeStart => _users.isEmpty ? 0 : (_page - 1) * pageSize + 1;
  int get rangeEnd => (_page - 1) * pageSize + _users.length;

  String get search => _search;
  AdminAccountStatus? get statusFilter => _statusFilter;
  bool isMutating(String userId) => _mutatingIds.contains(userId);

  // ── Loading ───────────────────────────────────────────────────────────────

  /// Safe to call on every build; only the first call fetches.
  Future<void> loadInitial() async {
    if (_hasLoadedOnce || _isLoading) {
      return;
    }
    await Future.wait(<Future<void>>[_loadPage(1), _loadStats()]);
  }

  Future<void> refresh() =>
      Future.wait(<Future<void>>[_loadPage(_page), _loadStats()]);

  // ── Pagination ────────────────────────────────────────────────────────────

  Future<void> goToPage(int page) async {
    final int target = page.clamp(1, pageCount);
    if (target == _page || _isLoading) {
      return;
    }
    await _loadPage(target);
  }

  Future<void> nextPage() => goToPage(_page + 1);
  Future<void> prevPage() => goToPage(_page - 1);

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSearch(String value) {
    final String next = value.trim();
    if (next == _search) {
      return;
    }
    _search = next;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => _loadPage(1));
  }

  void setStatusFilter(AdminAccountStatus? status) {
    if (status == _statusFilter) {
      return;
    }
    _statusFilter = status;
    _loadPage(1);
  }

  // ── Suspend / reactivate ──────────────────────────────────────────────────

  Future<bool> suspendUser(String userId, int days) =>
      _mutate(userId, AdminAccountStatus.suspended, suspendDays: days);

  Future<bool> reactivateUser(String userId) =>
      _mutate(userId, AdminAccountStatus.active);

  Future<bool> _mutate(
    String userId,
    AdminAccountStatus status, {
    int? suspendDays,
  }) async {
    if (_mutatingIds.contains(userId)) {
      return false;
    }
    _mutatingIds.add(userId);
    notifyListeners();

    try {
      await _service.updateStatus(
        userId: userId,
        status: status,
        suspendDays: suspendDays,
      );
      // Re-pull the current page + stats so the row and counts reflect the server.
      await Future.wait(<Future<void>>[_loadPage(_page), _loadStats()]);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not update this account. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _mutatingIds.remove(userId);
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

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _loadPage(int page) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final AdminUsersPage result = await _service.fetchUsers(
        page: page,
        limit: pageSize,
        search: _search,
        status: _statusFilter,
      );
      _users = result.items;
      _total = result.total;
      _page = result.page < 1 ? page : result.page;
      _error = null;
    } on ApiException catch (failure) {
      _users = <AdminUserAccount>[];
      _error = failure.message;
    } catch (_) {
      _users = <AdminUserAccount>[];
      _error = 'Unable to load users. Please try again.';
    } finally {
      _isLoading = false;
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  Future<void> _loadStats() async {
    try {
      _stats = await _service.fetchStats();
      notifyListeners();
    } on ApiException catch (_) {
      // Non-critical — the list itself still renders.
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
