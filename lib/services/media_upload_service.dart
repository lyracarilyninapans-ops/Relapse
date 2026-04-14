import 'dart:io';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading media files (photos, audio, video) to Firebase Storage.
class MediaUploadService {
  static const Duration _maxAudioDuration = Duration(minutes: 2);
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  MediaUploadService({
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  // ─── Image Picking ──────────────────────────────────────────────────

  Future<File?> pickPhoto({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return null;
      
      final file = File(picked.path);
      if (file.lengthSync() > 50 * 1024 * 1024) {
        throw Exception('Photo exceeds the 50MB size limit.');
      }
      return file;
    } catch (e) {
      debugPrint('Error picking photo: $e');
      rethrow;
    }
  }

  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null) return null;
      
      final file = File(picked.path);
      if (file.lengthSync() > 50 * 1024 * 1024) {
        throw Exception('Video exceeds the 50MB size limit.');
      }
      return file;
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  // ─── Firebase Storage Upload ────────────────────────────────────────

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    if (!file.existsSync()) {
      throw Exception('File does not exist: ${file.path}');
    }

    final ref = _storage.ref().child(storagePath);

    // Detect MIME type so Firebase Storage stores it with the correct
    // content-type header; this prevents getDownloadURL() failures.
    final mimeType = _mimeTypeFromPath(file.path);
    final metadata = SettableMetadata(contentType: mimeType);

    final uploadTask = ref.putFile(file, metadata);
    StreamSubscription<TaskSnapshot>? progressSubscription;

    if (onProgress != null) {
      progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      }, onError: (Object error, StackTrace stackTrace) {
        unawaited(progressSubscription?.cancel());
      });
    }

    try {
      await uploadTask;
      return await ref.getDownloadURL();
    } finally {
      await progressSubscription?.cancel();
    }
  }

  /// Uploads a memory media file (photo/audio/video) and returns the download URL.
  Future<String> uploadMemoryMedia({
    required File file,
    required String uid,
    required String patientId,
    required String reminderId,
    required String mediaType,
    void Function(double progress)? onProgress,
  }) async {
    if (mediaType == 'audio') {
      await _validateAudioDuration(file);
    }

    final ext = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'users/$uid/patients/$patientId/memories/$reminderId/${mediaType}_$timestamp.$ext';
    return uploadFile(file: file, storagePath: path, onProgress: onProgress);
  }

  Future<void> _validateAudioDuration(File file) async {
    final player = AudioPlayer();
    StreamSubscription<Duration>? durationSubscription;
    final completer = Completer<Duration?>();

    try {
      durationSubscription = player.onDurationChanged.listen((duration) {
        if (!completer.isCompleted && duration > Duration.zero) {
          completer.complete(duration);
        }
      });

      await player.setSourceDeviceFile(file.path);

      Duration? duration = await player.getDuration();
      duration ??= await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      if (duration == null || duration <= Duration.zero) {
        throw Exception('Unable to read audio duration. Please choose another file.');
      }

      if (duration > _maxAudioDuration) {
        throw Exception('Audio length must be 2 minutes or less.');
      }
    } finally {
      await durationSubscription?.cancel();
      await player.dispose();
    }
  }

  /// Uploads a profile picture and returns the download URL.
  Future<String> uploadProfilePhoto({
    required File file,
    required String uid,
    required String subPath,
    void Function(double progress)? onProgress,
  }) async {
    final ext = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'users/$uid/profile/${subPath}_$timestamp.$ext';
    return uploadFile(file: file, storagePath: path, onProgress: onProgress);
  }

  /// Deletes a file from Firebase Storage by its download URL.
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Resolve MIME type from a file path extension.
  static String _mimeTypeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }
}
