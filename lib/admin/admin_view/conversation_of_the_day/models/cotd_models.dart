// Models for Conversation of the Day (COTD).

enum CotdStatus { live, ended }

extension CotdStatusX on CotdStatus {
  String get label => this == CotdStatus.live ? 'Live' : 'Ended';

  static CotdStatus parse(String? raw) =>
      raw == 'live' ? CotdStatus.live : CotdStatus.ended;
}

/// One row from GET /admin/cotd/history (and the POST /admin/cotd response,
/// which omits the counts).
class CotdQuestion {
  const CotdQuestion({
    required this.id,
    required this.question,
    required this.publishedAt,
    required this.answerCount,
    required this.reports,
    required this.status,
    this.createdBy,
  });

  factory CotdQuestion.fromJson(Map<String, dynamic> json) {
    return CotdQuestion(
      id: json['id'] as String,
      question: json['question'] as String? ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: json['createdBy'] as String?,
      answerCount: (json['answerCount'] as num?)?.toInt() ?? 0,
      reports: (json['reports'] as num?)?.toInt() ?? 0,
      status: CotdStatusX.parse(json['status'] as String?),
    );
  }

  final String id;
  final String question;
  final DateTime publishedAt;
  final String? createdBy;
  final int answerCount;
  final int reports;
  final CotdStatus status;

  bool get isLive => status == CotdStatus.live;
}

/// One answer from GET /engagement/cotd/:id/answers.
class CotdAnswer {
  CotdAnswer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.body,
    required this.createdAt,
    required this.featured,
    required this.hidden,
  });

  factory CotdAnswer.fromJson(Map<String, dynamic> json) {
    return CotdAnswer(
      id: json['id'] as String,
      questionId: json['questionId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      featured: json['featured'] as bool? ?? false,
      hidden: json['hidden'] as bool? ?? false,
    );
  }

  final String id;
  final String questionId;
  final String userId;
  final String body;
  final DateTime createdAt;

  // Mutable so a feature/hide result can be applied in place.
  bool featured;
  bool hidden;

  /// A short, stable handle from the user id (the API returns no username).
  String get handle => '@${userId.split('-').first}';
}
