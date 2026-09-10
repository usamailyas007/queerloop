// Moderator Reports service — every /mod/* call.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).
// Role (moderator/admin) comes from the JWT — never sent in the request.

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/mod_report.dart';

enum ModReportSort { priority, oldest, newest }

class ModReportsService {
  const ModReportsService(this._client);

  final ApiClient _client;

  Future<ModDashboard> fetchDashboard() async {
    debugPrint('🚀 [ModReportsService] GET ${ApiEndpoints.modDashboard}');
    final dynamic data =
        await _client.get(ApiEndpoints.modDashboard, useCache: false);
    return ModDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<ModReportsPage> fetchReports({
    ReportStatus? status,
    bool urgentOnly = false,
    String? search,
    ModReportSort sort = ModReportSort.priority,
    int limit = 20,
    int offset = 0,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'sort': sort.name,
      if (status != null && status != ReportStatus.unknown)
        'status': _statusWire(status),
      if (urgentOnly) 'urgentOnly': true,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    debugPrint('🚀 [ModReportsService] GET ${ApiEndpoints.modReports} $query');
    final dynamic data = await _client.get(
      ApiEndpoints.modReports,
      query: query,
      useCache: false,
    );
    return ModReportsPage.fromJson(data as Map<String, dynamic>);
  }

  Future<ModReport> fetchReport(String id) async {
    debugPrint('🚀 [ModReportsService] GET ${ApiEndpoints.modReport(id)}');
    final dynamic data =
        await _client.get(ApiEndpoints.modReport(id), useCache: false);
    return ModReport.fromJson(data as Map<String, dynamic>);
  }

  /// Pass the report's `targetOwnerId` — never `targetId`.
  Future<AccountHistory> fetchAccountHistory(String targetOwnerId) async {
    debugPrint('🚀 [ModReportsService] GET ${ApiEndpoints.modAccountHistory(targetOwnerId)}');
    final dynamic data = await _client.get(
      ApiEndpoints.modAccountHistory(targetOwnerId),
      useCache: false,
    );
    return AccountHistory.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /mod/reports/:id/assign — no body. Server sets status=in_review,
  /// assignedTo=current moderator.
  Future<ModReport> assignReport(String id) async {
    debugPrint('🚀 [ModReportsService] PATCH ${ApiEndpoints.modReportAssign(id)}');
    final dynamic data = await _client.patch(ApiEndpoints.modReportAssign(id));
    return ModReport.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /mod/reports/:id/decision — `note` is mandatory (1–1000 chars).
  Future<ModReport> decideReport({
    required String id,
    required ModDecision decision,
    required String note,
  }) async {
    debugPrint('🚀 [ModReportsService] PATCH ${ApiEndpoints.modReportDecision(id)} (${decision.wire})');
    final dynamic data = await _client.patch(
      ApiEndpoints.modReportDecision(id),
      body: <String, dynamic>{'decision': decision.wire, 'note': note},
    );
    return ModReport.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /mod/reports/:id/reopen — only works on a resolved report.
  Future<ModReport> reopenReport({
    required String id,
    required String note,
  }) async {
    debugPrint('🚀 [ModReportsService] PATCH ${ApiEndpoints.modReportReopen(id)}');
    final dynamic data = await _client.patch(
      ApiEndpoints.modReportReopen(id),
      body: <String, dynamic>{'note': note},
    );
    return ModReport.fromJson(data as Map<String, dynamic>);
  }

  static String _statusWire(ReportStatus s) => switch (s) {
        ReportStatus.open => 'open',
        ReportStatus.inReview => 'in_review',
        ReportStatus.escalated => 'escalated',
        ReportStatus.resolved => 'resolved',
        ReportStatus.unknown => 'open',
      };
}
