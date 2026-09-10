// Owns the moderator reports flow: dashboard, the paginated queue with filters,
// and one selected report's detail + account history + actions.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../mod_reports_service.dart';
import '../models/mod_report.dart';

class ModReportsProvider extends ChangeNotifier {
  ModReportsProvider({required ApiClient client, ModReportsService? service})
      : _service = service ?? ModReportsService(client);

  final ModReportsService _service;

  static const int pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 400);

  // ── Dashboard ─────────────────────────────────────────────────────────────

  ModDashboard _dashboard = ModDashboard.empty;
  bool _isLoadingDashboard = false;
  String? _dashboardError;
  bool _dashboardLoadedOnce = false;

  ModDashboard get dashboard => _dashboard;
  bool get isLoadingDashboard => _isLoadingDashboard;
  String? get dashboardError => _dashboardError;

  Future<void> loadDashboard() async {
    if (_dashboardLoadedOnce || _isLoadingDashboard) {
      return;
    }
    await refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.fetchDashboard();
      _dashboardError = null;
    } on ApiException catch (failure) {
      _dashboardError = failure.message;
    } catch (_) {
      _dashboardError = 'Unable to load the dashboard. Please try again.';
    } finally {
      _isLoadingDashboard = false;
      _dashboardLoadedOnce = true;
      notifyListeners();
    }
  }

  // ── Queue ─────────────────────────────────────────────────────────────────

  List<ModReport> _reports = <ModReport>[];
  int _total = 0;
  int _offset = 0;
  bool _isLoadingQueue = false;
  String? _queueError;
  bool _queueLoadedOnce = false;

  ReportStatus? _statusFilter;
  bool _urgentOnly = false;
  ModReportSort _sort = ModReportSort.priority;
  String _search = '';
  Timer? _searchTimer;

  List<ModReport> get reports => List<ModReport>.unmodifiable(_reports);
  int get total => _total;
  bool get isLoadingQueue => _isLoadingQueue;
  String? get queueError => _queueError;
  bool get isQueueEmpty =>
      _queueLoadedOnce && !_isLoadingQueue && _reports.isEmpty;

  ReportStatus? get statusFilter => _statusFilter;
  bool get urgentOnly => _urgentOnly;
  ModReportSort get sort => _sort;
  String get search => _search;

  int get page => (_offset ~/ pageSize) + 1;
  int get pageCount => _total == 0 ? 1 : ((_total + pageSize - 1) ~/ pageSize);
  bool get canPrev => _offset > 0 && !_isLoadingQueue;
  bool get canNext => (_offset + _reports.length) < _total && !_isLoadingQueue;
  int get rangeStart => _reports.isEmpty ? 0 : _offset + 1;
  int get rangeEnd => _offset + _reports.length;

  Future<void> loadQueue() async {
    if (_queueLoadedOnce || _isLoadingQueue) {
      return;
    }
    await _fetchQueue(0);
  }

  Future<void> refreshQueue() => _fetchQueue(_offset);

  Future<void> nextPage() {
    if (!canNext) return Future<void>.value();
    return _fetchQueue(_offset + pageSize);
  }

  Future<void> prevPage() {
    if (!canPrev) return Future<void>.value();
    return _fetchQueue((_offset - pageSize).clamp(0, _offset));
  }

  void setStatusFilter(ReportStatus? status) {
    if (status == _statusFilter) return;
    _statusFilter = status;
    _fetchQueue(0);
  }

  void setUrgentOnly(bool value) {
    if (value == _urgentOnly) return;
    _urgentOnly = value;
    _fetchQueue(0);
  }

  void setSort(ModReportSort sort) {
    if (sort == _sort) return;
    _sort = sort;
    _fetchQueue(0);
  }

  void setSearch(String value) {
    final String next = value.trim();
    if (next == _search) return;
    _search = next;
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () => _fetchQueue(0));
  }

  Future<void> _fetchQueue(int offset) async {
    _isLoadingQueue = true;
    _queueError = null;
    notifyListeners();
    try {
      final ModReportsPage result = await _service.fetchReports(
        status: _statusFilter,
        urgentOnly: _urgentOnly,
        search: _search,
        sort: _sort,
        limit: pageSize,
        offset: offset,
      );
      _reports = result.items;
      _total = result.total;
      _offset = result.offset;
      _queueError = null;
    } on ApiException catch (failure) {
      _reports = <ModReport>[];
      _queueError = failure.message;
    } catch (_) {
      _reports = <ModReport>[];
      _queueError = 'Unable to load the queue. Please try again.';
    } finally {
      _isLoadingQueue = false;
      _queueLoadedOnce = true;
      notifyListeners();
    }
  }

  // ── Detail (one selected report) ─────────────────────────────────────────

  ModReport? _selected;
  AccountHistory? _history;
  bool _isLoadingDetail = false;
  bool _isActing = false;
  String? _detailError;

  ModReport? get selectedReport => _selected;
  AccountHistory? get accountHistory => _history;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isActing => _isActing;
  String? get detailError => _detailError;

  /// Open a report — pass whatever we have (a queue row or just an id) and it
  /// fetches the full report + the target owner's history.
  Future<void> openReport({ModReport? report, String? id}) async {
    _selected = report;
    _history = null;
    _detailError = null;
    notifyListeners();
    await _loadDetail(id ?? report!.id);
  }

  Future<void> refreshDetail() async {
    final ModReport? current = _selected;
    if (current != null) {
      await _loadDetail(current.id);
    }
  }

  Future<void> _loadDetail(String id) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();
    try {
      final ModReport report = await _service.fetchReport(id);
      _selected = report;
      // Account history keys off targetOwnerId, not targetId.
      final String? owner = report.targetOwnerId;
      _history = owner == null
          ? null
          : await _service.fetchAccountHistory(owner);
      _detailError = null;
    } on ApiException catch (failure) {
      _detailError = failure.message;
    } catch (_) {
      _detailError = 'Unable to load this report. Please try again.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> assignSelected() => _act(() {
        final ModReport r = _selected!;
        return _service.assignReport(r.id);
      });

  Future<bool> decideSelected(ModDecision decision, String note) => _act(() {
        final ModReport r = _selected!;
        return _service.decideReport(id: r.id, decision: decision, note: note);
      });

  Future<bool> reopenSelected(String note) => _act(() {
        final ModReport r = _selected!;
        return _service.reopenReport(id: r.id, note: note);
      });

  Future<bool> _act(Future<ModReport> Function() call) async {
    if (_selected == null || _isActing) {
      return false;
    }
    _isActing = true;
    _detailError = null;
    notifyListeners();
    try {
      _selected = await call();
      // Keep the queue + dashboard + action log in sync with the change.
      unawaited(_fetchQueue(_offset));
      unawaited(refreshDashboard());
      if (_actionLogLoadedOnce) unawaited(refreshActionLog());
      return true;
    } on ApiException catch (failure) {
      _detailError = failure.message;
      return false;
    } catch (_) {
      _detailError = 'Could not apply that action. Please try again.';
      return false;
    } finally {
      _isActing = false;
      notifyListeners();
    }
  }

  void clearDetailError() {
    if (_detailError == null) return;
    _detailError = null;
    notifyListeners();
  }

  // ── Action log (every decided / escalated report) ─────────────────────────

  List<ModReport> _actionLog = <ModReport>[];
  bool _isLoadingActionLog = false;
  String? _actionLogError;
  bool _actionLogLoadedOnce = false;

  List<ModReport> get actionLog => List<ModReport>.unmodifiable(_actionLog);
  bool get isLoadingActionLog => _isLoadingActionLog;
  String? get actionLogError => _actionLogError;
  bool get isActionLogEmpty =>
      _actionLogLoadedOnce && !_isLoadingActionLog && _actionLog.isEmpty;

  Future<void> loadActionLog() async {
    if (_actionLogLoadedOnce || _isLoadingActionLog) {
      return;
    }
    await refreshActionLog();
  }

  Future<void> refreshActionLog() async {
    _isLoadingActionLog = true;
    _actionLogError = null;
    notifyListeners();
    try {
      // The log is the set of reports that carry a moderation decision:
      // resolved ones, plus escalated ones (escalate doesn't resolve).
      final List<ModReportsPage> pages = await Future.wait(<Future<ModReportsPage>>[
        _service.fetchReports(
          status: ReportStatus.resolved,
          sort: ModReportSort.newest,
          limit: 100,
        ),
        _service.fetchReports(
          status: ReportStatus.escalated,
          sort: ModReportSort.newest,
          limit: 100,
        ),
      ]);
      final List<ModReport> merged = <ModReport>[
        ...pages[0].items,
        ...pages[1].items,
      ]..sort((ModReport a, ModReport b) => (b.resolvedAt ?? b.createdAt)
          .compareTo(a.resolvedAt ?? a.createdAt));
      _actionLog = merged;
      _actionLogError = null;
    } on ApiException catch (failure) {
      _actionLogError = failure.message;
    } catch (_) {
      _actionLogError = 'Unable to load the action log. Please try again.';
    } finally {
      _isLoadingActionLog = false;
      _actionLogLoadedOnce = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
