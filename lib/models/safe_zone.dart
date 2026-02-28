class SafeZone {
  final String id;
  final String patientId;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final bool isActive;
  final bool alarmEnabled;
  final bool vibrationEnabled;
  final bool alertOnExit;
  final String? contactOnExit;

  const SafeZone({
    required this.id,
    required this.patientId,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMeters,
    this.isActive = true,
    this.alarmEnabled = true,
    this.vibrationEnabled = true,
    this.alertOnExit = true,
    this.contactOnExit,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      centerLat: (json['centerLat'] as num).toDouble(),
      centerLng: (json['centerLng'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      alarmEnabled: json['alarmEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      alertOnExit: json['alertOnExit'] as bool? ?? true,
      contactOnExit: json['contactOnExit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
      'alarmEnabled': alarmEnabled,
      'vibrationEnabled': vibrationEnabled,
      'alertOnExit': alertOnExit,
      'contactOnExit': contactOnExit,
    };
  }

  SafeZone copyWith({
    String? id,
    String? patientId,
    double? centerLat,
    double? centerLng,
    double? radiusMeters,
    bool? isActive,
    bool? alarmEnabled,
    bool? vibrationEnabled,
    bool? alertOnExit,
    String? contactOnExit,
  }) {
    return SafeZone(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      alertOnExit: alertOnExit ?? this.alertOnExit,
      contactOnExit: contactOnExit ?? this.contactOnExit,
    );
  }
}
