enum MediaType { photo, audio, video }

class MediaItem {
  final String id;
  final String reminderId;
  final MediaType type;
  final String? localPath;
  final String? cloudUrl;
  final String? thumbnailUrl;

  const MediaItem({
    required this.id,
    required this.reminderId,
    required this.type,
    this.localPath,
    this.cloudUrl,
    this.thumbnailUrl,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      reminderId: json['reminderId'] as String,
      type: MediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MediaType.photo,
      ),
      localPath: json['localPath'] as String?,
      cloudUrl: json['cloudUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reminderId': reminderId,
      'type': type.name,
      'localPath': localPath,
      'cloudUrl': cloudUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
