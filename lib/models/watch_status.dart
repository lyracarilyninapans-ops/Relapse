import 'package:cloud_firestore/cloud_firestore.dart';

class WatchStatus {
  final String watchId;
  final bool isConnected;
  final int? batteryLevel;
  final DateTime? lastSyncTimestamp;
  final String? firmwareVersion;

  const WatchStatus({
    required this.watchId,
    this.isConnected = false,
    this.batteryLevel,
    this.lastSyncTimestamp,
    this.firmwareVersion,
  });

  factory WatchStatus.fromJson(Map<String, dynamic> json) {
    return WatchStatus(
      watchId: json['watchId'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      batteryLevel: json['batteryLevel'] as int?,
      lastSyncTimestamp: json['lastSyncTimestamp'] != null
          ? (json['lastSyncTimestamp'] as Timestamp).toDate()
          : null,
      firmwareVersion: json['firmwareVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watchId': watchId,
      'isConnected': isConnected,
      'batteryLevel': batteryLevel,
      'lastSyncTimestamp': lastSyncTimestamp != null
          ? Timestamp.fromDate(lastSyncTimestamp!)
          : null,
      'firmwareVersion': firmwareVersion,
    };
  }
}
