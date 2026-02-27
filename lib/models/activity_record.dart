import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityEventType {
  locationUpdate,
  safeZoneEnter,
  safeZoneExit,
  reminderTriggered,
  watchDisconnected,
  watchReconnected;

  /// Snake_case string used by the watch and Cloud Functions.
  String get firestoreValue {
    switch (this) {
      case ActivityEventType.locationUpdate:
        return 'location_update';
      case ActivityEventType.safeZoneEnter:
        return 'safe_zone_enter';
      case ActivityEventType.safeZoneExit:
        return 'safe_zone_exit';
      case ActivityEventType.reminderTriggered:
        return 'reminder_triggered';
      case ActivityEventType.watchDisconnected:
        return 'watch_disconnected';
      case ActivityEventType.watchReconnected:
        return 'watch_reconnected';
    }
  }

  static ActivityEventType fromFirestore(String value) {
    switch (value) {
      case 'location_update':
        return ActivityEventType.locationUpdate;
      case 'safe_zone_enter':
        return ActivityEventType.safeZoneEnter;
      case 'safe_zone_exit':
        return ActivityEventType.safeZoneExit;
      case 'reminder_triggered':
        return ActivityEventType.reminderTriggered;
      case 'watch_disconnected':
        return ActivityEventType.watchDisconnected;
      case 'watch_reconnected':
        return ActivityEventType.watchReconnected;
      default:
        return ActivityEventType.locationUpdate;
    }
  }
}

class ActivityRecord {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final ActivityEventType eventType;
  final Map<String, dynamic>? metadata;

  const ActivityRecord({
    required this.id,
    required this.patientId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.eventType,
    this.metadata,
  });

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      eventType: ActivityEventType.fromFirestore(json['eventType'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
      'eventType': eventType.firestoreValue,
      'metadata': metadata,
    };
  }

  ActivityRecord copyWith({
    String? id,
    String? patientId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    ActivityEventType? eventType,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      eventType: eventType ?? this.eventType,
      metadata: metadata ?? this.metadata,
    );
  }
}
