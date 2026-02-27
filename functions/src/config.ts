/** Shared configuration constants for Cloud Functions. */

export const REGION = "asia-southeast1";

/** Cooldown window (ms) to prevent alert storms for safe zone events. */
export const SAFE_ZONE_COOLDOWN_MS = 5 * 60 * 1000; // 5 minutes

/** Duration (ms) of sustained disconnect before sending warning. */
export const WATCH_DISCONNECT_THRESHOLD_MS = 10 * 60 * 1000; // 10 minutes

/** Battery level thresholds that trigger warnings (descending). */
export const BATTERY_THRESHOLDS = [20, 10, 5];

/** Firestore path helpers. */
export const paths = {
  activityRecords: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/activityRecords`,
  dailySummaries: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/dailySummaries`,
  safeZoneEvents: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/safeZoneEvents`,
  watchStatus: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/watchStatus/current`,
  functionLocks: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/functionLocks`,
  devices: (uid: string) =>
    `users/${uid}/devices`,
  safeZones: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/safeZones`,
  memoryReminders: (uid: string, patientId: string) =>
    `users/${uid}/patients/${patientId}/memoryReminders`,
};
