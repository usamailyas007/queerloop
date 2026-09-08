// Report provider -- ChangeNotifier that calls ReportService and tracks state.

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../models/report_models.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  ReportProvider({required ReportService service}) : _service = service;

  final ReportService _service;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  // Submits a report. Returns the displayId on success, null on failure.
  Future<String?> submitReport(CreateReportRequest request) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ReportResponse response = await _service.createReport(request);
      debugPrint('[ReportProvider] Report submitted: ${response.displayId}');
      return response.displayId;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('[ReportProvider] ApiException: ${e.message}');
      return null;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      debugPrint('[ReportProvider] Unknown error: $e');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
