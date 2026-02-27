import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';

/// Abstract repository for safe zone operations.
abstract class SafeZoneRepository {
  /// Stream of active safe zones for a patient.
  Stream<List<SafeZone>> watchSafeZones(String patientId);

  /// Save (create or update) a safe zone.
  Future<void> saveSafeZone(String patientId, SafeZone safeZone);

  /// Delete a safe zone.
  Future<void> deleteSafeZone(String patientId, String zoneId);

  /// Stream of recent safe zone events.
  Stream<List<SafeZoneEvent>> watchRecentEvents(String patientId,
      {int limit = 20});
}
