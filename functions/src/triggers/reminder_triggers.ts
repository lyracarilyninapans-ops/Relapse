import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { ActivityRecord } from "../types";
import { claimLock } from "../utils/idempotency";
import { sendPushToUser } from "../utils/notifications";

export function extractReminderIdFromMetadata(metadata: unknown): string {
  if (!metadata) return "";

  if (typeof metadata === "object") {
    const value = (metadata as Record<string, unknown>).reminderId;
    return typeof value === "string" ? value : "";
  }

  if (typeof metadata === "string") {
    try {
      const parsed = JSON.parse(metadata) as Record<string, unknown>;
      const value = parsed.reminderId;
      return typeof value === "string" ? value : "";
    } catch {
      return "";
    }
  }

  return "";
}

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

    // Atomic idempotency lock — claim FIRST before sending push
    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `reminder_push_${recordId}`;
    if (!(await claimLock(lockPath, lockId))) return;

    // Try to resolve the reminder title
    const reminderId = extractReminderIdFromMetadata(data.metadata);
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

    // Resolve patient name for a more descriptive caregiver push body.
    let patientName = "Patient";
    try {
      const patientDoc = await admin.firestore().doc(paths.patient(uid, patientId)).get();
      const resolvedName = patientDoc.data()?.name;
      if (typeof resolvedName === "string" && resolvedName.trim().length > 0) {
        patientName = resolvedName.trim();
      }
    } catch (err) {
      logger.warn("Failed to resolve patient for reminder push", { err, uid, patientId });
    }

    const body = reminderTitle === "Memory Reminder"
      ? `${patientName} has triggered a memory reminder.`
      : `${patientName}: ${reminderTitle}`;

    const sent = await sendPushToUser(uid,
      "Memory Reminder",
      body,
      {
        type: "reminder_triggered",
        patientId,
        reminderId,
        screen: "memory_details",
        channelId: "memory_reminders",
      },
    );

    logger.info("Reminder push sent", { uid, patientId, recordId, reminderId, sent });
  },
);
