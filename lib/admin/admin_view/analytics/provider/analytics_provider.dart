
import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../analytics_service.dart';
import '../models/analytics_dashboard.dart';
import '../models/analytics_overview.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider({required ApiClient client, AnalyticsService? service})
      : _service = service ?? AnalyticsService(client);

  final AnalyticsService _service;

  String _range = '30d';
  AnalyticsOverview? _overview;
  AnalyticsDashboard? _dashboard;

  bool _isLoadingOverview = false;
  bool _isLoadingDashboard = false;

  String? _overviewError;
  String? _dashboardError;
  bool _hasLoadedOnce = false;

  String get range => _range;
  AnalyticsOverview? get overview => _overview;
  AnalyticsDashboard? get dashboard => _dashboard;

  bool get isLoadingOverview => _isLoadingOverview;
  bool get isLoadingDashboard => _isLoadingDashboard;
  bool get isLoading => _isLoadingOverview || _isLoadingDashboard;

  String? get overviewError => _overviewError;
  String? get dashboardError => _dashboardError;
  String? get error => _overviewError ?? _dashboardError;
  bool get hasLoadedOnce => _hasLoadedOnce;

  Future<void> loadInitial() async {
    if (_hasLoadedOnce || isLoading) {
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    await Future.wait<void>(<Future<void>>[
      fetchOverview(),
      fetchDashboard(),
    ]);
    _hasLoadedOnce = true;
  }

  void setRange(String nextRange) {
    if (_range == nextRange) {
      return;
    }
    _range = nextRange;
    notifyListeners();
    refresh();
  }

  Future<void> fetchOverview() async {
    _isLoadingOverview = true;
    _overviewError = null;
    notifyListeners();
    try {
      _overview = await _service.fetchOverview(range: _range);
      _overviewError = null;
    } on ApiException catch (failure) {
      _overviewError = failure.message;
    } catch (_) {
      _overviewError = 'Unable to load analytics overview. Please try again.';
    } finally {
      _isLoadingOverview = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboard() async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.fetchDashboard(range: _range);
      _dashboardError = null;
    } on ApiException catch (failure) {
      _dashboardError = failure.message;
    } catch (_) {
      _dashboardError = 'Unable to load dashboard analytics. Please try again.';
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  void clearErrors() {
    if (_overviewError == null && _dashboardError == null) {
      return;
    }
    _overviewError = null;
    _dashboardError = null;
    notifyListeners();
  }
}
