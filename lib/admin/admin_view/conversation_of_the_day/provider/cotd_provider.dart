// Owns Conversation of the Day: the question history, the publish flow, and the
// answers (with feature/hide) for a selected question.
// Mirrors features/auth/auth_provider.dart conventions (isBusy/error, selective
// notifyListeners()).

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../cotd_service.dart';
import '../models/cotd_models.dart';

class CotdProvider extends ChangeNotifier {
  CotdProvider({required ApiClient client, CotdService? service})
      : _service = service ?? CotdService(client);

  final CotdService _service;

  // ── History ───────────────────────────────────────────────────────────────

  List<CotdQuestion> _history = <CotdQuestion>[];
  bool _isLoadingHistory = false;
  bool _isPublishing = false;
  String? _historyError;
  bool _hasLoadedHistory = false;

  List<CotdQuestion> get history => List<CotdQuestion>.unmodifiable(_history);
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isPublishing => _isPublishing;
  String? get historyError => _historyError;
  bool get isHistoryEmpty =>
      _hasLoadedHistory && !_isLoadingHistory && _history.isEmpty;

  CotdQuestion? get liveQuestion {
    for (final CotdQuestion q in _history) {
      if (q.isLive) return q;
    }
    return _history.isNotEmpty ? _history.first : null;
  }

  Future<void> loadHistory() async {
    if (_hasLoadedHistory || _isLoadingHistory) {
      return;
    }
    await refreshHistory();
  }

  Future<void> refreshHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      _history = await _service.fetchHistory();
      _historyError = null;
    } on ApiException catch (failure) {
      _historyError = failure.message;
    } catch (_) {
      _historyError = 'Unable to load history. Please try again.';
    } finally {
      _isLoadingHistory = false;
      _hasLoadedHistory = true;
      notifyListeners();
    }
  }

  /// Returns the published question on success, null on failure (`historyError` set).
  Future<CotdQuestion?> publishQuestion(String question) async {
    final String text = question.trim();
    if (text.isEmpty || _isPublishing) {
      return null;
    }
    _isPublishing = true;
    _historyError = null;
    notifyListeners();
    try {
      final CotdQuestion created = await _service.publishQuestion(text);
      await _service.fetchHistory().then((List<CotdQuestion> h) => _history = h);
      return created;
    } on ApiException catch (failure) {
      _historyError = failure.message;
      return null;
    } catch (_) {
      _historyError = 'Could not publish the question. Please try again.';
      return null;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  // ── Answers (per selected question) ───────────────────────────────────────

  CotdQuestion? _selected;
  List<CotdAnswer> _answers = <CotdAnswer>[];
  bool _isLoadingAnswers = false;
  String? _answersError;
  final Set<String> _mutatingAnswerIds = <String>{};

  CotdQuestion? get selectedQuestion => _selected;
  List<CotdAnswer> get answers => List<CotdAnswer>.unmodifiable(_answers);
  bool get isLoadingAnswers => _isLoadingAnswers;
  String? get answersError => _answersError;
  bool get isAnswersEmpty => !_isLoadingAnswers && _answers.isEmpty;
  bool isAnswerMutating(String id) => _mutatingAnswerIds.contains(id);

  Future<void> openAnswers(CotdQuestion question) async {
    _selected = question;
    _answers = <CotdAnswer>[];
    _answersError = null;
    await _loadAnswers();
  }

  Future<void> refreshAnswers() => _loadAnswers();

  Future<void> _loadAnswers() async {
    final CotdQuestion? question = _selected;
    if (question == null) {
      return;
    }
    _isLoadingAnswers = true;
    _answersError = null;
    notifyListeners();
    try {
      _answers = await _service.fetchAnswers(question.id);
      _answersError = null;
    } on ApiException catch (failure) {
      _answersError = failure.message;
    } catch (_) {
      _answersError = 'Unable to load answers. Please try again.';
    } finally {
      _isLoadingAnswers = false;
      notifyListeners();
    }
  }

  Future<bool> featureAnswer(String answerId) =>
      _mutateAnswer(answerId, _service.featureAnswer);

  Future<bool> hideAnswer(String answerId) =>
      _mutateAnswer(answerId, _service.hideAnswer);

  Future<bool> _mutateAnswer(
    String answerId,
    Future<CotdAnswer> Function(String) call,
  ) async {
    if (_mutatingAnswerIds.contains(answerId)) {
      return false;
    }
    _mutatingAnswerIds.add(answerId);
    notifyListeners();
    try {
      final CotdAnswer updated = await call(answerId);
      final int i = _answers.indexWhere((CotdAnswer a) => a.id == answerId);
      if (i != -1) {
        _answers[i]
          ..featured = updated.featured
          ..hidden = updated.hidden;
      }
      return true;
    } on ApiException catch (failure) {
      _answersError = failure.message;
      return false;
    } catch (_) {
      _answersError = 'Could not update this answer. Please try again.';
      return false;
    } finally {
      _mutatingAnswerIds.remove(answerId);
      notifyListeners();
    }
  }

  void clearAnswersError() {
    if (_answersError == null) {
      return;
    }
    _answersError = null;
    notifyListeners();
  }
}
