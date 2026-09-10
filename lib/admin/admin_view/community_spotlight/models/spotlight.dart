// Model for the Community Spotlight — /admin/spotlights + /engagement/spotlights.

class Spotlight {
  const Spotlight({
    required this.id,
    required this.title,
    required this.body,
    required this.views,
    required this.taps,
    required this.createdAt,
    required this.live,
    this.imageUrl,
    this.createdBy,
  });

  factory Spotlight.fromJson(Map<String, dynamic> json) {
    return Spotlight(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
      taps: (json['taps'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      // The create/patch/rerun responses omit `live`; only the feed has it.
      live: json['live'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'views': views,
      'taps': taps,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'live': live,
    };
  }

  Spotlight copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    int? views,
    int? taps,
    String? createdBy,
    DateTime? createdAt,
    bool? live,
  }) {
    return Spotlight(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      views: views ?? this.views,
      taps: taps ?? this.taps,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      live: live ?? this.live,
    );
  }

  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final int views;
  final int taps;
  final String? createdBy;
  final DateTime createdAt;
  final bool live;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;
}
