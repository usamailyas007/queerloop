// Models for the Conversation of the Day (CotD) feature.

class CotdQuestion {
  const CotdQuestion({
    required this.id,
    required this.body,
    required this.answerCount,
    required this.createdAt,
    this.hasAnswered = false,
  });

  factory CotdQuestion.fromJson(Map<String, dynamic> json) {
    return CotdQuestion(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ??
          json['question'] as String? ??
          json['text'] as String? ??
          '',
      answerCount: (json['answerCount'] as num?)?.toInt() ??
          (json['answers'] as num?)?.toInt() ??
          0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      hasAnswered: json['hasAnswered'] as bool? ?? false,
    );
  }

  final String id;
  final String body;
  final int answerCount;
  final DateTime createdAt;
  final bool hasAnswered;

  /// Formatted short count: "2.1K answered"
  String get formattedAnswerCount {
    if (answerCount >= 1000000) {
      return '${(answerCount / 1000000).toStringAsFixed(1)}M answered';
    } else if (answerCount >= 1000) {
      return '${(answerCount / 1000).toStringAsFixed(1)}K answered';
    }
    return '$answerCount answered';
  }

  /// Short subtitle shown on the card
  String get subtitle {
    if (answerCount >= 1000000) {
      return '${(answerCount / 1000000).toStringAsFixed(1)}M people have answered — add your voice, or just read what others said.';
    } else if (answerCount >= 1000) {
      return '${(answerCount / 1000).toStringAsFixed(1)}K people have answered — add your voice, or just read what others said.';
    } else if (answerCount == 0) {
      return 'Be the first to answer — share your voice.';
    }
    return '$answerCount people have answered — add your voice, or just read what others said.';
  }
}

class CotdAnswer {
  const CotdAnswer({
    required this.id,
    required this.body,
    required this.authorId,
    required this.createdAt,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
  });

  factory CotdAnswer.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? author =
        json['author'] as Map<String, dynamic>?;
    return CotdAnswer(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      authorId: json['authorId'] as String? ??
          author?['userId'] as String? ??
          '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      authorUsername: author?['username'] as String?,
      authorDisplayName: author?['displayName'] as String?,
      authorAvatarUrl: author?['avatarUrl'] as String?,
    );
  }

  final String id;
  final String body;
  final String authorId;
  final DateTime createdAt;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  String get displayName =>
      authorDisplayName?.isNotEmpty == true
          ? authorDisplayName!
          : authorUsername ?? 'Anonymous';
}
