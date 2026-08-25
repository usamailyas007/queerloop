import 'package:flutter/foundation.dart';
import '../../../core/theme/app_images.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';

enum TopTab { following, forYou, communities }
enum SubMode { reels, posts }

class HomeFeedProvider extends ChangeNotifier {
  bool _isGuest = false;
  int _bottomNavIndex = 0; // 0: Home, 1: Discover, 2: Create, 3: Messages, 4: Profile
  TopTab _activeTopTab = TopTab.forYou;
  SubMode _activeSubMode = SubMode.reels;
  String _selectedCommunityFilter = 'All Communities';

  // Mock Feed Lists — each reel uses a real video asset
  final List<ReelItemModel> _reels = <ReelItemModel>[
    const ReelItemModel(
      id: 'reel_1',
      username: '@jules.does',
      pronounsTime: 'she/they · 40m',
      avatarAsset: AppImages.user1,
      videoAsset: 'assets/videos/video1.mp4',
      caption: 'Drag brunch prep at 6am is a lifestyle nobody warns you about 💃',
      likesCount: 908,
      commentsCount: 77,
      isLiked: false,
      isFollowing: true,
      tags: <String>['Queer'],
      durationText: '0:47',
    ),
    const ReelItemModel(
      id: 'reel_2',
      username: '@rowankeeps',
      pronounsTime: 'they/them · 2h',
      avatarAsset: AppImages.user2,
      videoAsset: 'assets/videos/video2.mp4',
      caption:
          'Six months of top surgery recovery in 40 seconds. Read the caption before you comment, please 🤍\n#transjoy #recovery #sixmonths',
      likesCount: 1240,
      commentsCount: 182,
      isLiked: false,
      isFollowing: false,
      tags: <String>['Non-binary'],
      durationText: '0:40',
    ),
    const ReelItemModel(
      id: 'reel_3',
      username: '@moss.and.oat',
      pronounsTime: 'she/her · 5h',
      avatarAsset: AppImages.user3,
      videoAsset: 'assets/videos/video3.mp4',
      caption:
          "First date turned into building a bookshelf together. That's the whole plot.",
      likesCount: 3410,
      commentsCount: 420,
      isLiked: false,
      isFollowing: false,
      tags: <String>['Lesbian · community only'],
      durationText: '0:59',
    ),
  ];

  final List<PostItemModel> _posts = <PostItemModel>[
    const PostItemModel(
      id: 'post_1',
      username: '@theo.vance',
      pronounsTime: 'he/him · 18m',
      avatarAsset: AppImages.user4,
      content:
          'Told my grandma about Dev over the phone and she said "finally, you sounded lonely in December." Eleven months of rehearsing a speech for nothing.',
      likesCount: 5600,
      commentsCount: 311,
      postImageAsset: AppImages.forYouImg,
      isLiked: false,
    ),
    const PostItemModel(
      id: 'post_2',
      username: '@nadia.builds',
      pronounsTime: 'she/her · 1h',
      avatarAsset: AppImages.user1,
      content:
          'Reminder that the Tuesday support call is open to anyone, camera off is normal, and nobody has to speak.',
      likesCount: 1200,
      commentsCount: 311,
      isLiked: false,
    ),
  ];

  // Getters
  bool get isGuest => _isGuest;
  int get bottomNavIndex => _bottomNavIndex;
  TopTab get activeTopTab => _activeTopTab;
  SubMode get activeSubMode => _activeSubMode;
  String get selectedCommunityFilter => _selectedCommunityFilter;

  List<ReelItemModel> get reels {
    if (_activeTopTab == TopTab.following) {
      return _reels.where((r) => r.id == 'reel_1').toList();
    } else if (_activeTopTab == TopTab.communities) {
      return _reels.where((r) => r.id == 'reel_3').toList();
    }
    return _reels;
  }

  List<PostItemModel> get posts => List<PostItemModel>.unmodifiable(_posts);

  bool get isFollowingEmpty => false;

  // Actions
  void setGuestMode(bool val) {
    if (_isGuest == val) return;
    _isGuest = val;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners();
  }

  void setTopTab(TopTab tab) {
    _activeTopTab = tab;
    notifyListeners();
  }

  void setSubMode(SubMode mode) {
    _activeSubMode = mode;
    notifyListeners();
  }

  void setSelectedCommunityFilter(String val) {
    _selectedCommunityFilter = val;
    notifyListeners();
  }

  void toggleLikeReel(String id) {
    final int index = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (index != -1) {
      final ReelItemModel item = _reels[index];
      final bool newLiked = !item.isLiked;
      final int newCount = newLiked ? item.likesCount + 1 : item.likesCount - 1;
      _reels[index] = item.copyWith(isLiked: newLiked, likesCount: newCount);
      notifyListeners();
    }
  }

  void toggleSaveReel(String id) {
    final int index = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (index != -1) {
      final ReelItemModel item = _reels[index];
      _reels[index] = item.copyWith(isSaved: !item.isSaved);
      notifyListeners();
    }
  }

  void toggleFollowReel(String id) {
    final int index = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (index != -1) {
      final ReelItemModel item = _reels[index];
      _reels[index] = item.copyWith(isFollowing: !item.isFollowing);
      notifyListeners();
    }
  }

  void addNewReel(ReelItemModel reel) {
    _reels.insert(0, reel);
    notifyListeners();
  }

  void toggleLikePost(String id) {
    final int index = _posts.indexWhere((PostItemModel p) => p.id == id);
    if (index != -1) {
      final PostItemModel item = _posts[index];
      final bool newLiked = !item.isLiked;
      final int newCount = newLiked ? item.likesCount + 1 : item.likesCount - 1;
      _posts[index] = item.copyWith(isLiked: newLiked, likesCount: newCount);
      notifyListeners();
    }
  }

  void toggleSavePost(String id) {
    final int index = _posts.indexWhere((PostItemModel p) => p.id == id);
    if (index != -1) {
      final PostItemModel item = _posts[index];
      _posts[index] = item.copyWith(isSaved: !item.isSaved);
      notifyListeners();
    }
  }
}
