import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { toDateString } from "../utils/dates";
import { sendPushToUser } from "../utils/notifications";

/**
 * Trigger 6: dailySummaryRollupScheduler
 * Reconciles any missed increments and ensures summary correctness.
 * Runs every 15 minutes.
 */
export const dailySummaryRollupScheduler = onSchedule(
  {
    schedule: "every 15 minutes",
    region: REGION,
    timeoutSeconds: 120,
  },
  async () => {
    const today = toDateString(new Date());
    logger.info("Daily summary rollup started", { date: today });

    // Iterate over all users with patients
    const usersSnap = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const uid = userDoc.id;
      const patientsSnap = await admin.firestore()
        .collection(`users/${uid}/patients`)
        .get();

      for (const patientDoc of patientsSnap.docs) {
        const patientId = patientDoc.id;

        try {
          // Count today's records
          const recordsSnap = await admin.firestore()
            .collection(paths.activityRecords(uid, patientId))
            .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(
              new Date(`${today}T00:00:00`),
            ))
            .where("timestamp", "<", admin.firestore.Timestamp.fromDate(
              new Date(new Date(`${today}T00:00:00`).getTime() + 86400000),
            ))
            .get();

          if (recordsSnap.empty) continue;

          const summaryRef = admin.firestore()
            .doc(`${paths.dailySummaries(uid, patientId)}/${today}`);
          const summarySnap = await summaryRef.get();
          const summaryData = summarySnap.data();

          const actualTotal = recordsSnap.size;
          const storedTotal = summaryData?.totalEvents || 0;

          // Only reconcile if there's drift
          if (Math.abs(actualTotal - storedTotal) > 1) {
            logger.warn("Summary drift detected, reconciling", {
              uid, patientId, actualTotal, storedTotal,
            });
            await summaryRef.set({
              totalEvents: actualTotal,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              reconciledAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
          }
        } catch (err) {
          logger.error("Rollup failed for patient", { uid, patientId, err });
        }
      }
    }

    logger.info("Daily summary rollup completed");
  },
);

/**
 * Trigger 7: dailyReportNotificationScheduler
 * Sends daily report push from finalized summary values.
 * Runs every day at 20:00 UTC.
 */
export const dailyReportNotificationScheduler = onSchedule(
  {
    schedule: "every day 20:00",
    region: REGION,
    timeoutSeconds: 120,
  },
  async () => {
    const today = toDateString(new Date());
    logger.info("Daily report notification started", { date: today });

    const usersSnap = await admin.firestore().collection("users").get();

    for (const userDoc of usersSnap.docs) {
      const uid = userDoc.id;
      const patientsSnap = await admin.firestore()
        .collection(`users/${uid}/patients`)
        .get();

      for (const patientDoc of patientsSnap.docs) {
        const patientId = patientDoc.id;
        const patientName = patientDoc.data()?.name || "your patient";

        try {
          const summaryRef = admin.firestore()
            .doc(`${paths.dailySummaries(uid, patientId)}/${today}`);
          const summarySnap = await summaryRef.get();

          if (!summarySnap.exists) continue;

          const summary = summarySnap.data()!;
          const body = `${patientName}: ${summary.totalEvents || 0} events, ` +
            `${summary.safeZoneExits || 0} zone exits, ` +
            `${Math.round(summary.distanceMeters || 0)}m traveled today.`;

          await sendPushToUser(uid,
            "Daily Activity Report",
            body,
            {
              type: "daily_report",
              patientId,
              screen: "activity",
              channelId: "daily_report",
            },
          );
        } catch (err) {
          logger.error("Daily report push failed", { uid, patientId, err });
        }
      }
    }

    logger.info("Daily report notifications completed");
  },
);
