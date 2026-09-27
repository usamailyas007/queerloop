import 'package:flutter/foundation.dart';

import '../models/cotd_models.dart';
import '../services/cotd_service.dart';

/// Manages the Conversation of the Day state and answer submissions.
class CotdProvider extends ChangeNotifier {
  CotdProvider({required CotdService service}) : _service = service {
    _loadCurrentQuestion();
  }

  final CotdService _service;

  CotdQuestion? _currentQuestion;
  List<CotdAnswer> _answers = <CotdAnswer>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasAnswered = false;
  String? _error;

  CotdQuestion? get currentQuestion => _currentQuestion;
  List<CotdAnswer> get answers => List<CotdAnswer>.unmodifiable(_answers);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasAnswered => _hasAnswered;
  String? get error => _error;

  /// Reload the current question (e.g. on pull-to-refresh).
  Future<void> refresh() async {
    await _loadCurrentQuestion(refresh: true);
  }

  Future<void> _loadCurrentQuestion({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final CotdQuestion? question = await _service.fetchCurrentQuestion();
      _currentQuestion = question;
      if (question != null) {
        _hasAnswered = question.hasAnswered;
        // Pre-load answers in the background
        _fetchAnswersIfNeeded(question.id);
      }
    } catch (e) {
      _error = 'Could not load today\'s question.';
      debugPrint('❌ [CotdProvider] _loadCurrentQuestion: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAnswersIfNeeded(String questionId) async {
    if (_answers.isNotEmpty) return;
    try {
      _answers = await _service.fetchAnswers(questionId);
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch (or refresh) the answers for the current question.
  Future<void> fetchAnswers() async {
    final String? qid = _currentQuestion?.id;
    if (qid == null || qid.isEmpty) return;
    try {
      _answers = await _service.fetchAnswers(qid);
      notifyListeners();
    } catch (_) {}
  }

  /// Submit an answer to the current question.
  /// Returns true on success.
  Future<bool> submitAnswer(String body) async {
    final String? qid = _currentQuestion?.id;
    if (qid == null || qid.isEmpty || body.trim().isEmpty) return false;
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final bool ok = await _service.submitAnswer(
        questionId: qid,
        body: body.trim(),
      );
      if (ok) {
        _hasAnswered = true;
        // Refresh answers and update count optimistically
        await fetchAnswers();
      }
      return ok;
    } catch (e) {
      _error = 'Could not submit your answer. Please try again.';
      debugPrint('❌ [CotdProvider] submitAnswer: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
