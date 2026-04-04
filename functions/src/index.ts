import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

// Initialize Firebase Admin SDK
admin.initializeApp();

const mapsServerApiKey = defineSecret("MAPS_SERVER_API_KEY");

export const mapsSecretCheck = onRequest(
	{ region: "asia-southeast1", secrets: [mapsServerApiKey] },
	(req, res) => {
		const key = mapsServerApiKey.value();
		logger.info("maps secret check", { hasKey: Boolean(key) });
		res.status(200).json({ hasMapsServerApiKey: Boolean(key) });
	},
);

// Re-export all trigger functions
export {
	onActivityRecordCreated,
	onActivityRecordForSummary,
} from "./triggers/activity_triggers";
export {
	onLocationUpdateToSafeZoneEvaluation,
} from "./triggers/safe_zone_triggers";
export { onWatchStatusChanged } from "./triggers/watch_status_triggers";
export { onReminderTriggeredEvent } from "./triggers/reminder_triggers";
export { dailySummaryRollupScheduler, dailyReportNotificationScheduler } from "./triggers/summary_triggers";

// Re-export callable functions
export { manualSummaryRebuild } from "./callable/manual_summary_rebuild";
