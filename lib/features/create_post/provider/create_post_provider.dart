import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_images.dart';
import '../models/create_post_models.dart';
import '../models/post_draft_model.dart';
import '../services/media_upload_service.dart';
import '../services/post_content_service.dart';

class CreatePostProvider extends ChangeNotifier {
  CreatePostProvider({
    MediaUploadService? uploadService,
    PostContentService? contentService,
  })  : _uploadService = uploadService,
        _contentService = contentService {
    _initDefaultMedia();
    loadDeviceVideos();
    loadDevicePhotos();
  }

  MediaUploadService? _uploadService;
  PostContentService? _contentService;

  void updateServices({
    required MediaUploadService uploadService,
    required PostContentService contentService,
  }) {
    _uploadService = uploadService;
    _contentService = contentService;
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

  // ── Video Trimming & 60-Second Server Limit ─────────────────────────
  static const int maxVideoDurationLimitSeconds = 60;

  double _trimStart = 0.0;
  double _trimEnd = 1.0;
  int _totalDurationSeconds = 47;

  double get trimStart => _trimStart;
  double get trimEnd => _trimEnd;
  int get totalDurationSeconds => _totalDurationSeconds;

  bool get isVideoOverLimit =>
      _totalDurationSeconds > maxVideoDurationLimitSeconds;
  bool get isDurationWithinLimit =>
      selectedDurationSeconds <= maxVideoDurationLimitSeconds;

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
    double proposedEnd = end.clamp(_trimStart, 1.0);

    // Enforce 60s max video limit
    if (_totalDurationSeconds > maxVideoDurationLimitSeconds) {
      final double maxAllowedFraction =
          maxVideoDurationLimitSeconds / _totalDurationSeconds;
      if ((proposedEnd - _trimStart) > maxAllowedFraction) {
        proposedEnd = (_trimStart + maxAllowedFraction).clamp(0.0, 1.0);
      }
    }
    _trimEnd = proposedEnd;
    notifyListeners();
  }

  // ── Media Upload & Transcoding Pipeline ──────────────────────────────
  MediaUploadStatus _uploadStatus = MediaUploadStatus.idle;
  MediaUploadStatus get uploadStatus => _uploadStatus;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  String? _uploadedMediaId;
  String? get uploadedMediaId => _uploadedMediaId;

  MediaUploadResult? _uploadResult;
  MediaUploadResult? get uploadResult => _uploadResult;

  String? _uploadError;
  String? get uploadError => _uploadError;

  bool _isPublishing = false;
  bool get isPublishing => _isPublishing;

  bool get isMediaReady => _uploadStatus == MediaUploadStatus.ready;

  /// Gate: Client-side gating on status
  bool get canPublish =>
      !_isPublishing &&
      (_selectedMedia == null ||
          _uploadStatus == MediaUploadStatus.ready ||
          _uploadStatus == MediaUploadStatus.idle ||
          _uploadStatus == MediaUploadStatus.failed);

  int _uploadSessionId = 0;

  void _resetUploadState() {
    _uploadSessionId++;
    _uploadService?.cancelPolling();
    _uploadStatus = MediaUploadStatus.idle;
    _uploadProgress = 0.0;
    _uploadedMediaId = null;
    _uploadResult = null;
    _uploadError = null;
  }

  /// Cancels any in-flight media upload, S3 transfer, or status polling loop.
  void cancelMediaUpload() {
    _uploadSessionId++;
    _uploadService?.cancelPolling();
    if (_uploadStatus == MediaUploadStatus.uploading ||
        _uploadStatus == MediaUploadStatus.transcoding ||
        _uploadStatus == MediaUploadStatus.requestingUrl ||
        _uploadStatus == MediaUploadStatus.completing) {
      _uploadStatus = MediaUploadStatus.idle;
      _uploadProgress = 0.0;
      _uploadError = null;
      notifyListeners();
    }
    debugPrint('🛑 [CreatePostProvider] Media upload cancelled.');
  }

