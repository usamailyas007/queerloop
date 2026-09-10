// Analytics Dashboard model — GET /admin/analytics/dashboard

class AnalyticsDashboard {
  const AnalyticsDashboard({
    this.dailyActive,
    required this.newSignups,
    required this.postsInRange,
    required this.videoSharePct,
    required this.openReports,
    required this.avgResponseHours,
  });

  factory AnalyticsDashboard.fromJson(Map<String, dynamic> json) {
    return AnalyticsDashboard(
      dailyActive: (json['dailyActive'] as num?)?.toInt(),
      newSignups: (json['newSignups'] as num?)?.toInt() ?? 0,
      postsInRange: (json['postsInRange'] as num?)?.toInt() ?? 0,
      videoSharePct: (json['videoSharePct'] as num?)?.toDouble() ?? 0.0,
      openReports: (json['openReports'] as num?)?.toInt() ?? 0,
      avgResponseHours: (json['avgResponseHours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final int? dailyActive;
  final int newSignups;
  final int postsInRange;
  final double videoSharePct;
  final int openReports;
  final double avgResponseHours;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dailyActive': dailyActive,
      'newSignups': newSignups,
      'postsInRange': postsInRange,
      'videoSharePct': videoSharePct,
      'openReports': openReports,
      'avgResponseHours': avgResponseHours,
    };
  }
}
