// Analytics Overview model — GET /admin/analytics/overview

class ContentMixItem {
  const ContentMixItem({
    required this.type,
    required this.count,
  });

  factory ContentMixItem.fromJson(Map<String, dynamic> json) {
    return ContentMixItem(
      type: json['type'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String type;
  final int count;

  Map<String, dynamic> toJson() => <String, dynamic>{'type': type, 'count': count};
}

class TopHashtagItem {
  const TopHashtagItem({
    required this.tag,
    required this.count,
  });

  factory TopHashtagItem.fromJson(Map<String, dynamic> json) {
    return TopHashtagItem(
      tag: json['tag'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  final String tag;
  final int count;

  Map<String, dynamic> toJson() => <String, dynamic>{'tag': tag, 'count': count};
}

class SafetyOutcomes {
  const SafetyOutcomes({
    required this.received,
    required this.hidden,
    required this.warned,
    required this.suspended,
    required this.banned,
    required this.appealsTotal,
    required this.appealsReversed,
    required this.inQueue,
    required this.avgResponseHours,
  });

  factory SafetyOutcomes.fromJson(Map<String, dynamic> json) {
    return SafetyOutcomes(
      received: (json['received'] as num?)?.toInt() ?? 0,
      hidden: (json['hidden'] as num?)?.toInt() ?? 0,
      warned: (json['warned'] as num?)?.toInt() ?? 0,
      suspended: (json['suspended'] as num?)?.toInt() ?? 0,
      banned: (json['banned'] as num?)?.toInt() ?? 0,
      appealsTotal: (json['appealsTotal'] as num?)?.toInt() ?? 0,
      appealsReversed: (json['appealsReversed'] as num?)?.toInt() ?? 0,
      inQueue: (json['inQueue'] as num?)?.toInt() ?? 0,
      avgResponseHours: (json['avgResponseHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int received;
  final int hidden;
  final int warned;
  final int suspended;
  final int banned;
  final int appealsTotal;
  final int appealsReversed;
  final int inQueue;
  final double avgResponseHours;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'received': received,
      'hidden': hidden,
      'warned': warned,
      'suspended': suspended,
      'banned': banned,
      'appealsTotal': appealsTotal,
      'appealsReversed': appealsReversed,
      'inQueue': inQueue,
      'avgResponseHours': avgResponseHours,
    };
  }
}

class CommunitySizeItem {
  const CommunitySizeItem({
    required this.id,
    required this.name,
    required this.memberCount,
  });

  factory CommunitySizeItem.fromJson(Map<String, dynamic> json) {
    return CommunitySizeItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final int memberCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'memberCount': memberCount,
    };
  }
}

class AnalyticsOverview {
  const AnalyticsOverview({
    this.retention,
    this.avgSessionDuration,
    required this.postsPerPerson,
    required this.reportsPer1kPosts,
    required this.contentMix,
    required this.topHashtags,
    required this.safetyOutcomes,
    required this.communitySizes,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    final List<dynamic> mixRaw = json['contentMix'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> tagsRaw = json['topHashtags'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> commsRaw = json['communitySizes'] as List<dynamic>? ?? <dynamic>[];

    return AnalyticsOverview(
      retention: (json['retention'] as num?)?.toDouble(),
      avgSessionDuration: (json['avgSessionDuration'] as num?)?.toDouble(),
      postsPerPerson: (json['postsPerPerson'] as num?)?.toDouble() ?? 0.0,
      reportsPer1kPosts: (json['reportsPer1kPosts'] as num?)?.toDouble() ?? 0.0,
      contentMix: mixRaw
          .map((dynamic e) => ContentMixItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      topHashtags: tagsRaw
          .map((dynamic e) => TopHashtagItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      safetyOutcomes: json['safetyOutcomes'] != null
          ? SafetyOutcomes.fromJson(json['safetyOutcomes'] as Map<String, dynamic>)
          : const SafetyOutcomes(
              received: 0,
              hidden: 0,
              warned: 0,
              suspended: 0,
              banned: 0,
              appealsTotal: 0,
              appealsReversed: 0,
              inQueue: 0,
              avgResponseHours: 0,
            ),
      communitySizes: commsRaw
          .map((dynamic e) => CommunitySizeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final double? retention;
  final double? avgSessionDuration;
  final double postsPerPerson;
  final double reportsPer1kPosts;
  final List<ContentMixItem> contentMix;
  final List<TopHashtagItem> topHashtags;
  final SafetyOutcomes safetyOutcomes;
  final List<CommunitySizeItem> communitySizes;

  int get totalContentCount =>
      contentMix.fold(0, (int sum, ContentMixItem item) => sum + item.count);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'retention': retention,
      'avgSessionDuration': avgSessionDuration,
      'postsPerPerson': postsPerPerson,
      'reportsPer1kPosts': reportsPer1kPosts,
      'contentMix': contentMix.map((ContentMixItem e) => e.toJson()).toList(),
      'topHashtags': topHashtags.map((TopHashtagItem e) => e.toJson()).toList(),
      'safetyOutcomes': safetyOutcomes.toJson(),
      'communitySizes': communitySizes.map((CommunitySizeItem e) => e.toJson()).toList(),
    };
  }
}
