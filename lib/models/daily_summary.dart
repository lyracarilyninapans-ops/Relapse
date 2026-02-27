class DailySummary {
  final String id;
  final String patientId;
  final String date;
  final int stepCount;
  final double distanceMeters;
  final int activeMinutes;
  final int placesVisited;
  final int safeZoneExits;
  final int remindersTriggered;
  final int totalEvents;

  const DailySummary({
    required this.id,
    required this.patientId,
    required this.date,
    this.stepCount = 0,
    this.distanceMeters = 0,
    this.activeMinutes = 0,
    this.placesVisited = 0,
    this.safeZoneExits = 0,
    this.remindersTriggered = 0,
    this.totalEvents = 0,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? '',
      date: json['date'] as String,
      stepCount: (json['stepCount'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      activeMinutes: (json['activeMinutes'] as num?)?.toInt() ?? 0,
      placesVisited: (json['placesVisited'] as num?)?.toInt() ?? 0,
      safeZoneExits: (json['safeZoneExits'] as num?)?.toInt() ?? 0,
      remindersTriggered: (json['remindersTriggered'] as num?)?.toInt() ?? 0,
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'date': date,
      'stepCount': stepCount,
      'distanceMeters': distanceMeters,
      'activeMinutes': activeMinutes,
      'placesVisited': placesVisited,
      'safeZoneExits': safeZoneExits,
      'remindersTriggered': remindersTriggered,
      'totalEvents': totalEvents,
    };
  }
}
