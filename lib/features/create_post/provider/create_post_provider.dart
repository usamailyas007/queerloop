import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_images.dart';
import '../models/create_post_models.dart';

class CreatePostProvider extends ChangeNotifier {
  CreatePostProvider() {
    _initDefaultMedia();
    loadDeviceVideos();
    loadDevicePhotos();
  }

  final ImagePicker _picker = ImagePicker();

  // ── Selected Media ───────────────────────────────────────────────────
  GalleryMediaItem? _selectedMedia;
  GalleryMediaItem? get selectedMedia => _selectedMedia;

  MediaType _mediaType = MediaType.video;
  MediaType get mediaType => _mediaType;

  bool _isLoadingDeviceVideos = false;
  bool get isLoadingDeviceVideos => _isLoadingDeviceVideos;

  bool _isLoadingDevicePhotos = false;
  bool get isLoadingDevicePhotos => _isLoadingDevicePhotos;

  // ── Gallery Items (Recent 4 Videos, Recent 8 Photos) ─────────────────
  List<GalleryMediaItem> _videoGallery = <GalleryMediaItem>[];
  List<GalleryMediaItem> get videoGallery =>
      List<GalleryMediaItem>.unmodifiable(_videoGallery.take(4));

  List<GalleryMediaItem> _photoGallery = <GalleryMediaItem>[];
  List<GalleryMediaItem> get photoGallery =>
      List<GalleryMediaItem>.unmodifiable(_photoGallery.take(8));

  // ── Video Trimming ───────────────────────────────────────────────────
  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  int _totalDurationSeconds = 47;

  double get trimStart => _trimStart;
  double get trimEnd => _trimEnd;
  int get totalDurationSeconds => _totalDurationSeconds;

  int get selectedDurationSeconds => _totalDurationSeconds > 0
      ? ((_trimEnd - _trimStart) * _totalDurationSeconds)
          .round()
          .clamp(1, _totalDurationSeconds)
      : 0;

