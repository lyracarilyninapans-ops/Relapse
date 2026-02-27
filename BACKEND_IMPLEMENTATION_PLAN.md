# Relapse Flutter App — Backend Implementation Plan

> **Current State:** The Flutter app is a pure UI shell with zero backend, persistence, or business logic. All data is hardcoded. Two Riverpod providers exist but only manage ephemeral form state.

> **Priority Focus:** The Activity Screen is the first feature to be fully functional end-to-end. All backend phases are ordered to deliver the Activity Screen's data pipeline (watch → cloud → local DB → UI) as early as possible.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Activity Screen — Data Requirements](#2-activity-screen--data-requirements)
3. [Phase 1 — Foundation (Dependencies, Models, DI)](#3-phase-1--foundation)
4. [Phase 2 — Authentication](#4-phase-2--authentication)
5. [Phase 3 — Activity Data Layer (Local DB + Firestore)](#5-phase-3--activity-data-layer)
6. [Phase 4 — Activity Providers & Screen Wiring](#6-phase-4--activity-providers--screen-wiring)
7. [Phase 5 — Watch Communication (Wearable Data Layer)](#7-phase-5--watch-communication)
8. [Phase 6 — Geofencing & Location Services](#8-phase-6--geofencing--location-services)
9. [Phase 7 — Full Local Database & Remaining Repositories](#9-phase-7--full-local-database--remaining-repositories)
10. [Phase 8 — Memory Cues (Media & Geo-Reminders)](#10-phase-8--memory-cues)
11. [Phase 9 — Notifications & Alerts](#11-phase-9--notifications--alerts)
12. [Phase 10 — Offline Support & Maps](#12-phase-10--offline-support--maps)
13. [Phase 11 — Settings & Preferences](#13-phase-11--settings--preferences)
14. [Phase 12 — Testing & Hardening](#14-phase-12--testing--hardening)
15. [Dependency Summary](#15-dependency-summary)
16. [Directory Structure](#16-directory-structure)

---

## 1. Architecture Overview

### Chosen Architecture: **Clean Architecture + Riverpod**

```
┌─────────────────────────────────────────────────┐
│  UI Layer (Screens / Widgets)                   │
│  ↕  Riverpod Providers (state + logic)          │
├─────────────────────────────────────────────────┤
│  Domain Layer                                   │
│  • Entities (pure Dart models)                  │
│  • Use Cases (optional, for complex flows)      │
│  • Repository Interfaces (abstract)             │
├─────────────────────────────────────────────────┤
│  Data Layer                                     │
│  • Repository Implementations                   │
│  • Data Sources (local DB, Firebase, APIs)      │
│  • DTOs / Mappers                               │
│  • Services (location, watch comms, media)      │
└─────────────────────────────────────────────────┘
```

### State Management: **Riverpod** (already in project)

- `StateNotifierProvider` / `AsyncNotifierProvider` for complex state
- `FutureProvider` / `StreamProvider` for async data
- `Provider` for dependency injection of repositories/services

---

## 2. Activity Screen — Data Requirements

The Activity Screen is the **primary delivery target**. Every backend phase is sequenced to unblock it first. Below is a mapping of each UI element to the backend data it requires:

### 2.1 UI Element → Data Mapping

| UI Element | Required Data | Source | Model |
|---|---|---|---|
| **Date filter row** (Today / This Week / This Month) | Date range selector | Local (UI state) | — |
| **Current location card** (map + LIVE badge + address) | Patient's latest GPS coordinates, timestamp | Watch → Firestore → local DB | `ActivityRecord` (type: `location_update`) |
| **Safe Zone status pill** (Inside/Outside) | Whether latest location is within safe zone radius | Derived from `ActivityRecord` + `SafeZone` | `SafeZone`, `ActivityRecord` |
| **Daily summary — Distance** | Total distance traveled today | Watch aggregates → Firestore | `DailySummary.distanceMeters` |
| **Daily summary — Time Outside** | Minutes spent outside safe zone today | Watch aggregates → Firestore | `DailySummary.activeMinutes` |
| **Daily summary — Places** | Count of distinct locations visited | Watch aggregates → Firestore | `DailySummary.placesVisited` |
| **Movement pattern chart** (24 hourly bars) | Hourly activity level (location updates per hour) | Computed from `ActivityRecord` timestamps | `List<ActivityRecord>` grouped by hour |
| **Recent activity feed** (event tiles) | Typed events: safe zone enter/exit, reminder triggered, location update | Watch → Firestore (real-time) | `ActivityRecord` with `eventType` enum |
| **Location history timeline** (dot + line track) | Ordered list of significant locations with timestamps + durations | Watch → Firestore | `List<ActivityRecord>` (type: `location_update`) |
| **Home Screen — Activity stat** | Count of activity events today | Derived from `ActivityRecord` count | `DailySummary` or count query |

### 2.2 Models Required for Activity Screen

| Model | Priority | Fields Needed by Activity Screen |
|---|---|---|
| `ActivityRecord` | **P0** | `id`, `patientId`, `timestamp`, `latitude`, `longitude`, `eventType`, `metadata` |
| `DailySummary` | **P0** | `id`, `patientId`, `date`, `distanceMeters`, `activeMinutes`, `placesVisited`, `safeZoneExits`, `remindersTriggered`, `totalEvents` |
| `SafeZone` | **P0** | `id`, `patientId`, `centerLat`, `centerLng`, `radiusMeters`, `isActive` (needed to compute Inside/Outside pill) |
| `Patient` | **P0** | `id`, `name` (needed by all screens) |

### 2.3 Providers Required for Activity Screen

| Provider | Type | Feeds UI Element |
|---|---|---|
| `liveLocationProvider(patientId)` | `StreamProvider<ActivityRecord?>` | Current location card, LIVE badge |
| `activityFeedProvider(patientId, dateRange)` | `StreamProvider<List<ActivityRecord>>` | Recent activity feed, movement chart, timeline |
| `dailySummaryProvider(patientId, date)` | `FutureProvider<DailySummary>` | Daily summary cards (distance, time outside, places) |
| `hourlyActivityProvider(patientId, date)` | `FutureProvider<List<int>>` | Movement pattern bar chart (24 values) |
| `locationHistoryProvider(patientId, dateRange)` | `FutureProvider<List<ActivityRecord>>` | Location history timeline |
| `safeZoneStatusProvider(patientId)` | `Provider<SafeZoneStatus>` | Safe zone pill (derived from live location + safe zone config) |
| `selectedDateRangeProvider` | `StateProvider<DateRange>` | Date filter row state |

### 2.4 End-to-End Pipeline

```
Watch (GPS + sensors)
   │
   ├── Location update (every 30s)
   ├── Safe zone enter/exit event
   ├── Geo-reminder triggered event
   │
   ▼
Firestore: users/{uid}/patients/{patientId}/
   ├── activityRecords/{id}    ← real-time stream
   └── dailySummaries/{date}   ← updated periodically
   │
   ▼
Flutter App (Riverpod providers)
   ├── StreamProvider listens to Firestore snapshots
   ├── Caches to local SQLite for offline
   │
   ▼
Activity Screen UI
   ├── Current location card   ← liveLocationProvider
   ├── Daily summary cards     ← dailySummaryProvider
   ├── Movement chart          ← hourlyActivityProvider
   ├── Activity feed           ← activityFeedProvider
   └── Location timeline       ← locationHistoryProvider
```

---

## 3. Phase 1 — Foundation

### 2.1 Add Dependencies to `pubspec.yaml`

```yaml
dependencies:
  # State Management (already present)
  flutter_riverpod: ^2.6.1

  # Firebase
  firebase_core: ^3.12.0
  firebase_auth: ^5.5.0
  cloud_firestore: ^5.6.0
  firebase_storage: ^12.4.0
  firebase_messaging: ^15.2.0

  # Local Database
  sqflite: ^2.4.2
  path: ^1.9.1

  # Networking / Serialization
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # Location & Geofencing
  geolocator: ^13.0.2
  geofencing_flutter: ^0.0.2   # or geo_fence_service
  flutter_local_notifications: ^18.0.1

  # Watch Communication
  flutter_wear_os_connectivity: ^1.0.2  # or custom platform channel

  # Media
  image_picker: ^1.1.2
  video_player: ^2.9.2
  audioplayers: ^6.1.0
  path_provider: ^2.1.5
  file_picker: ^9.2.0

  # Connectivity
  connectivity_plus: ^6.1.2

  # Maps (already present)
  google_maps_flutter: ^2.6.1

  # Misc
  uuid: ^4.5.1
  intl: ^0.19.0
  shared_preferences: ^2.5.0
  cached_network_image: ^3.3.1

dev_dependencies:
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
  mockito: ^5.4.5
  flutter_test:
    sdk: flutter
```

### 2.2 Firebase Project Setup

- [ ] Create Firebase project in Firebase Console
- [ ] Add Android app (`com.example.relapse_flutter`)
- [ ] Download `google-services.json`
- [ ] Initialize Firebase in `main.dart` before `runApp()`

### 2.3 Define Domain Models

Create `lib/models/` with Freezed data classes:

| Model | Fields | Purpose |
|---|---|---|
| `AppUser` | `uid`, `email`, `displayName`, `photoUrl`, `createdAt` | Firebase Auth user profile |
| `CaregiverProfile` | `uid`, `name`, `phone`, `bio`, `photoUrl` | Caregiver-specific data |
| `Patient` | `id`, `caregiverUid`, `name`, `age`, `notes`, `photoUrl`, `pairedWatchId`, `createdAt` | Patient record |
| `MemoryReminder` | `id`, `patientId`, `title`, `description`, `latitude`, `longitude`, `radiusMeters`, `mediaItems[]`, `createdAt`, `isActive` | Geo-triggered memory cue |
| `MediaItem` | `id`, `reminderId`, `type` (photo/audio/video), `localPath`, `cloudUrl`, `thumbnailUrl` | Media attachment |
| `SafeZone` | `id`, `patientId`, `centerLat`, `centerLng`, `radiusMeters`, `isActive`, `alarmEnabled`, `vibrationEnabled`, `contactOnExit` | Safe zone config |
| `SafeZoneEvent` | `id`, `safeZoneId`, `eventType` (enter/exit), `timestamp`, `latitude`, `longitude` | Safe zone breach log |
| `ActivityRecord` | `id`, `patientId`, `timestamp`, `latitude`, `longitude`, `eventType`, `metadata` | Patient location/activity data point |
| `DailySummary` | `id`, `patientId`, `date`, `stepCount`, `distanceMeters`, `activeMinutes`, `safeZoneExits`, `remindersTriggered` | Aggregated daily stats |
| `WatchStatus` | `watchId`, `isConnected`, `batteryLevel`, `lastSyncTimestamp`, `firmwareVersion` | Watch connectivity state |
| `PairingInfo` | `pairingCode`, `watchId`, `pairedAt`, `status` | Watch pairing state |

---

## 4. Phase 2 — Authentication

### 3.1 Auth Service (`lib/services/auth_service.dart`)

```
AuthService (abstract)
├── signInWithEmail(email, password) → AppUser
├── signUpWithEmail(email, password, displayName) → AppUser
├── signOut() → void
├── sendPasswordResetEmail(email) → void
├── currentUser → Stream<AppUser?>
├── isSignedIn → bool
└── deleteAccount() → void

FirebaseAuthService implements AuthService
```

### 3.2 Auth Providers (`lib/providers/auth_providers.dart`)

| Provider | Type | Purpose |
|---|---|---|
| `authServiceProvider` | `Provider<AuthService>` | Provides FirebaseAuthService instance |
| `authStateProvider` | `StreamProvider<AppUser?>` | Wraps `FirebaseAuth.authStateChanges()` |
| `signInProvider` | `StateNotifierProvider` | Manages sign-in form state + async call |
| `signUpProvider` | `StateNotifierProvider` | Manages sign-up form state + async call |

### 3.3 Route Guards

- Create `AuthGuard` widget or use `ref.watch(authStateProvider)` in `main.dart`
- Redirect unauthenticated users to `/login`
- Redirect authenticated users away from auth screens to `/main`
- Replace current `Navigator.pushReplacementNamed` hardcoded navigation

### 3.4 Wire Up Existing Screens

| Screen | Changes Needed |
|---|---|
| `login_screen.dart` | Call `authService.signInWithEmail()`, show loading/error states |
| `signup_screen.dart` | Call `authService.signUpWithEmail()`, validate password, create profile |
| `forgot_password_screen.dart` | Call `authService.sendPasswordResetEmail()` |
| `splash_screen.dart` | Check `authStateProvider` → route to `/login` or `/main` |

---

## 5. Phase 3 — Activity Data Layer (Local DB + Firestore)

> **This phase is brought forward from the original Phases 3+4 to unblock the Activity Screen as fast as possible.** It creates only the tables, data sources, repositories, and Firestore listeners needed for activity data.

### 5.1 SQLite Database — Activity Tables First

Create `lib/data/local/app_database.dart` with the **activity-critical tables only** in the first pass:

| Table | Maps To | Purpose for Activity Screen |
|---|---|---|
| `activity_records` | `ActivityRecord` | Feed, chart, timeline, live location |
| `daily_summaries` | `DailySummary` | Distance, time outside, places stats |
| `safe_zones` | `SafeZone` | Inside/Outside pill calculation |
| `patients` | `Patient` | Patient name, ID (needed everywhere) |

> Remaining tables (`memory_reminders`, `media_items`, `safe_zone_events`) are added in Phase 7.

### 5.2 Activity Local Data Sources

```
lib/data/local/
├── app_database.dart                  — DB init with activity tables
├── activity_local_source.dart         — CRUD for activity_records
├── daily_summary_local_source.dart    — CRUD for daily_summaries
├── safe_zone_local_source.dart        — Read safe zone config
└── patient_local_source.dart          — Read patient info
```

Key queries in `activity_local_source.dart`:
```dart
Future<List<ActivityRecord>> getRecordsByDateRange(String patientId, DateTime start, DateTime end);
Future<ActivityRecord?> getLatestRecord(String patientId);
Future<List<ActivityRecord>> getRecordsByType(String patientId, String eventType, DateTime date);
Future<int> getRecordCountForDate(String patientId, DateTime date);
Future<List<Map<String, dynamic>>> getHourlyActivityCounts(String patientId, DateTime date);
Future<void> insertRecords(List<ActivityRecord> records);
Future<void> deleteOlderThan(DateTime cutoff);
```

### 5.3 Activity Firestore Listeners

```
lib/data/remote/
├── activity_remote_source.dart        — Listen to activityRecords collection
├── daily_summary_remote_source.dart   — Listen to dailySummaries collection
├── safe_zone_remote_source.dart       — Read safe zone config
└── patient_remote_source.dart         — Read patient info
```

`activity_remote_source.dart` — key methods:
```dart
/// Real-time stream of new activity records (watch uploads to Firestore)
Stream<List<ActivityRecord>> watchActivityRecords(String uid, String patientId, DateTime since);

/// Fetch daily summary for a specific date
Future<DailySummary?> getDailySummary(String uid, String patientId, DateTime date);

/// Real-time stream of daily summary updates
Stream<DailySummary?> watchDailySummary(String uid, String patientId, DateTime date);
```

### 5.4 Activity Repository

```dart
/// lib/repositories/activity_repository.dart
abstract class ActivityRepository {
  /// Real-time stream of activity records (feed, timeline)
  Stream<List<ActivityRecord>> watchActivityFeed(String patientId, DateRange range);

  /// Latest location record for live tracking
  Stream<ActivityRecord?> watchLiveLocation(String patientId);

  /// Daily summary (distance, time outside, places)
  Future<DailySummary?> getDailySummary(String patientId, DateTime date);
  Stream<DailySummary?> watchDailySummary(String patientId, DateTime date);

  /// Hourly activity counts for movement chart (24 values)
  Future<List<int>> getHourlyActivity(String patientId, DateTime date);

  /// Location history for timeline view
  Future<List<ActivityRecord>> getLocationHistory(String patientId, DateRange range);

  /// Cache Firestore data to local DB
  Future<void> cacheRecords(List<ActivityRecord> records);
}
```

Implementation (`activity_repository_impl.dart`):
- Listens to Firestore `activityRecords` via `StreamProvider`
- Caches every received record to SQLite
- Returns local DB data when offline
- Computes `getHourlyActivity()` by grouping cached records by hour

### 5.5 Repository Providers

```dart
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl(
    localSource: ref.watch(activityLocalSourceProvider),
    remoteSource: ref.watch(activityRemoteSourceProvider),
    summaryLocalSource: ref.watch(dailySummaryLocalSourceProvider),
    summaryRemoteSource: ref.watch(dailySummaryRemoteSourceProvider),
  );
});
```

---

## 6. Phase 4 — Activity Providers & Screen Wiring

> **This phase connects the Activity Screen UI to real data.** After this phase, the Activity Screen is functional (showing data from Firestore that the watch uploads).

### 6.1 Activity Providers

```dart
/// lib/providers/activity_providers.dart

/// Currently selected date range filter
final selectedDateRangeProvider = StateProvider<DateRange>((ref) => DateRange.today);

/// Real-time activity feed for the selected date range
final activityFeedProvider = StreamProvider.family<List<ActivityRecord>, String>((ref, patientId) {
  final range = ref.watch(selectedDateRangeProvider);
  return ref.watch(activityRepositoryProvider).watchActivityFeed(patientId, range);
});

/// Live location (latest GPS point from watch)
final liveLocationProvider = StreamProvider.family<ActivityRecord?, String>((ref, patientId) {
  return ref.watch(activityRepositoryProvider).watchLiveLocation(patientId);
});

/// Daily summary stats (distance, time outside, places)
final dailySummaryProvider = FutureProvider.family<DailySummary?, ({String patientId, DateTime date})>((ref, params) {
  return ref.watch(activityRepositoryProvider).getDailySummary(params.patientId, params.date);
});

/// Hourly activity counts for movement chart (24 int values)
final hourlyActivityProvider = FutureProvider.family<List<int>, ({String patientId, DateTime date})>((ref, params) {
  return ref.watch(activityRepositoryProvider).getHourlyActivity(params.patientId, params.date);
});

/// Location history for timeline
final locationHistoryProvider = FutureProvider.family<List<ActivityRecord>, ({String patientId, DateRange range})>((ref, params) {
  return ref.watch(activityRepositoryProvider).getLocationHistory(params.patientId, params.range);
});

/// Safe zone status (derived)
final safeZoneStatusProvider = Provider.family<SafeZoneStatus, String>((ref, patientId) {
  final liveLocation = ref.watch(liveLocationProvider(patientId)).valueOrNull;
  final safeZone = ref.watch(safeZoneConfigProvider(patientId)).valueOrNull;
  if (liveLocation == null || safeZone == null) return SafeZoneStatus.unknown;
  final distance = calculateDistance(liveLocation, safeZone);
  return distance <= safeZone.radiusMeters ? SafeZoneStatus.inside : SafeZoneStatus.outside;
});
```

### 6.2 Wire Activity Screen to Providers

Changes to `activity_screen.dart`:

| Current (hardcoded) | After (provider-backed) |
|---|---|
| `"123 Main Street, Springfield"` | `ref.watch(liveLocationProvider(patientId))` → reverse geocode |
| `"2.4 km"` distance stat | `ref.watch(dailySummaryProvider(...)).distanceMeters` formatted |
| `"45 min"` time outside | `ref.watch(dailySummaryProvider(...)).activeMinutes` formatted |
| `"6"` places visited | `ref.watch(dailySummaryProvider(...)).placesVisited` |
| Mock 24-bar chart data | `ref.watch(hourlyActivityProvider(...))` → 24 int values |
| 6 hardcoded feed events | `ref.watch(activityFeedProvider(patientId))` → real event list |
| 4 hardcoded timeline entries | `ref.watch(locationHistoryProvider(...))` → real location trail |
| Date filter buttons (visual only) | `ref.read(selectedDateRangeProvider.notifier).state = ...` |

### 6.3 Wire Home Screen Activity Stat

| Current | After |
|---|---|
| `"8"` activity count | `ref.watch(dailySummaryProvider(...)).totalEvents` |

### 6.4 Milestone: Activity Screen Functional

After Phase 4, the Activity Screen shows **real data** from Firestore. The data pipeline is:
```
Watch → Firestore → Flutter Riverpod providers → Activity Screen UI
         (Phase 3)          (Phase 4)              (Phase 4)
```

---

## 7. Phase 5 — Watch Communication (Wearable Data Layer)

---

## 6. Phase 5 — Watch Communication

### 6.1 Wearable Data Layer Service (`lib/services/watch_communication_service.dart`)

```
WatchCommunicationService
├── discoverWatches() → List<WatchDevice>
├── sendPairingCode(code) → void
├── isPaired() → bool
├── syncPatientData(patient) → void
├── syncSafeZoneConfig(safeZone) → void
├── syncMemoryReminders(reminders) → void
├── onWatchStatusUpdate → Stream<WatchStatus>
├── onActivityData → Stream<ActivityRecord>
├── onSafeZoneEvent → Stream<SafeZoneEvent>
└── unpairWatch() → void
```

### 6.2 Communication Architecture

```
Flutter Phone App                    Wear OS Watch App
      │                                     │
      ├── Wearable MessageClient ◄──────────┤  Direct messages (pairing, commands)
      ├── Wearable DataClient    ◄──────────┤  Synced data items (status, config)
      │                                     │
      ├── Firestore ─────────────────────►  │  Cloud sync (when BT unavailable)
      │   (users/{uid}/...)                 │  (same Firestore path)
      │                                     │
```

### 6.3 Pairing Flow

1. Phone generates 6-char pairing code → stores in Firestore `users/{uid}/watchPairing`
2. Patient enters code on watch → watch queries Firestore for matching code
3. On match: watch writes its `watchId` to pairing doc → status = "paired"
4. Phone listens to pairing doc → detects paired status → navigates to patient setup
5. Both devices establish Wearable Data Layer connection for direct comms

### 6.4 Providers

| Provider | Purpose |
|---|---|
| `watchServiceProvider` | Provides `WatchCommunicationService` |
| `watchStatusProvider` | `StreamProvider<WatchStatus>` — real-time watch state |
| `isPairedProvider` | Derived `bool` from watch status |
| `watchBatteryProvider` | Watch battery level stream |

---

## 8. Phase 6 — Geofencing & Location Services

### 7.1 Location Service (`lib/services/location_service.dart`)

```
LocationService
├── requestPermissions() → LocationPermission
├── getCurrentPosition() → Position
├── getPositionStream(interval) → Stream<Position>
├── calculateDistance(lat1, lng1, lat2, lng2) → double
└── isLocationEnabled() → bool
```

### 7.2 Geofence Service (`lib/services/geofence_service.dart`)

```
GeofenceService
├── registerSafeZone(safeZone) → void
├── removeSafeZone(zoneId) → void
├── updateSafeZone(safeZone) → void
├── onGeofenceEvent → Stream<GeofenceEvent>
└── getActiveGeofences() → List<SafeZone>
```

> **Note:** The phone-side geofencing is primarily for monitoring the *watch's reported location*. The actual geofence detection happens on the watch. The phone receives events and displays them.

### 7.3 Phone-Side Location Responsibilities

| Feature | Implementation |
|---|---|
| Display patient location on map | Listen to `activityRecords` stream from Firestore (watch uploads) |
| Memory reminder map view | Show markers from `memoryReminders` collection |
| Safe zone visualization | Draw circle overlay from `safeZone` config |
| Movement history | Query `activityRecords` for date range |

---

## 9. Phase 7 — Full Local Database & Remaining Repositories

> Now that activity data is flowing, build out the remaining tables and repositories.

### 9.1 Additional SQLite Tables

| Table | Maps To | Purpose |
|---|---|---|
| `memory_reminders` | `MemoryReminder` | Geo-triggered memory cues |
| `media_items` | `MediaItem` | Photo/audio/video attachments |
| `safe_zone_events` | `SafeZoneEvent` | Safe zone breach history |

### 9.2 Additional Local Data Sources

```
lib/data/local/
├── memory_reminder_local_source.dart
└── safe_zone_event_local_source.dart
```

### 9.3 Additional Repositories

```
lib/repositories/
├── memory_repository.dart + memory_repository_impl.dart
└── safe_zone_repository.dart + safe_zone_repository_impl.dart
```

### 9.4 Additional Remote Sources

```
lib/data/remote/
├── user_remote_source.dart
└── memory_remote_source.dart
```

### 9.5 Firebase Storage

- Store media files under: `users/{uid}/patients/{patientId}/media/{mediaId}/{filename}`
- Upload on create, download URL stored in Firestore
- Cache locally with `cached_network_image` for photos
- Download videos/audio to local storage for playback

### 9.6 Firestore Full Schema

```
users/{uid}/
├── profile: { name, phone, bio, photoUrl }
├── patients/{patientId}/
│   ├── info: { name, age, notes, photoUrl, pairedWatchId }
│   ├── memoryReminders/{reminderId}: { title, lat, lng, radius, mediaItems[], ... }
│   ├── safeZones/{zoneId}: { centerLat, centerLng, radius, alarm, vibrate, ... }
│   ├── safeZoneEvents/{eventId}: { type, timestamp, lat, lng }
│   ├── activityRecords/{recordId}: { timestamp, lat, lng, eventType, ... }
│   └── dailySummaries/{date}: { steps, distance, activeMinutes, ... }
└── watchPairing: { pairingCode, watchId, status, pairedAt }
```

### 9.7 Sync Strategy

| Direction | Mechanism |
|---|---|
| Phone → Cloud | Write-through on create/update/delete |
| Cloud → Phone | Firestore `snapshots()` stream listeners |
| Watch → Cloud → Phone | Watch writes activity/events to Firestore; phone listens |
| Phone → Cloud → Watch | Phone writes safe zone config; watch listens via Firestore or Wearable Data Layer |

---

## 10. Phase 8 — Memory Cues (Media & Geo-Reminders)

### 8.1 Memory Reminder Service (`lib/services/memory_reminder_service.dart`)

```
MemoryReminderService
├── createReminder(title, location, media[]) → MemoryReminder
├── updateReminder(reminder) → void
├── deleteReminder(id) → void
├── getRemindersForPatient(patientId) → List<MemoryReminder>
├── getRemindersByLocation(lat, lng, radius) → List<MemoryReminder>
└── syncRemindersToWatch(patientId) → void
```

### 8.2 Media Service (`lib/services/media_service.dart`)

```
MediaService
├── pickPhoto(source: camera|gallery) → File
├── pickVideo(source: camera|gallery) → File
├── recordAudio() → File
├── uploadMedia(file, path) → String (cloudUrl)
├── downloadMedia(cloudUrl) → File
├── deleteMedia(cloudUrl) → void
├── generateThumbnail(videoFile) → File
└── getLocalCachePath(mediaId) → String?
```

### 8.3 Create Reminder Flow (3-Step Wizard)

1. **Step 1 — Name:** Validate title → save to state
2. **Step 2 — Location:** User taps map → save lat/lng + radius
3. **Step 3 — Media:** Pick/capture media → upload to Firebase Storage → save URLs
4. **Submit:** Write `MemoryReminder` to local DB + Firestore + sync to watch

### 8.4 Providers

| Provider | Purpose |
|---|---|
| `memoryRemindersProvider(patientId)` | `StreamProvider<List<MemoryReminder>>` |
| `memoryReminderDetailProvider(id)` | Single reminder with media |
| `createReminderProvider` | `StateNotifier` managing wizard state |
| `mediaUploadProvider` | Upload progress tracking |

---

## 11. Phase 9 — Notifications & Alerts

### 11.1 Notification Service (`lib/services/notification_service.dart`)

```
NotificationService
├── initialize() → void
├── showSafeZoneAlert(event) → void
├── showReminderTriggered(reminder) → void
├── showWatchDisconnected() → void
├── showWatchLowBattery(level) → void
├── scheduleDailyReport(time) → void
├── cancelAll() → void
└── onNotificationTapped → Stream<NotificationPayload>
```

### 11.2 Firebase Cloud Messaging

- Register FCM token in Firestore under user profile
- Watch (via Firestore triggers / Cloud Functions; see **11.4** for full design) can send push to phone:
  - Safe zone exit alert
  - Watch disconnected
  - Low battery warning
- Phone-side handles foreground + background notifications

### 11.3 Local Notifications

- Safe zone exit → immediate high-priority notification with sound
- Reminder triggered → notification with reminder title + thumbnail
- Watch disconnected > 10 min → warning notification
- Daily summary available → scheduled notification

### 11.4 Cloud Functions — Detailed Implementation

> This subsection defines the server-side automation layer for alerts, aggregation, and reliability. It expands the Phase 9 mention of “Firestore triggers / Cloud Functions” into an executable implementation plan.

#### A) Runtime & Project Setup

Create a dedicated Firebase Functions workspace at the repo root:

```
functions/
├── package.json
├── tsconfig.json
├── .eslintrc.cjs
├── src/
│   ├── index.ts
│   ├── config.ts
│   ├── types.ts
│   ├── utils/
│   │   ├── idempotency.ts
│   │   ├── geo.ts
│   │   ├── notifications.ts
│   │   └── dates.ts
│   ├── triggers/
│   │   ├── activity_triggers.ts
│   │   ├── safe_zone_triggers.ts
│   │   ├── watch_status_triggers.ts
│   │   ├── reminder_triggers.ts
│   │   └── summary_triggers.ts
│   └── callable/
│       ├── admin_repair.ts
│       └── manual_summary_rebuild.ts
└── firestore.indexes.json
```

Recommended stack:
- `firebase-functions` v2 (2nd gen)
- `firebase-admin`
- TypeScript + ESLint + Prettier

API key strategy (project decision):
- Use the existing Google Maps Platform API keys already provisioned for this project.
- Cloud Functions geocoding/place-resolution calls use server-side Firebase Secrets (`MAPS_API_KEY`, or split `GEOCODING_API_KEY` + `PLACES_API_KEY` if needed).
- Mobile app keys remain client-restricted for map rendering only; geocoding/place-resolution keys are not embedded in Flutter app code.
- Do not commit key values to source control or docs; store/manage only in Firebase Secrets and cloud console.

`package.json` scripts:
- `build`: `tsc -p tsconfig.json`
- `lint`: `eslint --ext .ts src`
- `serve`: `firebase emulators:start --only functions,firestore,pubsub`
- `deploy`: `firebase deploy --only functions`

#### B) Data Contracts Used by Functions

All functions operate on this path convention:
- `users/{uid}/patients/{patientId}/activityRecords/{recordId}`
- `users/{uid}/patients/{patientId}/dailySummaries/{yyyy-MM-dd}`
- `users/{uid}/patients/{patientId}/safeZones/{zoneId}`
- `users/{uid}/patients/{patientId}/safeZoneEvents/{eventId}`
- `users/{uid}/patients/{patientId}/watchStatus/current`
- `users/{uid}/devices/{deviceId}` (contains FCM token + platform)

Activity event types expected in `activityRecords`:
- `location_update`
- `safe_zone_enter`
- `safe_zone_exit`
- `reminder_triggered`
- `watch_disconnected`
- `watch_reconnected`

#### C) Trigger Functions (Core)

1) `onActivityRecordCreated`
- **Trigger:** `onDocumentCreated(activityRecords/{recordId})`
- **Purpose:** Validate event payload, enrich metadata, and fan out downstream writes.
- **Steps:**
  - Validate required fields (`timestamp`, `eventType`, `patientId`).
  - Reject or quarantine malformed events into `invalidEvents/{id}`.
  - Upsert `latestLocation/current` when event includes coordinates.
  - Write lightweight analytics counters (`hourlyBuckets/{hour}` increment).
  - Mark processed event in idempotency store (`functionLocks/{eventId}`).

2) `onActivityRecordForSummary`
- **Trigger:** `onDocumentCreated(activityRecords/{recordId})`
- **Purpose:** Incrementally maintain `dailySummaries/{date}` for Activity Screen cards.
- **Aggregation updates:**
  - `totalEvents += 1`
  - `safeZoneExits += 1` for `safe_zone_exit`
  - `remindersTriggered += 1` for `reminder_triggered`
  - `distanceMeters += segmentDistance` for sequential location points
  - `activeMinutes` computed from movement/time windows
  - `placesVisited` based on clustered distinct location cells (geohash prefix)
- **Implementation detail:** Use Firestore transaction to avoid race conditions.

3) `onSafeZoneEventCreated`
- **Trigger:** `onDocumentCreated(safeZoneEvents/{eventId})`
- **Purpose:** Send immediate high-priority caregiver push alert.
- **Behavior:**
  - Build localized message by `eventType` (enter/exit).
  - Include payload for deep link (`screen: activity`, `patientId`, `eventId`).
  - Enforce cooldown window (for example 5 min) to prevent alert storms.

4) `onWatchStatusChanged`
- **Trigger:** `onDocumentWritten(watchStatus/current)`
- **Purpose:** Notify on disconnect and low battery transitions.
- **Behavior:**
  - Send disconnect warning after sustained disconnected duration (for example 10 min).
  - Send low battery warning once per threshold bucket (20%, 10%, 5%).
  - Clear “pending disconnect alert” marker when reconnected.

5) `onReminderTriggeredEvent`
- **Trigger:** `onDocumentCreated(activityRecords/{recordId})` filtered by `eventType=reminder_triggered`
- **Purpose:** Push reminder context notification with optional media thumbnail URL.

6) `dailySummaryRollupScheduler`
- **Trigger:** `onSchedule("every 15 minutes")`
- **Purpose:** Reconcile any missed increments and ensure summary correctness.
- **Behavior:**
  - Scan recent records per patient for current day.
  - Recompute summary fields and compare against stored values.
  - Correct drift if mismatch exceeds tolerance.

7) `dailyReportNotificationScheduler`
- **Trigger:** `onSchedule("every day 20:00")` (timezone-aware)
- **Purpose:** Send daily report push from finalized summary values.

#### D) Idempotency, Ordering, and Retry Strategy

- Store processed event IDs at:
  - `users/{uid}/patients/{patientId}/functionLocks/{eventId}`
- For each trigger:
  - Exit early if lock exists.
  - Perform side effects in transaction/batch.
  - Create lock as the final operation in the same write batch where possible.
- Use deterministic notification IDs (`patientId + date + alertType`) to collapse duplicates.
- Use exponential backoff for FCM send retries; dead-letter unrecoverable payloads into `notificationFailures/{id}`.

#### E) Security & Access Model

- Firestore Rules:
  - Caregiver can read/write only own `users/{uid}` subtree.
  - Watch writes only scoped docs through authenticated custom token or App Check enforced channel.
  - Deny direct client writes to server-managed docs:
    - `dailySummaries/*`
    - `latestLocation/*`
    - `functionLocks/*`
- Functions run with admin privileges and become the only writer to server-managed aggregates.

#### F) Observability & Operations

- Structured logs with fields: `uid`, `patientId`, `eventId`, `functionName`, `status`.
- Error reporting to Cloud Logging + Error Reporting.
- Custom metrics (Cloud Monitoring):
  - `activity_events_processed_count`
  - `summary_rebuild_count`
  - `notification_send_success_rate`
  - `notification_cooldown_suppressed_count`
- Alert policies:
  - High error rate in any trigger for 5+ minutes
  - Scheduler failure for 2 consecutive runs

#### G) Local Emulator + Test Plan

Minimum automated tests for functions:
- Unit tests:
  - Summary math (distance, active minutes, places)
  - Cooldown logic for notifications
  - Idempotency lock behavior
- Integration tests (emulator):
  - Insert `activityRecord` → verify `dailySummary` update
  - Insert `safeZoneEvent` → verify push send call
  - Simulate duplicate event write → verify no duplicate side effects

Recommended CI steps:
1. `npm ci`
2. `npm run lint`
3. `npm run build`
4. `firebase emulators:exec --only functions,firestore "npm test"`

#### H) Deployment & Rollout

- Environments:
  - `relapse-dev`
  - `relapse-staging`
  - `relapse-prod`
- Rollout sequence:
  1. Deploy read-only/logging triggers first.
  2. Enable summary write triggers for a pilot patient cohort.
  3. Enable notifications with conservative cooldowns.
  4. Promote to full production after 7 days stable metrics.
- Backfill command (callable/admin-only):
  - `manualSummaryRebuild(uid, patientId, fromDate, toDate)`

#### I) Activity Screen Impact (Direct)

This Cloud Functions layer guarantees Activity Screen data quality by:
- Keeping `dailySummaries/{date}` continuously updated for summary cards.
- Maintaining stable event ingestion with dedupe/idempotency.
- Emitting reliable safe-zone and reminder alerts for feed consistency.
- Repairing drift with scheduled rollups so chart and counts remain accurate.

---

## 12. Phase 10 — Offline Support & Maps

### 12.1 Offline-First Strategy

| Data | Offline Behavior |
|---|---|
| Patient profile | Cached in SQLite, always available |
| Memory reminders | Cached locally, queue writes for sync |
| Safe zone config | Cached locally |
| Activity history | Cached locally, new data queued |
| Media files | Downloaded and cached in app directory |
| Map tiles | Google Maps offline areas (user-managed) |

### 12.2 Connectivity Service (`lib/services/connectivity_service.dart`)

```
ConnectivityService
├── isOnline → bool
├── onConnectivityChanged → Stream<bool>
└── syncPendingChanges() → void   // called when back online
```

### 12.3 Sync Queue

- When offline: writes go to local DB + `pending_sync` table
- When online: `SyncService` drains the queue in order
- Conflict resolution: last-write-wins with timestamps

### 12.4 Offline Maps Screen

- Guide user to download Google Maps offline region
- Store recommended region based on safe zone center + radius
- No custom tile server needed — leverage Google Maps' built-in offline

---

## 13. Phase 11 — Settings & Preferences

### 13.1 Settings/Preferences

| Setting | Storage | Default |
|---|---|---|
| Reminder cooldown (minutes) | SharedPreferences + Firestore | 30 min |
| Notification sound enabled | SharedPreferences | true |
| Daily report time | SharedPreferences | 8:00 PM |
| Theme preference | SharedPreferences | System |

### 13.2 Unpair Device Flow

1. Confirm dialog
2. Clear local pairing data
3. Update Firestore pairing doc → status = "unpaired"
4. Send unpair message to watch via Wearable Data Layer
5. Clear watch-side data
6. Navigate to Add Patient screen

---

## 14. Phase 12 — Testing & Hardening

### 14.1 Unit Tests

| Target | Tests |
|---|---|
| Models | Serialization/deserialization, equality |
| Repositories | CRUD operations with mocked data sources |
| Services | Business logic with mocked dependencies |
| Providers | State transitions, async flows |

### 14.2 Integration Tests

| Flow | Scope |
|---|---|
| Auth flow | Sign up → login → logout → password reset |
| Patient flow | Add patient → pair → setup → edit → unpair |
| Memory flow | Create reminder → view list → view detail → delete |
| Safe zone flow | Configure → activate → receive event → view log |

### 14.3 Error Handling

- Wrap all async operations in try/catch
- Display user-friendly error messages via Snackbar/Dialog
- Log errors to Firebase Crashlytics (add dependency)
- Retry logic for network operations
- Graceful degradation when watch disconnected

---

## 15. Dependency Summary

| Category | Package | Purpose |
|---|---|---|
| **State** | `flutter_riverpod` | Providers, state management |
| **Firebase** | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging` | Auth, database, file storage, push notifications |
| **Local DB** | `sqflite`, `path` | Offline-first SQLite storage |
| **Serialization** | `freezed`, `json_serializable`, `json_annotation` | Immutable models, JSON mapping |
| **Location** | `geolocator` | GPS position, distance |
| **Maps** | `google_maps_flutter` | Map display (already present) |
| **Watch** | `flutter_wear_os_connectivity` | Wearable Data Layer communication |
| **Media** | `image_picker`, `video_player`, `audioplayers`, `file_picker` | Capture/playback |
| **Notifications** | `flutter_local_notifications`, `firebase_messaging` | Local + push alerts |
| **Connectivity** | `connectivity_plus` | Online/offline detection |
| **Preferences** | `shared_preferences` | Local key-value settings |
| **Caching** | `cached_network_image`, `path_provider` | Image caching, file paths |
| **Utilities** | `uuid`, `intl` | IDs, date formatting |

---

## 16. Directory Structure

```
lib/
├── main.dart                              — Firebase init, ProviderScope, routing
├── models/
│   ├── app_user.dart                      — Freezed
│   ├── caregiver_profile.dart
│   ├── patient.dart
│   ├── memory_reminder.dart
│   ├── media_item.dart
│   ├── safe_zone.dart
│   ├── safe_zone_event.dart
│   ├── activity_record.dart
│   ├── daily_summary.dart
│   ├── watch_status.dart
│   └── pairing_info.dart
├── data/
│   ├── local/
│   │   ├── app_database.dart              — SQLite setup, migrations
│   │   ├── patient_local_source.dart
│   │   ├── memory_reminder_local_source.dart
│   │   ├── safe_zone_local_source.dart
│   │   ├── activity_local_source.dart
│   │   └── daily_summary_local_source.dart
│   └── remote/
│       ├── user_remote_source.dart
│       ├── patient_remote_source.dart
│       ├── memory_remote_source.dart
│       ├── safe_zone_remote_source.dart
│       └── activity_remote_source.dart
├── repositories/
│   ├── auth_repository.dart
│   ├── auth_repository_impl.dart
│   ├── patient_repository.dart
│   ├── patient_repository_impl.dart
│   ├── memory_repository.dart
│   ├── memory_repository_impl.dart
│   ├── safe_zone_repository.dart
│   ├── safe_zone_repository_impl.dart
│   ├── activity_repository.dart
│   └── activity_repository_impl.dart
├── services/
│   ├── auth_service.dart
│   ├── location_service.dart
│   ├── geofence_service.dart
│   ├── watch_communication_service.dart
│   ├── media_service.dart
│   ├── memory_reminder_service.dart
│   ├── activity_service.dart
│   ├── notification_service.dart
│   ├── connectivity_service.dart
│   └── sync_service.dart
├── providers/
│   ├── auth_providers.dart                — Auth state, sign-in/up notifiers
│   ├── auth_ui_providers.dart             — (existing) form UI state
│   ├── patient_providers.dart             — Patient CRUD, pairing
│   ├── patient_profile_ui_providers.dart  — (existing) form UI state
│   ├── memory_providers.dart              — Reminders list, detail, create wizard
│   ├── safe_zone_providers.dart           — Safe zone config, events
│   ├── activity_providers.dart            — Feed, summaries, live location
│   ├── watch_providers.dart               — Watch status, pairing, comms
│   ├── notification_providers.dart        — Notification state
│   ├── connectivity_providers.dart        — Online/offline state
│   └── settings_providers.dart            — App preferences
├── screens/                               — (existing, will be updated)
├── widgets/                               — (existing, will be updated)
└── theme/                                 — (existing, no changes needed)
```

---

## Implementation Priority Order

> Activity Screen is the **first fully functional feature**. Phases 1–4 form the critical path to get it working end-to-end.

| Priority | Phase | Effort | Blocking | Activity Screen? |
|---|---|---|---|---|
| 🔴 P0 | Phase 1 — Foundation (models, deps) | 3-4 days | Everything | ✅ Required |
| 🔴 P0 | Phase 2 — Authentication | 2-3 days | All data features | ✅ Required |
| 🔴 P0 | Phase 3 — Activity Data Layer (DB + Firestore) | 3-4 days | Activity Screen | ✅ **Core** |
| 🔴 P0 | Phase 4 — Activity Providers & Screen Wiring | 2-3 days | Activity Screen | ✅ **Core** |
| 🟠 P1 | Phase 5 — Watch Communication | 4-5 days | Watch features | Enhances live data |
| 🟠 P1 | Phase 6 — Geofencing & Location | 3-4 days | Safe zones | Enhances safe zone pill |
| 🟠 P1 | Phase 7 — Full DB + Remaining Repos | 3-4 days | Other features | — |
| 🟡 P2 | Phase 8 — Memory Cues | 3-4 days | Core feature | — |
| 🟡 P2 | Phase 9 — Notifications | 2-3 days | Alerts | — |
| 🟢 P3 | Phase 10 — Offline Support | 2-3 days | Resilience | Offline activity cache |
| 🟢 P3 | Phase 11 — Settings & Preferences | 1-2 days | Secondary features | — |
| 🟢 P3 | Phase 12 — Testing | 5-7 days | Quality | Activity tests first |

**🎯 Activity Screen functional after Phase 4 (~11-14 days)**

**Estimated total: ~37-47 days of development effort**
