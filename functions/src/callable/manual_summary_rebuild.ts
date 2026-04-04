import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { ActivityRecord } from "../types";
import { toDateString } from "../utils/dates";
import { calculateActiveMinutes, inferInitiallyOutside } from "../utils/summary_metrics";

/**
 * Callable: manualSummaryRebuild
 * Allows a caregiver to manually trigger a full summary rebuild for a patient/date.
 */
export const manualSummaryRebuild = onCall(
  { region: REGION },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const uid = request.auth.uid;
    const { patientId, date } = request.data as { patientId?: string; date?: string };

    if (!patientId) {
      throw new HttpsError("invalid-argument", "patientId is required");
    }

    const targetDate = date || toDateString(new Date());
    logger.info("Manual summary rebuild requested", { uid, patientId, targetDate });

    // Fetch all records for the day
    const startOfDay = new Date(`${targetDate}T00:00:00`);
    const endOfDay = new Date(startOfDay.getTime() + 86400000);

    const recordsSnap = await admin.firestore()
      .collection(paths.activityRecords(uid, patientId))
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(startOfDay))
      .where("timestamp", "<", admin.firestore.Timestamp.fromDate(endOfDay))
      .orderBy("timestamp")
      .get();

    const boundarySnap = await admin.firestore()
      .collection(paths.activityRecords(uid, patientId))
      .where("timestamp", "<", admin.firestore.Timestamp.fromDate(startOfDay))
      .orderBy("timestamp", "desc")
      .limit(20)
      .get();

    const initiallyOutside = inferInitiallyOutside(
      boundarySnap.docs.map((doc) => doc.data() as ActivityRecord),
    );
    const activeMinutes = calculateActiveMinutes(
      recordsSnap.docs.map((doc) => doc.data() as ActivityRecord),
      {
        dayStart: startOfDay,
        dayEnd: endOfDay,
        openIntervalEnd: endOfDay,
        initiallyOutside,
      },
    );

    let totalEvents = 0;
    let safeZoneExits = 0;
    let remindersTriggered = 0;

    for (const doc of recordsSnap.docs) {
      const data = doc.data();
      totalEvents++;
      if (data.eventType === "safe_zone_exit") safeZoneExits++;
      if (data.eventType === "reminder_triggered") remindersTriggered++;
    }

    const summaryRef = admin.firestore()
      .doc(`${paths.dailySummaries(uid, patientId)}/${targetDate}`);

    await summaryRef.set({
      date: targetDate,
      totalEvents,
      safeZoneExits,
      remindersTriggered,
      activeMinutes,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      rebuiltAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    logger.info("Summary rebuilt", { uid, patientId, targetDate, totalEvents });

    return { success: true, totalEvents, safeZoneExits, remindersTriggered, activeMinutes };
  },
);
