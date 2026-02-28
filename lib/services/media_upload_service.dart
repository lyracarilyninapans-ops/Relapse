import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Service for uploading media files (photos, audio, video) to Firebase Storage.
class MediaUploadService {
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
      return File(picked.path);
    } catch (e) {
      debugPrint('Error picking photo: $e');
      return null;
    }
  }

  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (picked == null) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  // ─── Firebase Storage Upload ────────────────────────────────────────

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putFile(file);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
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
    final ext = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'users/$uid/patients/$patientId/memories/$reminderId/${mediaType}_$timestamp.$ext';
    return uploadFile(file: file, storagePath: path, onProgress: onProgress);
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
    final path = 'users/$uid/profile/$subPath\_$timestamp.$ext';
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
}
