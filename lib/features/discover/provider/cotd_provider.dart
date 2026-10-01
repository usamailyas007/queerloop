import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cotd_models.dart';
import '../services/cotd_service.dart';

/// Manages the Conversation of the Day state and answer submissions.
class CotdProvider extends ChangeNotifier {
  CotdProvider({required CotdService service}) : _service = service {
    _activeInstance = this;
    _loadCurrentQuestion();
  }

  static CotdProvider? _activeInstance;

  /// Clear in-memory COTD state and cache (e.g. on logout).
  static void clearGlobalCache() {
    _activeInstance?.clearAll();
  }

  /// Full reset of COTD state.
  void clearAll() {
    _currentQuestion = null;
    _answers = <CotdAnswer>[];
    _isLoading = false;
    _isSubmitting = false;
    _hasAnswered = false;
    _error = null;
    _currentUserId = null;
    _currentUsername = null;
    notifyListeners();
  }

  final CotdService _service;

  CotdQuestion? _currentQuestion;
  List<CotdAnswer> _answers = <CotdAnswer>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _hasAnswered = false;
  String? _error;
  String? _currentUserId;
  String? _currentUsername;

  CotdQuestion? get currentQuestion => _currentQuestion;
  List<CotdAnswer> get answers => List<CotdAnswer>.unmodifiable(_answers);
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get hasAnswered => _hasAnswered;
  String? get error => _error;

  void updateUserInfo({String? userId, String? username}) {
    bool changed = false;
    if (_currentUserId != userId) {
      _currentUserId = userId;
      changed = true;
    }
    if (_currentUsername != username) {
      _currentUsername = username;
      changed = true;
    }
    if (changed) {
      _checkHasAnswered();
    }
  }

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
        // Fetch answers to verify if current user has answered
        await fetchAnswers();
      } else {
        _hasAnswered = false;
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
    if (qid == null || qid.isEmpty) {
      if (_hasAnswered) {
        _hasAnswered = false;
        notifyListeners();
      }
      return;
    }

    // 1. If backend explicitly returned hasAnswered for this authenticated user
    if (_currentQuestion?.hasAnswered == true) {
      if (!_hasAnswered) {
        _hasAnswered = true;
        notifyListeners();
      }
      return;
    }

    // 2. Clear any legacy global cache that poisoned the device across accounts
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey('cotd_answered_questions_global')) {
        await prefs.remove('cotd_answered_questions_global');
      }
    } catch (_) {}

    // 3. If user is logged in, check if their answer is in the answers list
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      final bool alreadyInAnswers = _answers.any((CotdAnswer a) =>
          (a.authorId.isNotEmpty && a.authorId == _currentUserId) ||
          (_currentUsername != null &&
              _currentUsername!.isNotEmpty &&
              a.authorUsername != null &&
              a.authorUsername!.toLowerCase() ==
                  _currentUsername!.toLowerCase()));

      if (alreadyInAnswers) {
        if (!_hasAnswered) {
          _hasAnswered = true;
          notifyListeners();
        }
        await _saveAnsweredQuestionLocally(qid);
        return;
      }

      // Check user-specific SharedPreferences
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String> userAnswers =
            prefs.getStringList('cotd_answered_questions_$_currentUserId') ??
                <String>[];
        if (userAnswers.contains(qid)) {
          if (!_hasAnswered) {
            _hasAnswered = true;
            notifyListeners();
          }
          return;
        }
      } catch (_) {}

      // Current user has NOT answered this question
      if (_hasAnswered) {
        _hasAnswered = false;
        notifyListeners();
      }
      return;
    }

    // Guest or unknown user has NOT answered
    if (_hasAnswered) {
      _hasAnswered = false;
      notifyListeners();
    }
  }

  Future<void> _saveAnsweredQuestionLocally(String qid) async {
    try {
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
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

  @override
  void dispose() {
    if (_activeInstance == this) {
      _activeInstance = null;
    }
    super.dispose();
  }
}
