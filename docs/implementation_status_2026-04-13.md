# Implementation Status - 2026-04-13

Source plan: `../detailed_implementation_plan.md`

## Overall status

- Phase 0: mostly complete (baseline evidence capture still pending)
- Phase 1: complete
- Phase 2: implementation complete, evidence capture pending
- Phase 3: complete
- Phase 4: in progress (major decomposition done, broader modernization still open)

## Phase-by-phase checklist

## Phase 0 - Baseline and Safety Nets

- [x] Enable `unawaited_futures` lint.
  - Evidence: `analysis_options.yaml`
- [ ] Baseline metrics recorded (Firestore reads, 30-minute memory, rebuild counts).
  - Gap: no committed baseline report artifact yet.
- [ ] PR template/checklist updates captured in repository.
  - Gap: not found in current workspace changes.

## Phase 1 - P0 Stabilization

### 1A Notification lifecycle
- [x] Track and cancel notification stream subscriptions.
- [x] Ensure single token refresh listener registration.
- [x] Add init idempotency guard.
  - Evidence: `lib/services/notification_service.dart`

### 1B Audio lifecycle
- [x] Store/cancel audio subscriptions.
- [x] Move audio setup out of `build` path.
- [x] Reinitialize only when source URL changes.
  - Evidence: `lib/screens/memory/memory_details_screen.dart`

### 1C Firestore query cost + safe-zone dedup
- [x] Optimize latest-location query with `where(eventType)` + `orderBy(timestamp)` + `limit(1)`.
- [x] Keep runtime fallback query path.
- [x] Commit Firestore composite index config and wire deployment path.
- [x] Deduplicate safe-zone listener path via provider aliasing.
  - Evidence: `lib/data/remote/activity_remote_source.dart`, `lib/providers/settings_providers.dart`, `lib/providers/patient_providers.dart`, `lib/providers/activity_providers.dart`, `firestore.indexes.json`, `firebase.json`, `docs/firestore-index-deployment.md`

### 1D Connectivity initialization
- [x] Ensure initialize runs exactly once.
- [x] Keep provider lifecycle disposal.
  - Evidence: `lib/services/connectivity_service.dart`, `lib/providers/connectivity_providers.dart`, `lib/main.dart`

## Phase 2 - Performance and Rebuild Reduction

### 2A Render dependency cleanup
- [x] Replace broad `MediaQuery.of(context).size` with `MediaQuery.sizeOf` in touched screens.
- [x] Add targeted `RepaintBoundary` on expensive sections.
  - Evidence: `lib/screens/home/home_screen.dart`, `lib/screens/activity/activity_screen.dart`, `lib/screens/activity/widgets/activity_current_location_card.dart`, `lib/screens/activity/widgets/activity_summary_widgets.dart`

### 2B Map object memoization
- [x] Memoize map overlays and recompute only on data signature changes.
  - Evidence: `lib/screens/memory/memory_screen.dart`, `lib/screens/activity/widgets/activity_current_location_card.dart`

### 2C Tab mount strategy
- [x] Lazy first-mount heavy tabs while preserving tab state after first load.
  - Evidence: `lib/screens/navigation/main_screen.dart`

### 2D Patient overview split
- [x] Split static and high-frequency sections to reduce rebuild blast radius.
  - Evidence: `lib/screens/home/home_screen.dart`

- [ ] Phase 2 measurement evidence populated with real before/after metrics.
  - Evidence template exists: `docs/phase2-performance-evidence.md`
  - Gap: metric rows are still empty.

## Phase 3 - State, Async, and Resource Hardening

### 3A selectedPatient redesign
- [x] Replace fragile self-initializing selection with notifier model.
- [x] Preserve explicit user selection and fallback only when needed.
  - Evidence: `lib/providers/patient_providers.dart`
  - Tests: `test/providers/patient_selection_provider_test.dart`

### 3B Splash listener cleanup
- [x] Store and close manual listener subscription.
- [x] Prevent duplicate navigation races.
  - Evidence: `lib/screens/auth/splash_screen.dart`

### 3C Geocoding memory/network fixes
- [x] Bounded LRU cache (500 entries).
- [x] Shared `HttpClient` reuse.
- [x] Typed JSON parsing helpers.
  - Evidence: `lib/utils/geocoding_utils.dart`

### 3D Upload progress cleanup
- [x] Track progress subscription and cancel on lifecycle end.
  - Evidence: `lib/services/media_upload_service.dart`

## Phase 4 - Modernization and Maintainability

- [x] Large Activity screen decomposition started and largely completed.
  - Evidence: `lib/screens/activity/activity_screen.dart`, `lib/screens/activity/widgets/activity_map_widgets.dart`, `lib/screens/activity/widgets/activity_summary_widgets.dart`, `lib/screens/activity/widgets/activity_feed_widgets.dart`, `lib/screens/activity/widgets/activity_current_location_card.dart`
- [ ] Broader `const` modernization pass in touched files.
- [ ] Logging standardization for expected error paths.
- [ ] Equality strategy rollout across high-churn models.
- [ ] Riverpod Notifier/AsyncNotifier modernization batches.

## Validation snapshot

- `flutter analyze`: clean in latest iteration.
- `flutter test test/providers test/services/settings_service_test.dart`: passing.
- Added tests:
  - `test/providers/patient_selection_provider_test.dart`
  - `test/providers/latest_location_flag_provider_test.dart`
  - updates in `test/services/settings_service_test.dart`

## Final gaps to close program-level Done

1. Commit actual Phase 0 baseline evidence artifact (metrics + device profile + timestamp).
2. Populate `docs/phase2-performance-evidence.md` with measured before/after values and attachments.
3. Decide whether Phase 4 modernization items are in-scope now or explicitly defer with owner and due date.