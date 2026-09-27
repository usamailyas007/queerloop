import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _currentUserId;

  CotdQuestion? get currentQuestion => _currentQuestion;
  List<CotdAnswer> get answers => List<CotdAnswer>.unmodifiable(_answers);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasAnswered => _hasAnswered;
  String? get error => _error;

  void updateUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _checkHasAnswered();
    }
  }

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
        await _checkHasAnswered();
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

  Future<void> _checkHasAnswered() async {
    final String? qid = _currentQuestion?.id;
    if (qid == null || qid.isEmpty) return;

    if (_currentQuestion?.hasAnswered == true) {
      _hasAnswered = true;
      notifyListeners();
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> globalAnswered =
          prefs.getStringList('cotd_answered_questions_global') ?? <String>[];
      if (globalAnswered.contains(qid)) {
        _hasAnswered = true;
        notifyListeners();
        return;
      }

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        final List<String> userAnswers =
            prefs.getStringList('cotd_answered_questions_$_currentUserId') ??
                <String>[];
        if (userAnswers.contains(qid)) {
          _hasAnswered = true;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      final bool alreadyInAnswers = _answers.any((CotdAnswer a) =>
          a.authorId.isNotEmpty && a.authorId == _currentUserId);
      if (alreadyInAnswers) {
        _hasAnswered = true;
        _saveAnsweredQuestionLocally(qid);
        notifyListeners();
      }
    }
  }

  Future<void> _saveAnsweredQuestionLocally(String qid) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> globalList =
          prefs.getStringList('cotd_answered_questions_global') ?? <String>[];
      if (!globalList.contains(qid)) {
        globalList.add(qid);
        await prefs.setStringList('cotd_answered_questions_global', globalList);
      }

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        final List<String> userList =
            prefs.getStringList('cotd_answered_questions_$_currentUserId') ??
                <String>[];
        if (!userList.contains(qid)) {
          userList.add(qid);
          await prefs.setStringList(
              'cotd_answered_questions_$_currentUserId', userList);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [CotdProvider] Error saving answered question locally: $e');
    }
  }

  Future<void> _fetchAnswersIfNeeded(String questionId) async {
    if (_answers.isNotEmpty) return;
    try {
      _answers = await _service.fetchAnswers(questionId);
      await _checkHasAnswered();
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch (or refresh) the answers for the current question.
  Future<void> fetchAnswers() async {
    final String? qid = _currentQuestion?.id;
    if (qid == null || qid.isEmpty) return;
    try {
      _answers = await _service.fetchAnswers(qid);
      await _checkHasAnswered();
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
        await _saveAnsweredQuestionLocally(qid);
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
