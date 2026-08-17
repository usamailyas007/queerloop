// Data models for Discover / Search screens

class DiscoverSearchResult {
  const DiscoverSearchResult({
    required this.imageAsset,
    this.viewCount,
  });

  final String imageAsset;
  final String? viewCount;
}

class DiscoverPerson {
  const DiscoverPerson({
    required this.avatarAsset,
    required this.username,
    required this.pronouns,
    required this.followers,
    required this.isFollowing,
  });

  final String avatarAsset;
  final String username;
  final String pronouns;
  final String followers;
  final bool isFollowing;
}

class DiscoverCommunity {
  const DiscoverCommunity({
    required this.imageAsset,
    required this.name,
    required this.description,
    required this.isJoined,
  });

  final String imageAsset;
  final String name;
  final String description;
  final bool isJoined;
}

class DiscoverCreator {
  const DiscoverCreator({
    required this.avatarAsset,
    required this.username,
  });

  final String avatarAsset;
  final String username;
}

class TrendingItem {
  const TrendingItem({
    required this.rank,
    required this.hashtag,
    required this.postsCount,
    required this.thumbnailAsset,
  });

  final String rank;
  final String hashtag;
  final String postsCount;
  final String thumbnailAsset;
}
