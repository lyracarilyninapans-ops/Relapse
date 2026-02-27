import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityEventType {
  locationUpdate,
  safeZoneEnter,
  safeZoneExit,
  reminderTriggered,
  watchDisconnected,
  watchReconnected,
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
      eventType: ActivityEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => ActivityEventType.locationUpdate,
      ),
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
      'eventType': eventType.name,
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
