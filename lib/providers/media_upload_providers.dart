import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/services/media_upload_service.dart';

final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadService();
});
