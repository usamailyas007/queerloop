// Models for the moderator reports flow (/mod/*).

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum ReportStatus { open, inReview, escalated, resolved, unknown }

extension ReportStatusX on ReportStatus {
  String get label => switch (this) {
        ReportStatus.open => 'Open',
        ReportStatus.inReview => 'In review',
        ReportStatus.escalated => 'Escalated',
        ReportStatus.resolved => 'Resolved',
        ReportStatus.unknown => '—',
      };

  static ReportStatus parse(String? raw) => switch (raw) {
        'open' => ReportStatus.open,
        'in_review' => ReportStatus.inReview,
        'escalated' => ReportStatus.escalated,
        'resolved' => ReportStatus.resolved,
        _ => ReportStatus.unknown,
      };
}

/// Server-computed. Never derive on the client — render the value directly.
enum ReportBadge { appeal, escalate, urgent, high, normal, none }

extension ReportBadgeX on ReportBadge {
  String get label => switch (this) {
        ReportBadge.appeal => 'Appeal',
        ReportBadge.escalate => 'Escalate',
        ReportBadge.urgent => 'Urgent',
        ReportBadge.high => 'High',
        ReportBadge.normal => 'Normal',
        ReportBadge.none => '—',
      };

  Color get color => switch (this) {
        ReportBadge.appeal => AppColors.moderatorPurple,
        ReportBadge.escalate => AppColors.moderatorPurpleAccent,
        ReportBadge.urgent => AppColors.danger,
        ReportBadge.high => AppColors.warning,
        ReportBadge.normal => AppColors.moderatorGray,
        ReportBadge.none => AppColors.moderatorGray,
      };

  static ReportBadge parse(String? raw) => switch (raw) {
        'appeal' => ReportBadge.appeal,
        'escalate' => ReportBadge.escalate,
        'urgent' => ReportBadge.urgent,
        'high' => ReportBadge.high,
        'normal' => ReportBadge.normal,
        _ => ReportBadge.none,
      };
}

/// Moderation decisions accepted by PATCH /mod/reports/:id/decision.
enum ModDecision {
  hideContent,
  warn,
  mute,
  suspend,
  ban,
  escalate,
  reversed,
  noAction,
}

extension ModDecisionX on ModDecision {
  String get wire => switch (this) {
        ModDecision.hideContent => 'hide_content',
        ModDecision.warn => 'warn',
        ModDecision.mute => 'mute',
        ModDecision.suspend => 'suspend',
        ModDecision.ban => 'ban',
        ModDecision.escalate => 'escalate',
        ModDecision.reversed => 'reversed',
        ModDecision.noAction => 'no_action',
      };

  String get title => switch (this) {
        ModDecision.hideContent => 'Hide the content',
        ModDecision.warn => 'Warn the account',
        ModDecision.mute => 'Mute the account',
        ModDecision.suspend => 'Suspend the account',
        ModDecision.ban => 'Ban permanently',
        ModDecision.escalate => 'Escalate to admin',
        ModDecision.reversed => 'Reverse a prior action',
        ModDecision.noAction => 'No action needed',
      };

  String get subtitle => switch (this) {
        ModDecision.hideContent => 'Removed from all feeds',
        ModDecision.warn => 'Sends a formal warning',
        ModDecision.mute => "Can read, can't post",
        ModDecision.suspend => 'Temporary lockout',
        ModDecision.ban => 'Admin only',
        ModDecision.escalate => "Hands it to an admin — doesn't resolve",
        ModDecision.reversed => 'Undo an earlier decision',
        ModDecision.noAction => 'Close with no penalty',
      };

  /// `ban` is admin-only — hide it for moderators.
  bool get adminOnly => this == ModDecision.ban;

  /// `escalate` sets status = escalated and does not resolve.
  bool get resolvesReport =>
      this != ModDecision.escalate;

  static ModDecision? parse(String? raw) => switch (raw) {
        'hide_content' => ModDecision.hideContent,
        'warn' => ModDecision.warn,
        'mute' => ModDecision.mute,
        'suspend' => ModDecision.suspend,
        'ban' => ModDecision.ban,
        'escalate' => ModDecision.escalate,
        'reversed' => ModDecision.reversed,
        'no_action' => ModDecision.noAction,
        _ => null,
      };
}

