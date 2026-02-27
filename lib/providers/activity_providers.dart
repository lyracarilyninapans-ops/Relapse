import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relapse_flutter/models/activity_record.dart';
import 'package:relapse_flutter/models/daily_summary.dart';
import 'package:relapse_flutter/models/safe_zone.dart';
import 'package:relapse_flutter/providers/auth_providers.dart';
import 'package:relapse_flutter/providers/patient_providers.dart';
import 'package:relapse_flutter/repositories/activity_repository.dart';

// ─── Date Range Filter ──────────────────────────────────────────────────

enum DateRangeFilter { today, thisWeek, thisMonth }

final selectedDateRangeFilterProvider =
    StateProvider<DateRangeFilter>((ref) => DateRangeFilter.today);

final selectedDateRangeProvider = Provider<DateRange>((ref) {
  final filter = ref.watch(selectedDateRangeFilterProvider);
  switch (filter) {
    case DateRangeFilter.today:
      return DateRange.today();
    case DateRangeFilter.thisWeek:
      return DateRange.thisWeek();
    case DateRangeFilter.thisMonth:
      return DateRange.thisMonth();
  }
});

// ─── Activity Feed ──────────────────────────────────────────────────────

/// Real-time activity feed for the selected date range.
final activityFeedProvider =
    StreamProvider<List<ActivityRecord>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return const Stream.empty();
  final range = ref.watch(selectedDateRangeProvider);
  return ref.watch(activityRepositoryProvider).watchActivityFeed(patientId, range);
});

// ─── Live Location ──────────────────────────────────────────────────────

/// Live location (latest GPS point from watch).
final liveLocationProvider =
    StreamProvider<ActivityRecord?>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return const Stream.empty();
  return ref.watch(activityRepositoryProvider).watchLiveLocation(patientId);
});

// ─── Daily Summary ──────────────────────────────────────────────────────

/// Daily summary stats (distance, time outside, places).
final dailySummaryProvider =
    FutureProvider<DailySummary?>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Future.value(null);
  return ref
      .watch(activityRepositoryProvider)
      .getDailySummary(patientId, DateTime.now());
});

// ─── Hourly Activity ────────────────────────────────────────────────────

/// Hourly activity counts for movement chart (24 int values).
final hourlyActivityProvider =
    FutureProvider<List<int>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Future.value(List.filled(24, 0));
  return ref
      .watch(activityRepositoryProvider)
      .getHourlyActivity(patientId, DateTime.now());
});

// ─── Location History ───────────────────────────────────────────────────

/// Location history for timeline.
final locationHistoryProvider =
    FutureProvider<List<ActivityRecord>>((ref) {
  final patientId = ref.watch(selectedPatientIdProvider);
  if (patientId == null) return Future.value([]);
  final range = ref.watch(selectedDateRangeProvider);
  return ref
      .watch(activityRepositoryProvider)
      .getLocationHistory(patientId, range);
});

// ─── Safe Zone Status ───────────────────────────────────────────────────

enum SafeZoneStatus { inside, outside, unknown }

/// Safe zones for current patient.
final safeZoneConfigProvider =
    StreamProvider<List<SafeZone>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  final patientId = ref.watch(selectedPatientIdProvider);
  if (authUser == null || patientId == null) return const Stream.empty();
  return ref
      .watch(safeZoneRemoteSourceProvider)
      .watchSafeZones(authUser.uid, patientId);
});

/// Derived safe zone status from live location + safe zone config.
final safeZoneStatusProvider = Provider<SafeZoneStatus>((ref) {
  final liveLocation = ref.watch(liveLocationProvider).valueOrNull;
  final safeZones = ref.watch(safeZoneConfigProvider).valueOrNull;

  if (liveLocation == null ||
      liveLocation.latitude == null ||
      liveLocation.longitude == null ||
      safeZones == null ||
      safeZones.isEmpty) {
    return SafeZoneStatus.unknown;
  }

  for (final zone in safeZones) {
    final distance = _haversineDistance(
      liveLocation.latitude!,
      liveLocation.longitude!,
      zone.centerLat,
      zone.centerLng,
    );
    if (distance <= zone.radiusMeters) {
      return SafeZoneStatus.inside;
    }
  }
  return SafeZoneStatus.outside;
});

/// Haversine formula to calculate distance in meters between two GPS points.
double _haversineDistance(
    double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0; // meters
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