  Future<void> startMediaUpload() async {
    if (_selectedMedia == null) return;
    if (_uploadStatus == MediaUploadStatus.uploading ||
        _uploadStatus == MediaUploadStatus.transcoding ||
        _uploadStatus == MediaUploadStatus.requestingUrl) {
      return;
    }
    if (_uploadStatus == MediaUploadStatus.ready && _uploadedMediaId != null) {
      return;
    }

    final int sessionId = ++_uploadSessionId;
    bool isCancelled() => sessionId != _uploadSessionId;

    _uploadStatus = MediaUploadStatus.requestingUrl;
    _uploadProgress = 0.0;
    _uploadError = null;
    notifyListeners();

    try {
      final String? path = _selectedMedia!.filePath;
      final bool isVideo = _selectedMedia!.isVideo;

      if (_uploadService == null) {
        // Mock fallback simulation
        _uploadStatus = MediaUploadStatus.uploading;
        _uploadProgress = 0.5;
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (isCancelled()) return;
        _uploadProgress = 1.0;
        _uploadStatus =
            isVideo ? MediaUploadStatus.transcoding : MediaUploadStatus.completing;
        notifyListeners();
        await Future<void>.delayed(const Duration(seconds: 1));
        if (isCancelled()) return;
        _uploadedMediaId = 'media_${DateTime.now().millisecondsSinceEpoch}';
        _uploadResult = MediaUploadResult(
          id: _uploadedMediaId!,
          status: 'ready',
          downloadUrl: isVideo ? 'assets/videos/video1.mp4' : path,
        );
        _uploadStatus = MediaUploadStatus.ready;
        notifyListeners();
        return;
      }

      final String filename = path != null
          ? path.split(Platform.pathSeparator).last
          : (isVideo ? 'upload_video.mp4' : 'upload_image.jpg');
      final String contentType = isVideo ? 'video/mp4' : 'image/jpeg';
      final String fileType = isVideo ? 'video' : 'image';

      File? fileToUpload;
      int? fileSize;
      if (path != null) {
        final File file = File(path);
        if (await file.exists()) {
          fileToUpload = file;
          fileSize = await file.length();
        }
      }

      if (isCancelled()) return;

      // Step 1: POST /media/upload-url (Port 3014)
      final MediaUploadResult uploadInfo = await _uploadService!.getUploadUrl(
        filename: filename,
        contentType: contentType,
        fileType: fileType,
        fileSize: fileSize,
      );

      if (isCancelled()) return;

      if (uploadInfo.id.trim().isEmpty) {
        throw ApiException(
          'Upload service did not return a valid media ID.',
          kind: ApiErrorKind.server,
        );
      }

      _uploadStatus = MediaUploadStatus.uploading;
      notifyListeners();

      // Step 2: PUT <uploadUrl> direct to Amazon S3
      if (fileToUpload != null &&
          uploadInfo.uploadUrl != null &&
          uploadInfo.uploadUrl!.isNotEmpty) {
        await _uploadService!.uploadFileToS3(
          uploadUrl: uploadInfo.uploadUrl!,
          file: fileToUpload,
          contentType: contentType,
          onProgress: (int sent, int total) {
            if (isCancelled()) return;
            if (total > 0) {
              _uploadProgress = (sent / total).clamp(0.0, 1.0);
              notifyListeners();
            }
          },
        );
      } else {
        _uploadProgress = 1.0;
        notifyListeners();
      }

      if (isCancelled()) return;

      // Step 3: Complete upload notification to backend
      _uploadStatus = MediaUploadStatus.completing;
      notifyListeners();
      MediaUploadResult completedInfo = uploadInfo;
      try {
        completedInfo = await _uploadService!.completeUpload(uploadInfo.id);
      } catch (e) {
        debugPrint('⚠️ completeUpload notice: $e');
      }
      if (isCancelled()) return;

      final String statusLower = completedInfo.status.toLowerCase();
      if (!isVideo ||
          statusLower == 'ready' ||
          statusLower == 'uploaded' ||
          statusLower == 'completed' ||
          statusLower == 'done' ||
          statusLower == 'active') {
        _uploadedMediaId = completedInfo.id.isNotEmpty ? completedInfo.id : uploadInfo.id;
        _uploadResult = completedInfo;
        _uploadStatus = MediaUploadStatus.ready;
        notifyListeners();
        return;
      }

      // Step 4: Video status polling for AWS transcoding (GET /media/:id on Port 3014)
      _uploadStatus = MediaUploadStatus.transcoding;
      notifyListeners();

      MediaUploadResult readyMedia = completedInfo;
      try {
        readyMedia = await _uploadService!.pollUntilReady(
          uploadInfo.id,
          isCancelled: isCancelled,
          onStatusChange: (String status) {
            if (!isCancelled()) {
              debugPrint('🎬 Video transcoding status: $status');
            }
          },
        );
      } catch (e) {
        debugPrint('⚠️ pollUntilReady notice (falling back to uploaded media): $e');
        readyMedia = completedInfo;
      }

      if (isCancelled()) return;

      _uploadedMediaId = readyMedia.id.isNotEmpty ? readyMedia.id : uploadInfo.id;
      _uploadResult = readyMedia;
      _uploadStatus = MediaUploadStatus.ready;
      notifyListeners();
    } catch (e) {
      if (isCancelled()) return;
      debugPrint('❌ Media upload failed: $e');
      _uploadStatus = MediaUploadStatus.failed;
      _uploadError = e is ApiException ? e.message : e.toString();
      notifyListeners();
    }
  }

