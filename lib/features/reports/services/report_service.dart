// Report service -- wraps POST /reports with mock support.

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../models/report_models.dart';

class ReportService {
  const ReportService(this._client);

  final ApiClient _client;

  // POST /reports -- returns a [ReportResponse] containing the displayId
  // (case number, e.g. "QL-84226") shown to the user after submission.
  Future<ReportResponse> createReport(CreateReportRequest request) async {
    if (AppConfig.useMockApi) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final int mockNum = 80000 + Random().nextInt(9999);
      debugPrint('[Reports] Mock API ON. Returning mock report QL-$mockNum.');
      return ReportResponse(
        id: 'mock_report_$mockNum',
        displayId: 'QL-$mockNum',
        priority: _mockPriority(request.reason),
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    debugPrint(
        '[Reports] Creating report: ${request.targetType.value} '
        '(targetId=${request.targetId}, '
        'targetOwnerId=${request.targetOwnerId}, '
        'reason=${request.reason.value})');

    try {
      final dynamic data = await _client.post(
        ApiEndpoints.reports,
        body: request.toJson(),
      );

      if (data is Map<String, dynamic>) {
        return ReportResponse.fromJson(data);
      }

      // Some gateways return the report nested under a 'data' or 'report' key.
      if (data is Map) {
        final dynamic nested = data['data'] ?? data['report'];
        if (nested is Map<String, dynamic>) {
          return ReportResponse.fromJson(nested);
        }
      }

      throw const ApiException(
        'Unexpected response format from POST /reports',
        kind: ApiErrorKind.unknown,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Report submission failed: $e',
        kind: ApiErrorKind.unknown,
      );
    }
  }

  String _mockPriority(ReportReason reason) => switch (reason) {
        ReportReason.threats || ReportReason.selfHarm => 'urgent',
        ReportReason.harassment ||
        ReportReason.hateSpeech ||
        ReportReason.outing =>
          'high',
        _ => 'normal',
      };
}