  String get trimStartFormatted {
    final int startSec = (_trimStart * _totalDurationSeconds).round();
    final int m = startSec ~/ 60;
    final int s = startSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get selectedDurationFormatted {
    final int sec = selectedDurationSeconds;
    final int m = sec ~/ 60;
    final int s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')} (${sec}s)';
  }

  String get totalDurationFormatted {
    final int m = _totalDurationSeconds ~/ 60;
    final int s = _totalDurationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  void setTrimRange(double start, double end) {
    _trimStart = start.clamp(0.0, 1.0);
    _trimEnd = end.clamp(start, 1.0);
    notifyListeners();
  }

  // ── Post Form State ──────────────────────────────────────────────────
  String _caption = '';
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

  final List<String> _tags = <String>[];
  List<String> get tags => List<String>.unmodifiable(_tags);

  // ── Actions ──────────────────────────────────────────────────────────
  void setMediaType(MediaType type) {
    _mediaType = type;
    if (type == MediaType.video) {
      if (_videoGallery.isNotEmpty) {
        selectMedia(_videoGallery.first);
      } else {
        loadDeviceVideos();
      }
    } else if (type == MediaType.photo) {
      if (_photoGallery.isNotEmpty) {
        selectMedia(_photoGallery.first);
      } else {
        loadDevicePhotos();
      }
    }
    notifyListeners();
  }

  void selectMedia(GalleryMediaItem media) {
    _selectedMedia = media;
    if (media.isVideo) {
      _totalDurationSeconds =
          media.durationSeconds > 0 ? media.durationSeconds : 47;
      _trimStart = 0.0;
      _trimEnd = 1.0;
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

  void resetPostForm() {
    _caption = '';
    _tags.clear();
    _selectedCommunity = 'Transgender';
    _visibility = PostVisibility.followers;
    _allowComments = true;
    _allowDownloads = false;
    _trimStart = 0.0;
    _trimEnd = 1.0;
    notifyListeners();
  }

  // ── Load Most Recent Videos from Phone Gallery (Newest First) ────────
  Future<void> loadDeviceVideos() async {
    _isLoadingDeviceVideos = true;
    notifyListeners();

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        final FilterOptionGroup filterOption = FilterOptionGroup(
          orders: const <OrderOption>[
            OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        );

        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.video,
          onlyAll: true,
          filterOption: filterOption,
        );

        if (albums.isNotEmpty) {
          final List<AssetEntity> entities =
              await albums.first.getAssetListRange(start: 0, end: 4);

          if (entities.isNotEmpty) {
            final List<GalleryMediaItem> realItems = <GalleryMediaItem>[];

            for (final AssetEntity entity in entities) {
              Uint8List? thumbBytes;
              try {
                thumbBytes = await entity.thumbnailDataWithSize(
                  const ThumbnailSize.square(250),
                  format: ThumbnailFormat.jpeg,
                  quality: 85,
                );
              } catch (err) {
                debugPrint('Thumbnail error for ${entity.id}: $err');
              }

              final File? file = await entity.file;
              final int dur = entity.duration;
              final int m = dur ~/ 60;
              final int s = dur % 60;
              final String formattedDur = '$m:${s.toString().padLeft(2, '0')}';

              realItems.add(
                GalleryMediaItem(
                  id: entity.id,
                  filePath: file?.path,
                  thumbnailBytes: (thumbBytes != null && thumbBytes.isNotEmpty)
                      ? thumbBytes
                      : null,
                  assetEntity: entity,
                  isVideo: true,
                  duration: formattedDur,
                  durationSeconds: dur > 0 ? dur : 30,
                ),
              );
            }

            if (realItems.isNotEmpty) {
              _videoGallery = realItems;
              selectMedia(realItems.first);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading recent videos: $e');
    } finally {
      _isLoadingDeviceVideos = false;
      notifyListeners();
    }
  }

  // ── Load Most Recent Photos from Phone Gallery (Newest First) ────────
  Future<void> loadDevicePhotos() async {
    _isLoadingDevicePhotos = true;
    notifyListeners();

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        final FilterOptionGroup filterOption = FilterOptionGroup(
          orders: const <OrderOption>[
            OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        );

        final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
          filterOption: filterOption,
        );

        if (albums.isNotEmpty) {
          final List<AssetEntity> entities =
              await albums.first.getAssetListRange(start: 0, end: 8);

          if (entities.isNotEmpty) {
            final List<GalleryMediaItem> realItems = <GalleryMediaItem>[];

            for (final AssetEntity entity in entities) {
              Uint8List? thumbBytes;
              try {
                thumbBytes = await entity.thumbnailDataWithSize(
                  const ThumbnailSize.square(250),
                  format: ThumbnailFormat.jpeg,
                  quality: 85,
                );
              } catch (err) {
                debugPrint('Thumbnail error for photo ${entity.id}: $err');
              }

              final File? file = await entity.file;

              realItems.add(
                GalleryMediaItem(
                  id: entity.id,
                  filePath: file?.path,
                  thumbnailBytes: (thumbBytes != null && thumbBytes.isNotEmpty)
                      ? thumbBytes
                      : null,
                  assetEntity: entity,
                  isVideo: false,
                ),
              );
            }

            if (realItems.isNotEmpty) {
              _photoGallery = realItems;
              if (_selectedMedia == null || _selectedMedia!.isVideo) {
                selectMedia(realItems.first);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading recent photos: $e');
    } finally {
      _isLoadingDevicePhotos = false;
      notifyListeners();
    }
  }

  // ── Image Picker from Device Gallery ─────────────────────────────────
  Future<void> pickMediaFromDevice(bool isVideo) async {
    try {
      if (isVideo) {
        final XFile? file =
            await _picker.pickVideo(source: ImageSource.gallery);
        if (file != null) {
          int durationSec = 30;
          try {
            final VideoPlayerController tempCtrl =
                VideoPlayerController.file(File(file.path));
            await tempCtrl.initialize();
            durationSec = tempCtrl.value.duration.inSeconds;
            await tempCtrl.dispose();
          } catch (err) {
            debugPrint('Error getting video duration: $err');
          }

          final int m = durationSec ~/ 60;
          final int s = durationSec % 60;
          final String durFormatted = '$m:${s.toString().padLeft(2, '0')}';

          final GalleryMediaItem newItem = GalleryMediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            videoAsset: file.path,
            filePath: file.path,
            isVideo: true,
            duration: durFormatted,
            durationSeconds: durationSec > 0 ? durationSec : 30,
          );
          _videoGallery.insert(0, newItem);
          selectMedia(newItem);
        }
      } else {
        final XFile? file =
            await _picker.pickImage(source: ImageSource.gallery);
        if (file != null) {
          final GalleryMediaItem newItem = GalleryMediaItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  // ── Initial Fallback ─────────────────────────────────────────────────
  void _initDefaultMedia() {
    _videoGallery = <GalleryMediaItem>[
      const GalleryMediaItem(
        id: 'v1',
        assetPath: AppImages.forYouImg,
        videoAsset: 'assets/videos/video1.mp4',
        isVideo: true,
        duration: '0:47',
        durationSeconds: 47,
      ),
      const GalleryMediaItem(
        id: 'v2',
        assetPath: AppImages.followingImg,
        videoAsset: 'assets/videos/video2.mp4',
        isVideo: true,
        duration: '0:40',
        durationSeconds: 40,
      ),
      const GalleryMediaItem(
        id: 'v3',
        assetPath: AppImages.communityImg,
        videoAsset: 'assets/videos/video3.mp4',
        isVideo: true,
        duration: '0:59',
        durationSeconds: 59,
      ),
      const GalleryMediaItem(
        id: 'v4',
        assetPath: AppImages.emptyHomeImg,
        videoAsset: 'assets/videos/video1.mp4',
        isVideo: true,
        duration: '0:47',
        durationSeconds: 47,
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

    _selectedMedia = _videoGallery.first;
  }
}
