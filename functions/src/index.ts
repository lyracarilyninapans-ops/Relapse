import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Re-export all trigger functions
export { onActivityRecordCreated, onActivityRecordForSummary } from "./triggers/activity_triggers";
export { onSafeZoneEventCreated } from "./triggers/safe_zone_triggers";
export { onWatchStatusChanged } from "./triggers/watch_status_triggers";
export { onReminderTriggeredEvent } from "./triggers/reminder_triggers";
export { dailySummaryRollupScheduler, dailyReportNotificationScheduler } from "./triggers/summary_triggers";

// Re-export callable functions
export { manualSummaryRebuild } from "./callable/manual_summary_rebuild";
