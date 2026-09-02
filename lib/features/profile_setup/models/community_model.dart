class CommunityModel {
  const CommunityModel({
    required this.id,
    required this.name,
    this.avatarAsset = '',
    this.imageUrl,
    this.slug,
    this.description,
    this.visibility,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.isJoined = false,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      visibility: json['visibility'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String name;
  final String avatarAsset;
  final String? imageUrl;
  final String? slug;
  final String? description;
  final String? visibility;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final bool isJoined;

  CommunityModel copyWith({
    bool? isJoined,
    String? imageUrl,
  }) {
    return CommunityModel(
      id: id,
      name: name,
      avatarAsset: avatarAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      slug: slug,
      description: description,
      visibility: visibility,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
