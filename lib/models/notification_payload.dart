/// Payload attached to a notification for navigation and display purposes.
class NotificationPayload {
  final String type;
  final String? patientId;
  final String? eventId;
  final String? reminderId;
  final String? screen;
  final Map<String, String> extra;

  const NotificationPayload({
    required this.type,
    this.patientId,
    this.eventId,
    this.reminderId,
    this.screen,
    this.extra = const {},
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      type: map['type'] as String? ?? 'unknown',
      patientId: map['patientId'] as String?,
      eventId: map['eventId'] as String?,
      reminderId: map['reminderId'] as String?,
      screen: map['screen'] as String?,
      extra: (map['extra'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
    );
  }

  Map<String, String> toMap() {
    final map = <String, String>{
      'type': type,
      ...extra,
    };

    if (patientId != null) map['patientId'] = patientId!;
    if (eventId != null) map['eventId'] = eventId!;
    if (reminderId != null) map['reminderId'] = reminderId!;
    if (screen != null) map['screen'] = screen!;

    return map;
  }
}
