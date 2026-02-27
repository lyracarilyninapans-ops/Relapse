import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { ActivityRecord } from "../types";
import { isProcessed, markProcessed } from "../utils/idempotency";
import { sendPushToUser } from "../utils/notifications";

/**
 * Trigger 5: onReminderTriggeredEvent
 * Sends push notification when a memory reminder is triggered.
 * Filters activityRecords by eventType === "reminder_triggered".
 */
export const onReminderTriggeredEvent = onDocumentCreated(
  {
    document: "users/{uid}/patients/{patientId}/activityRecords/{recordId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, patientId, recordId } = event.params;
    const data = snap.data() as ActivityRecord;

    // Only process reminder_triggered events
    if (data.eventType !== "reminder_triggered") return;

    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `reminder_push_${recordId}`;
    if (await isProcessed(lockPath, lockId)) return;

    // Try to resolve the reminder title
    const reminderId = (data.metadata?.reminderId as string) || "";
    let reminderTitle = "Memory Reminder";

    if (reminderId) {
      try {
        const reminderDoc = await admin.firestore()
          .doc(`${paths.memoryReminders(uid, patientId)}/${reminderId}`)
          .get();
        if (reminderDoc.exists) {
          reminderTitle = reminderDoc.data()?.title || reminderTitle;
        }
      } catch (err) {
        logger.warn("Failed to resolve reminder", { err, reminderId });
      }
    }

    const sent = await sendPushToUser(uid,
      "Memory Reminder",
      reminderTitle,
      {
        type: "reminder_triggered",
        patientId,
        reminderId,
        screen: "memory_details",
        channelId: "memory_reminders",
      },
    );

    await markProcessed(lockPath, lockId);
    logger.info("Reminder push sent", { uid, patientId, recordId, reminderId, sent });
  },
);
