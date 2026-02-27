import 'package:cloud_firestore/cloud_firestore.dart';

enum SafeZoneEventType { enter, exit }

class SafeZoneEvent {
  final String id;
  final String safeZoneId;
  final SafeZoneEventType eventType;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  const SafeZoneEvent({
    required this.id,
    required this.safeZoneId,
    required this.eventType,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  factory SafeZoneEvent.fromJson(Map<String, dynamic> json) {
    return SafeZoneEvent(
      id: json['id'] as String,
      safeZoneId: json['safeZoneId'] as String,
      eventType: SafeZoneEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
        orElse: () => SafeZoneEventType.exit,
      ),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'safeZoneId': safeZoneId,
      'eventType': eventType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
