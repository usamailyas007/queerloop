import '../../../core/theme/app_images.dart';

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
    final String name = json['name'] as String? ?? '';
    final String? avatarFromJson = json['avatarAsset'] as String?;
    final String avatarAsset =
        (avatarFromJson != null && avatarFromJson.isNotEmpty)
            ? avatarFromJson
            : _matchAvatarAsset(name);

    return CommunityModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: name,
      avatarAsset: avatarAsset,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      visibility: json['visibility'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  static String _matchAvatarAsset(String name) {
    final String lower = name.toLowerCase().trim();
    if (lower.contains('lesbian')) return AppImages.lesbian;
    if (lower.contains('gay')) return AppImages.gay;
    if (lower.contains('bi')) return AppImages.bisexual;
    if (lower.contains('transgender') || lower == 'trans') {
      return AppImages.transgender;
    }
    if (lower.contains('non-binary') || lower.contains('nonbinary')) {
      return AppImages.nonBinary;
    }
    if (lower.contains('queer')) return AppImages.queer;
    if (lower.contains('pansexual') || lower.contains('pan')) {
      return AppImages.pansexual;
    }
    if (lower.contains('asexual') || lower.contains('ace')) {
      return AppImages.asexual;
    }
    if (lower.contains('aromantic') || lower.contains('aro')) {
      return AppImages.aromantic;
    }
    if (lower.contains('intersex')) return AppImages.intersex;
    if (lower.contains('genderfluid')) return AppImages.genderfluid;
    if (lower.contains('transmasc')) return AppImages.transmasc;
    if (lower.contains('transfemme')) return AppImages.transfemme;
    if (lower.contains('allies') || lower.contains('ally')) {
      return AppImages.allies;
    }
    return '';
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
