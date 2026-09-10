// Report feature models — enums and value types for POST /reports.

/// The content type being reported.
enum ReportTargetType {
  user,
  post,
  comment,
  conversation,
  cotdAnswer;

  /// Wire value sent to the server.
  String get value => switch (this) {
        ReportTargetType.user => 'user',
        ReportTargetType.post => 'post',
        ReportTargetType.comment => 'comment',
        ReportTargetType.conversation => 'conversation',
        ReportTargetType.cotdAnswer => 'cotd_answer',
      };
}

/// Reason codes accepted by the server.
enum ReportReason {
  threats,
  selfHarm,
  harassment,
  hateSpeech,
  spam,
  outing,
  sexualContent,
  other;

  /// Wire value sent to the server.
  String get value => switch (this) {
        ReportReason.threats => 'threats',
        ReportReason.selfHarm => 'self_harm',
        ReportReason.harassment => 'harassment',
        ReportReason.hateSpeech => 'hate_speech',
        ReportReason.spam => 'spam',
        ReportReason.outing => 'outing',
        ReportReason.sexualContent => 'sexual_content',
        ReportReason.other => 'other',
      };

  /// Human-readable label shown in bottom sheets.
  String get label => switch (this) {
        ReportReason.threats => 'Violence or threats',
        ReportReason.selfHarm => 'Self-harm or suicide',
        ReportReason.harassment => 'Harassment or bullying',
        ReportReason.hateSpeech => 'Hate speech or slurs',
        ReportReason.spam => 'Spam or a fake account',
        ReportReason.outing => 'Outing someone without consent',
        ReportReason.sexualContent => 'Sexual content or nudity',
        ReportReason.other => 'Something else',
      };
}

class CreateReportRequest {
  CreateReportRequest({
    required this.targetType,
    required this.targetId,
    required this.targetOwnerId,
    required this.reason,
    this.communityId,
  }) : assert(
          targetOwnerId.isNotEmpty,
          'targetOwnerId must be supplied — it is the userId of the content owner, '
          'NOT the content id. For targetType.user, use the same value as targetId.',
        );

  final ReportTargetType targetType;
  final String targetId;

  /// The userId of whoever owns the content (post/comment/conversation author,
  /// or the same as [targetId] when [targetType] is [ReportTargetType.user]).
  final String targetOwnerId;
  final ReportReason reason;
  final String? communityId;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> body = <String, dynamic>{
      'targetType': targetType.value,
      'targetId': targetId,
      'targetOwnerId': targetOwnerId,
      'reason': reason.value,
    };
    if (communityId != null && communityId!.isNotEmpty) {
      body['communityId'] = communityId;
    }
    return body;
  }
}

class ReportResponse {
  const ReportResponse({
    required this.id,
    required this.displayId,
    this.priority,
    this.status,
    this.createdAt,
  });

  final String id;

  /// Case number shown to the user, e.g. "QL-84226".
  final String displayId;
  final String? priority;
  final String? status;
  final String? createdAt;

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      displayId:
          (json['displayId'] ?? json['display_id'] ?? json['id'] ?? 'QL-00000')
              .toString(),
      priority: json['priority']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
