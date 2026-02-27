import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_item.dart';

class MemoryReminder {
  final String id;
  final String patientId;
  final String title;
  final String? description;
  final double? latitude;
  final double? longitude;
  final double radiusMeters;
  final List<MediaItem> mediaItems;
  final DateTime createdAt;
  final bool isActive;

  const MemoryReminder({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    this.latitude,
    this.longitude,
    this.radiusMeters = 100,
    this.mediaItems = const [],
    required this.createdAt,
    this.isActive = true,
  });

  factory MemoryReminder.fromJson(Map<String, dynamic> json) {
    return MemoryReminder(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 100,
      mediaItems: (json['mediaItems'] as List<dynamic>?)
              ?.map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'mediaItems': mediaItems.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  MemoryReminder copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    List<MediaItem>? mediaItems,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return MemoryReminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      mediaItems: mediaItems ?? this.mediaItems,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
