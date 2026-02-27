import 'package:relapse_flutter/data/remote/safe_zone_event_remote_source.dart';
import 'package:relapse_flutter/data/remote/safe_zone_remote_source.dart';
import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/models/safe_zone_event.dart';
import 'package:relapse_flutter/repositories/safe_zone_repository.dart';

/// Firestore-backed implementation of [SafeZoneRepository].
class SafeZoneRepositoryImpl implements SafeZoneRepository {
  final SafeZoneRemoteSource _safeZoneSource;
  final SafeZoneEventRemoteSource _eventSource;
  final String _uid;

  SafeZoneRepositoryImpl({
    required SafeZoneRemoteSource safeZoneSource,
    required SafeZoneEventRemoteSource eventSource,
    required String uid,
  })  : _safeZoneSource = safeZoneSource,
        _eventSource = eventSource,
        _uid = uid;

  @override
  Stream<List<SafeZone>> watchSafeZones(String patientId) {
    return _safeZoneSource.watchSafeZones(_uid, patientId);
  }

  @override
  Future<void> saveSafeZone(String patientId, SafeZone safeZone) {
    return _safeZoneSource.saveSafeZone(_uid, patientId, safeZone);
  }

  @override
  Future<void> deleteSafeZone(String patientId, String zoneId) {
    return _safeZoneSource.deleteSafeZone(_uid, patientId, zoneId);
  }

  @override
  Stream<List<SafeZoneEvent>> watchRecentEvents(String patientId,
      {int limit = 20}) {
    return _eventSource.watchRecentEvents(_uid, patientId, limit: limit);
  }
}
