
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/analytics_dashboard.dart';
import 'models/analytics_overview.dart';

class AnalyticsService {
  const AnalyticsService(this._client);

  final ApiClient _client;

  Future<AnalyticsOverview> fetchOverview({String range = '30d'}) async {
    debugPrint('🚀 [AnalyticsService] GET ${ApiEndpoints.adminAnalyticsOverview}?range=$range');
    final dynamic data = await _client.get(
      ApiEndpoints.adminAnalyticsOverview,
      query: <String, dynamic>{'range': range},
      useCache: false,
    );
    return AnalyticsOverview.fromJson(data as Map<String, dynamic>);
  }

  Future<AnalyticsDashboard> fetchDashboard({String range = '30d'}) async {
    debugPrint('🚀 [AnalyticsService] GET ${ApiEndpoints.adminAnalyticsDashboard}?range=$range');
    final dynamic data = await _client.get(
      ApiEndpoints.adminAnalyticsDashboard,
      query: <String, dynamic>{'range': range},
      useCache: false,
    );
    return AnalyticsDashboard.fromJson(data as Map<String, dynamic>);
  }
}
