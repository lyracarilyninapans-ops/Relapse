import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { ActivityRecord } from "../types";
import { toDateString, utcDayStart, utcDayEnd } from "../utils/dates";
import { sendPushToUser } from "../utils/notifications";
import { calculateActiveMinutes, inferInitiallyOutside } from "../utils/summary_metrics";

/** Batch size for paginating user and patient collections. */
const BATCH_SIZE = 100;

/**
 * Helper: iterate a Firestore collection in batches to avoid loading
 * all documents into memory at once. Yields document snapshots.
 */
async function* paginateCollection(
  collectionRef: admin.firestore.CollectionReference,
  batchSize: number,
): AsyncGenerator<admin.firestore.QueryDocumentSnapshot> {
  let lastDoc: admin.firestore.DocumentSnapshot | null = null;

  while (true) {
    let query = collectionRef.orderBy("__name__").limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      yield doc;
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < batchSize) break;
  }
}

/**
 * Trigger 6: dailySummaryRollupScheduler
 * Reconciles any missed increments and ensures summary correctness.
 * Runs every 15 minutes. Paginates users and patients to avoid timeouts.
 */
export const dailySummaryRollupScheduler = onSchedule(
  {
    schedule: "every 15 minutes",
    region: REGION,
    timeoutSeconds: 300,
  },
  async () => {
    const today = toDateString(new Date());
    const dayStart = utcDayStart(today);
    const dayEnd = utcDayEnd(today);
    logger.info("Daily summary rollup started", { date: today });

    for await (const userDoc of paginateCollection(
      admin.firestore().collection("users"),
      BATCH_SIZE,
    )) {
      const uid = userDoc.id;

      for await (const patientDoc of paginateCollection(
        admin.firestore().collection(`users/${uid}/patients`),
        BATCH_SIZE,
      )) {
        const patientId = patientDoc.id;

        try {
          const recordsSnap = await admin.firestore()
            .collection(paths.activityRecords(uid, patientId))
            .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(dayStart))
            .where("timestamp", "<", admin.firestore.Timestamp.fromDate(dayEnd))
            .orderBy("timestamp")
            .get();

          if (recordsSnap.empty) continue;

          const summaryRef = admin.firestore()
            .doc(`${paths.dailySummaries(uid, patientId)}/${today}`);
          const summarySnap = await summaryRef.get();
          const summaryData = summarySnap.data();

          const actualTotal = recordsSnap.size;
          const storedTotal = summaryData?.totalEvents || 0;

          const boundarySnap = await admin.firestore()
            .collection(paths.activityRecords(uid, patientId))
            .where("timestamp", "<", admin.firestore.Timestamp.fromDate(dayStart))
            .orderBy("timestamp", "desc")
            .limit(20)
            .get();

          const initiallyOutside = inferInitiallyOutside(
            boundarySnap.docs.map((doc) => doc.data() as ActivityRecord),
          );

          const activeMinutes = calculateActiveMinutes(
            recordsSnap.docs.map((doc) => doc.data() as ActivityRecord),
            {
              dayStart,
              dayEnd,
              openIntervalEnd: new Date(),
              initiallyOutside,
            },
          );
          const storedActiveMinutes = summaryData?.activeMinutes || 0;

          // Only reconcile if there's drift
          if (Math.abs(actualTotal - storedTotal) > 1 || storedActiveMinutes !== activeMinutes) {
            logger.warn("Summary drift detected, reconciling", {
              uid,
              patientId,
              actualTotal,
              storedTotal,
              activeMinutes,
              storedActiveMinutes,
            });
            await summaryRef.set({
              totalEvents: actualTotal,
              activeMinutes,
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
 * Runs every day at 20:00 UTC. Paginates users and patients.
 */
export const dailyReportNotificationScheduler = onSchedule(
  {
    schedule: "every day 20:00",
    region: REGION,
    timeoutSeconds: 300,
  },
  async () => {
    const today = toDateString(new Date());
    logger.info("Daily report notification started", { date: today });

    for await (const userDoc of paginateCollection(
      admin.firestore().collection("users"),
      BATCH_SIZE,
    )) {
      const uid = userDoc.id;

      for await (const patientDoc of paginateCollection(
        admin.firestore().collection(`users/${uid}/patients`),
        BATCH_SIZE,
      )) {
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
