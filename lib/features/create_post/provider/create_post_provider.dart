import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_images.dart';
import '../models/create_post_models.dart';

class CreatePostProvider extends ChangeNotifier {
  CreatePostProvider() {
    _initSampleGallery();
  }

  final ImagePicker _picker = ImagePicker();

  // ── Selected Media ───────────────────────────────────────────────────
  GalleryMediaItem? _selectedMedia;
  GalleryMediaItem? get selectedMedia => _selectedMedia;

  MediaType _mediaType = MediaType.photo;
  MediaType get mediaType => _mediaType;

  // ── Gallery Items ────────────────────────────────────────────────────
  List<GalleryMediaItem> _videoGallery = <GalleryMediaItem>[];
  List<GalleryMediaItem> get videoGallery => List<GalleryMediaItem>.unmodifiable(_videoGallery);

  List<GalleryMediaItem> _photoGallery = <GalleryMediaItem>[];
  List<GalleryMediaItem> get photoGallery => List<GalleryMediaItem>.unmodifiable(_photoGallery);

  // ── Video Trimming ───────────────────────────────────────────────────
  double _trimStart = 0.12; // percentage or seconds ratio
  double _trimEnd = 0.80;
  int _totalDurationSeconds = 47;
  
  double get trimStart => _trimStart;
  double get trimEnd => _trimEnd;
  int get totalDurationSeconds => _totalDurationSeconds;

  int get selectedDurationSeconds =>
      ((_trimEnd - _trimStart) * _totalDurationSeconds).round();

  String get trimStartFormatted => '0:${(_trimStart * _totalDurationSeconds).round().toString().padLeft(2, '0')}';
  String get selectedDurationFormatted => '${selectedDurationSeconds}s selected';
  String get totalDurationFormatted => '0:$_totalDurationSeconds';

  void setTrimRange(double start, double end) {
    _trimStart = start.clamp(0.0, 1.0);
    _trimEnd = end.clamp(start, 1.0);
    notifyListeners();
  }

  // ── Post Form State ──────────────────────────────────────────────────
  String _caption = 'Six months post-op. Read the caption before you comment 🤍 #transjoy #recovery';
  String get caption => _caption;

  int get captionCharCount => _caption.length;
  static const int maxCaptionLength = 300;

  String _selectedCommunity = 'Transgender';
  String get selectedCommunity => _selectedCommunity;

  PostVisibility _visibility = PostVisibility.followers;
  PostVisibility get visibility => _visibility;

  bool _allowComments = true;
  bool get allowComments => _allowComments;

  bool _allowDownloads = false;
  bool get allowDownloads => _allowDownloads;

  final List<String> _tags = <String>['#chosenfamily', '#support'];
  List<String> get tags => List<String>.unmodifiable(_tags);

  // ── Actions ──────────────────────────────────────────────────────────
  void setMediaType(MediaType type) {
    _mediaType = type;
    notifyListeners();
  }

  void selectMedia(GalleryMediaItem media) {
    _selectedMedia = media;
    if (media.isVideo) {
      _totalDurationSeconds = media.durationSeconds > 0 ? media.durationSeconds : 38;
      _trimStart = 0.0;
      _trimEnd = 0.70;
    }
    notifyListeners();
  }

  void updateCaption(String text) {
    _caption = text;
    notifyListeners();
  }

  void setSelectedCommunity(String community) {
    _selectedCommunity = community;
    notifyListeners();
  }

  void setVisibility(PostVisibility visibility) {
    _visibility = visibility;
    notifyListeners();
  }

  void toggleAllowComments(bool value) {
    _allowComments = value;
    notifyListeners();
  }

  void toggleAllowDownloads(bool value) {
    _allowDownloads = value;
    notifyListeners();
  }

  void setTags(List<String> newTags) {
    _tags.clear();
    _tags.addAll(newTags);
    notifyListeners();
  }

  void addTag(String tag) {
    final String cleanTag = tag.startsWith('#') ? tag : '#$tag';
    if (!_tags.contains(cleanTag)) {
      _tags.add(cleanTag);
      notifyListeners();
    }
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  // ── Image Picker Integration ─────────────────────────────────────────
  Future<void> pickMediaFromDevice(bool isVideo) async {
    try {
      if (isVideo) {
        final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file != null) {
          final GalleryMediaItem newItem = GalleryMediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            assetPath: AppImages.forYouImg,
            filePath: file.path,
            isVideo: true,
            duration: '0:30',
            durationSeconds: 30,
          );
          _videoGallery.insert(0, newItem);
          selectMedia(newItem);
        }
      } else {
        final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
        if (file != null) {
          final GalleryMediaItem newItem = GalleryMediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            assetPath: AppImages.searchResult1,
            filePath: file.path,
            isVideo: false,
          );
          _photoGallery.insert(0, newItem);
          selectMedia(newItem);
        }
      }
    } catch (e) {
      debugPrint('Device media picker exception: $e');
    }
  }

  // ── Default Gallery Fallback ─────────────────────────────────────────
  void _initSampleGallery() {
    _videoGallery = <GalleryMediaItem>[
      const GalleryMediaItem(
        id: 'v1',
        assetPath: AppImages.forYouImg,
        isVideo: true,
        duration: '0:47',
        durationSeconds: 47,
      ),
      const GalleryMediaItem(
        id: 'v2',
        assetPath: AppImages.followingImg,
        isVideo: true,
        duration: '0:12',
        durationSeconds: 12,
      ),
      const GalleryMediaItem(
        id: 'v3',
        assetPath: AppImages.communityImg,
        isVideo: true,
        duration: '0:35',
        durationSeconds: 35,
      ),
      const GalleryMediaItem(
        id: 'v4',
        assetPath: AppImages.emptyHomeImg,
        isVideo: true,
        duration: '1:02',
        durationSeconds: 62,
      ),
    ];

    _photoGallery = <GalleryMediaItem>[
      const GalleryMediaItem(id: 'p1', assetPath: AppImages.searchResult1),
      const GalleryMediaItem(id: 'p2', assetPath: AppImages.searchResult2),
      const GalleryMediaItem(id: 'p3', assetPath: AppImages.searchResult3),
      const GalleryMediaItem(id: 'p4', assetPath: AppImages.searchResult4),
      const GalleryMediaItem(id: 'p5', assetPath: AppImages.searchResult5),
      const GalleryMediaItem(id: 'p6', assetPath: AppImages.searchResult6),
      const GalleryMediaItem(id: 'p7', assetPath: AppImages.queer),
      const GalleryMediaItem(id: 'p8', assetPath: AppImages.transgender),
    ];

    // Default selection
    _selectedMedia = _videoGallery.first;
  }
}