  Future<PostResponseModel?> publishPost() async {
    if (_isPublishing) return null;

    // Client-side gating: text posts never upload or require media
    if (_mediaType == MediaType.text) {
      _selectedMedia = null;
      _uploadedMediaId = null;
      _uploadResult = null;
    } else if (_selectedMedia != null && _uploadStatus != MediaUploadStatus.ready) {
      if (_uploadStatus == MediaUploadStatus.idle ||
          _uploadStatus == MediaUploadStatus.failed) {
        await startMediaUpload();
      }
      if (_uploadStatus != MediaUploadStatus.ready) {
        throw Exception(
          _uploadError ?? 'Media is still processing. Please wait.',
        );
      }
    }

    _isPublishing = true;
    notifyListeners();

    try {
      final List<String> mediaRefs = <String>[];
      if (_mediaType != MediaType.text &&
          _uploadedMediaId != null &&
          _uploadedMediaId!.isNotEmpty) {
        mediaRefs.add(_uploadedMediaId!);
      }

      // Backend expects type: "TEXT" | "PHOTO" | "VIDEO"
      final String postType = _mediaType == MediaType.text
          ? 'TEXT'
          : ((_selectedMedia?.isVideo ?? (_mediaType == MediaType.video))
              ? 'VIDEO'
              : 'PHOTO');

      // Backend expects visibility: "EVERYONE" | "FOLLOWERS" | "COMMUNITY_ONLY"
      final String serverVisibility = () {
        switch (_visibility) {
          case PostVisibility.everyone:
            return 'EVERYONE';
          case PostVisibility.followers:
            return 'FOLLOWERS';
          case PostVisibility.communityOnly:
            return 'COMMUNITY_ONLY';
        }
      }();

      final List<String> postTags = _tags.isNotEmpty
          ? _tags
          : const <String>[];

      final String? commId = postType == 'TEXT' ? null : _selectedCommunityId;

      PostResponseModel result;
      if (_contentService != null) {
        result = await _contentService!.createPost(
          body: _caption,
          type: postType,
          visibility: serverVisibility,
          mediaRefs: postType == 'TEXT' ? const <String>[] : mediaRefs,
          tags: postTags,
          communityId: commId,
          allowDownloads: _allowDownloads,
        );
      } else {
        result = PostResponseModel(
          id: 'post_${DateTime.now().millisecondsSinceEpoch}',
          caption: _caption,
          type: postType,
          mediaRefs: postType == 'TEXT' ? const <String>[] : mediaRefs,
          tags: postTags,
          community: postType == 'TEXT' ? '' : _selectedCommunity,
          communityId: commId,
          visibility: serverVisibility,
          allowDownloads: _allowDownloads,
        );
      }

      return result;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  // ── Post Form State ──────────────────────────────────────────────────
  String _caption = '';
  String get caption => _caption;

  int get captionCharCount => _caption.length;
  static const int maxCaptionLength = 300;

  String _selectedCommunity = 'Transgender';
  String get selectedCommunity => _selectedCommunity;

  String? _selectedCommunityId;
  String? get selectedCommunityId => _selectedCommunityId;

  PostVisibility _visibility = PostVisibility.followers;
  PostVisibility get visibility => _visibility;

  bool _allowComments = true;
  bool get allowComments => _allowComments;

  bool _allowDownloads = false;
  bool get allowDownloads => _allowDownloads;

  final List<String> _tags = <String>[];
  List<String> get tags => List<String>.unmodifiable(_tags);

  String? _currentDraftId;
  String? get currentDraftId => _currentDraftId;

  PostDraft toDraft({String? caption}) {
    final String draftId =
        _currentDraftId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
    return PostDraft(
      id: draftId,
      mediaType: _selectedMedia != null
          ? (_selectedMedia!.isVideo ? MediaType.video : MediaType.photo)
          : _mediaType,
      caption: caption ?? _caption,
      createdAt: DateTime.now(),
      mediaPath: _selectedMedia?.filePath,
      communityId: _selectedCommunityId,
      communityName: _selectedCommunity,
      allowComments: _allowComments,
      allowSharing: _allowDownloads,
      taggedUsers: _tags,
      mediaUrl: _uploadResult?.downloadUrl ?? _uploadResult?.url,
      uploadedMediaId: _uploadedMediaId ?? _uploadResult?.id,
      thumbnailUrl: _uploadResult?.thumbnailUrl,
    );
  }

  void loadFromDraft(PostDraft draft) {
    _currentDraftId = draft.id;
    _caption = draft.caption;
    _mediaType = draft.mediaType;
    if (draft.communityName != null && draft.communityName!.isNotEmpty) {
      _selectedCommunity = draft.communityName!;
      _selectedCommunityId = draft.communityId;
    }
    _allowComments = draft.allowComments;
    _allowDownloads = draft.allowSharing;
    _tags.clear();
    _tags.addAll(draft.taggedUsers);

    final bool hasMediaUrl =
        draft.mediaUrl != null && draft.mediaUrl!.trim().isNotEmpty;
    final String? mediaId = draft.uploadedMediaId;

    if (draft.mediaPath != null && draft.mediaPath!.isNotEmpty) {
      final File file = File(draft.mediaPath!);
      if (file.existsSync()) {
        _selectedMedia = GalleryMediaItem(
          id: 'draft_${draft.id}',
          isVideo: draft.mediaType == MediaType.video,
          filePath: draft.mediaPath,
          mediaUrl: draft.mediaUrl,
          thumbnailUrl: draft.thumbnailUrl,
          durationSeconds: 47,
        );
      } else if (hasMediaUrl) {
        _selectedMedia = GalleryMediaItem(
          id: 'draft_${draft.id}',
          isVideo: draft.mediaType == MediaType.video,
          mediaUrl: draft.mediaUrl,
          thumbnailUrl: draft.thumbnailUrl,
          durationSeconds: 47,
        );
      }
    } else if (hasMediaUrl) {
      _selectedMedia = GalleryMediaItem(
        id: 'draft_${draft.id}',
        isVideo: draft.mediaType == MediaType.video,
        mediaUrl: draft.mediaUrl,
        thumbnailUrl: draft.thumbnailUrl,
        durationSeconds: 47,
      );
    }

    if (hasMediaUrl && mediaId != null && mediaId.isNotEmpty) {
      // Re-hydrate the uploaded media state so the user does NOT have to re-process video or image
      _uploadedMediaId = mediaId;
      _uploadResult = MediaUploadResult(
        id: mediaId,
        status: 'ready',
        downloadUrl: draft.mediaUrl,
        thumbnailUrl: draft.thumbnailUrl,
      );
      _uploadStatus = MediaUploadStatus.ready;
      _uploadProgress = 1.0;
      _uploadError = null;
    } else {
      _resetUploadState();
    }
    notifyListeners();
  }

  // ── Actions ──────────────────────────────────────────────────────────
  void setMediaType(MediaType type) {
    _mediaType = type;
    if (type == MediaType.text) {
      _selectedMedia = null;
      _uploadedMediaId = null;
      _uploadResult = null;
      _resetUploadState();
    } else if (type == MediaType.video) {
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

  void clearSelectedMedia() {
    _selectedMedia = null;
    _uploadedMediaId = null;
    _uploadResult = null;
    _resetUploadState();
    notifyListeners();
  }

  void selectMedia(GalleryMediaItem media) {
    _selectedMedia = media;
    if (media.isVideo) {
      _totalDurationSeconds =
          media.durationSeconds > 0 ? media.durationSeconds : 47;
      _trimStart = 0.0;
      if (_totalDurationSeconds > maxVideoDurationLimitSeconds) {
        _trimEnd = (maxVideoDurationLimitSeconds / _totalDurationSeconds)
            .clamp(0.0, 1.0);
      } else {
        _trimEnd = 1.0;
      }
    }
    _resetUploadState();
    notifyListeners();
    // Auto-trigger upload in background as user prepares post
    startMediaUpload();
  }

  void updateCaption(String text) {
    _caption = text;
    notifyListeners();
  }

  void setSelectedCommunity(String community, {String? id}) {
    _selectedCommunity = community;
    _selectedCommunityId = id;
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
    _currentDraftId = null;
    _caption = '';
    _tags.clear();
    _selectedCommunity = 'Transgender';
    _selectedCommunityId = null;
    _visibility = PostVisibility.followers;
    _allowComments = true;
    _allowDownloads = false;
    _trimStart = 0.0;
    _trimEnd = 1.0;
    _resetUploadState();
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
              if (_mediaType == MediaType.photo &&
                  (_selectedMedia == null || _selectedMedia!.isVideo)) {
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

    if (_mediaType == MediaType.photo && _photoGallery.isNotEmpty) {
      _selectedMedia = _photoGallery.first;
    }
  }
}
