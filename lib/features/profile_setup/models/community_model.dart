class CommunityModel {
  const CommunityModel({
    required this.id,
    required this.name,
    required this.avatarAsset,
    this.isJoined = false,
  });

  final String id;
  final String name;
  final String avatarAsset;
  final bool isJoined;

  CommunityModel copyWith({bool? isJoined}) {
    return CommunityModel(
      id: id,
      name: name,
      avatarAsset: avatarAsset,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}