class ModReport {
  const ModReport({
    required this.id,
    required this.displayId,
    required this.reason,
    required this.targetType,
    required this.status,
    required this.priority,
    required this.badge,
    required this.isAppeal,
    required this.createdAt,
    this.reporterId,
    this.targetId,
    this.targetOwnerId,
    this.communityId,
    this.communityName,
    this.assignedTo,
    this.assignedToName,
    this.resolvedById,
    this.resolvedByName,
    this.decision,
    this.moderatorNote,
    this.resolvedAt,
  });

  factory ModReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? assignee =
        json['assignee'] as Map<String, dynamic>?;
    final Map<String, dynamic>? resolvedBy =
        json['resolvedBy'] as Map<String, dynamic>?;
    String? nameOf(Map<String, dynamic>? m) {
      if (m == null) return null;
      final Object? d = m['displayName'];
      final Object? u = m['username'];
      if (d is String && d.isNotEmpty) return d;
      if (u is String && u.isNotEmpty) return u;
      return null;
    }

    return ModReport(
      id: json['id'] as String,
      displayId: json['displayId'] as String? ?? '',
      reporterId: json['reporterId'] as String?,
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String?,
      targetOwnerId: json['targetOwnerId'] as String?,
      communityId: json['communityId'] as String?,
      communityName:
          (json['community'] as Map<String, dynamic>?)?['name'] as String?,
      reason: json['reason'] as String? ?? '',
      status: ReportStatusX.parse(json['status'] as String?),
      priority: (json['priority'] as num?)?.toInt() ?? 3,
      assignedTo:
          json['assignedTo'] as String? ?? assignee?['userId'] as String?,
      assignedToName: nameOf(assignee),
      resolvedById:
          json['resolvedBy'] is String ? json['resolvedBy'] as String : resolvedBy?['userId'] as String?,
      resolvedByName: nameOf(resolvedBy),
      decision: ModDecisionX.parse(json['decision'] as String?),
      moderatorNote: json['moderatorNote'] as String?,
      isAppeal: json['isAppeal'] as bool? ?? false,
      badge: ReportBadgeX.parse(json['badge'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      resolvedAt: DateTime.tryParse(json['resolvedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String displayId;
  final String? reporterId;
  final String targetType;
  final String? targetId;
  final String? targetOwnerId;
  final String? communityId;
  final String? communityName;
  final String reason;
  final ReportStatus status;
  final int priority; // 1 urgent, 2 high, 3 normal
  final String? assignedTo;
  final String? assignedToName;
  final String? resolvedById;
  final String? resolvedByName;
  final ModDecision? decision;
  final String? moderatorNote;
  final bool isAppeal;
  final ReportBadge badge;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// Human-friendly reason (`self_harm` → `Self harm`).
  String get reasonLabel =>
      reason.isEmpty ? '—' : reason.replaceAll('_', ' ').replaceFirstMapped(
            RegExp('^.'),
            (Match m) => m[0]!.toUpperCase(),
          );

  bool get isResolved => status == ReportStatus.resolved;
  bool get isAssigned => assignedTo != null;

  static String _shortId(String id) =>
      id.contains('-') ? '#${id.split('-').first}' : '#$id';

  /// Moderator the case is assigned to — name if known, else a short id.
  String? get assignedToLabel {
    if (assignedToName != null && assignedToName!.isNotEmpty) {
      return assignedToName;
    }
    return assignedTo == null ? null : _shortId(assignedTo!);
  }

  /// Moderator who resolved the case — name if known, else a short id.
  String? get resolvedByLabel {
    if (resolvedByName != null && resolvedByName!.isNotEmpty) {
      return resolvedByName;
    }
    return resolvedById == null ? null : _shortId(resolvedById!);
  }
}

class ModReportsPage {
  const ModReportsPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ModReportsPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['items'] as List<dynamic>? ?? <dynamic>[];
    return ModReportsPage(
      items: raw
          .map((dynamic e) => ModReport.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      limit: (json['limit'] as num?)?.toInt() ?? raw.length,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ModReport> items;
  final int total;
  final int limit;
  final int offset;
}

class ReasonCount {
  const ReasonCount({required this.reason, required this.count});

  factory ReasonCount.fromJson(Map<String, dynamic> json) => ReasonCount(
        reason: json['reason'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final String reason;
  final int count;

  String get label => reason.isEmpty
      ? '—'
      : reason.replaceAll('_', ' ').replaceFirstMapped(
            RegExp('^.'),
            (Match m) => m[0]!.toUpperCase(),
          );
}

class ModDashboard {
  const ModDashboard({
    required this.inQueue,
    required this.waitingOver12h,
    required this.resolvedToday,
    required this.resolvedTodayByMe,
    required this.escalated,
    required this.avgResponseHours,
    required this.reportsByReason,
    required this.needsYouFirst,
    required this.nextUp,
  });

  factory ModDashboard.fromJson(Map<String, dynamic> json) {
    List<ModReport> reports(String key) =>
        (json[key] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => ModReport.fromJson(e as Map<String, dynamic>))
            .toList();
    return ModDashboard(
      inQueue: (json['inQueue'] as num?)?.toInt() ?? 0,
      waitingOver12h: (json['waitingOver12h'] as num?)?.toInt() ?? 0,
      resolvedToday: (json['resolvedToday'] as num?)?.toInt() ?? 0,
      resolvedTodayByMe: (json['resolvedTodayByMe'] as num?)?.toInt() ?? 0,
      escalated: (json['escalated'] as num?)?.toInt() ?? 0,
      avgResponseHours: (json['avgResponseHours'] as num?)?.toDouble() ?? 0,
      reportsByReason: (json['reportsByReason'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => ReasonCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      needsYouFirst: reports('needsYouFirst'),
      nextUp: reports('nextUp'),
    );
  }

  static const ModDashboard empty = ModDashboard(
    inQueue: 0,
    waitingOver12h: 0,
    resolvedToday: 0,
    resolvedTodayByMe: 0,
    escalated: 0,
    avgResponseHours: 0,
    reportsByReason: <ReasonCount>[],
    needsYouFirst: <ModReport>[],
    nextUp: <ModReport>[],
  );

  final int inQueue;
  final int waitingOver12h;
  final int resolvedToday;
  final int resolvedTodayByMe;
  final int escalated;
  final double avgResponseHours;
  final List<ReasonCount> reportsByReason;
  final List<ModReport> needsYouFirst;
  final List<ModReport> nextUp;
}

class PreviousAction {
  const PreviousAction({
    required this.displayId,
    required this.decision,
    this.moderatorNote,
    this.resolvedAt,
  });

  factory PreviousAction.fromJson(Map<String, dynamic> json) {
    return PreviousAction(
      displayId: json['displayId'] as String? ?? '',
      decision: ModDecisionX.parse(json['decision'] as String?),
      moderatorNote: json['moderatorNote'] as String?,
      resolvedAt: DateTime.tryParse(json['resolvedAt'] as String? ?? ''),
    );
  }

  final String displayId;
  final ModDecision? decision;
  final String? moderatorNote;
  final DateTime? resolvedAt;

  String get decisionLabel => decision?.title ?? 'Action';
}

class AccountHistory {
  const AccountHistory({
    required this.userId,
    required this.accountStatus,
    required this.blockedByCount,
    required this.reportsAgainst30d,
    required this.previousActions,
    this.joinedAt,
  });

  factory AccountHistory.fromJson(Map<String, dynamic> json) {
    return AccountHistory(
      userId: json['userId'] as String? ?? '',
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? ''),
      accountStatus: json['accountStatus'] as String? ?? 'active',
      blockedByCount: (json['blockedByCount'] as num?)?.toInt() ?? 0,
      reportsAgainst30d: (json['reportsAgainst30d'] as num?)?.toInt() ?? 0,
      previousActions: (json['previousActions'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(PreviousAction.fromJson)
          .toList(),
    );
  }

  final String userId;
  final DateTime? joinedAt;
  final String accountStatus;
  final int blockedByCount;
  final int reportsAgainst30d;
  final List<PreviousAction> previousActions;
}
