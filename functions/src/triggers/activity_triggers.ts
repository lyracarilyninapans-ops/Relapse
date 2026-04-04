import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { ActivityRecord } from "../types";
import { claimLock } from "../utils/idempotency";
import { toDateString, utcDayStart, utcDayEnd } from "../utils/dates";
import { haversineDistance, locationCellKey } from "../utils/geo";
import { calculateActiveMinutes, inferInitiallyOutside } from "../utils/summary_metrics";

/**
 * Trigger 1: onActivityRecordCreated
 * Validates event payload, enriches metadata, and fans out downstream writes.
 */
export const onActivityRecordCreated = onDocumentCreated(
  {
    document: "users/{uid}/patients/{patientId}/activityRecords/{recordId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, patientId, recordId } = event.params;
    const data = snap.data() as ActivityRecord;

    // Validate required fields
    if (!data.timestamp || !data.eventType || !data.patientId) {
      logger.warn("Malformed activity record, quarantining", { uid, patientId, recordId });
      await admin.firestore()
        .doc(`users/${uid}/patients/${patientId}/invalidEvents/${recordId}`)
        .set({ ...data, quarantinedAt: admin.firestore.FieldValue.serverTimestamp() });
      return;
    }

    // Atomic idempotency lock
    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `activity_${recordId}`;
    if (!(await claimLock(lockPath, lockId))) {
      logger.info("Already processed", { lockId });
      return;
    }

    // Upsert latest location when event includes coordinates
    if (data.latitude != null && data.longitude != null) {
      await admin.firestore()
        .doc(`users/${uid}/patients/${patientId}/latestLocation/current`)
        .set({
          latitude: data.latitude,
          longitude: data.longitude,
          timestamp: data.timestamp,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }

    logger.info("Activity record processed", { uid, patientId, recordId, eventType: data.eventType });
  },
);

/**
 * Trigger 2: onActivityRecordForSummary
 * Incrementally maintains dailySummaries/{date} for Activity Screen cards.
 *
 * Uses a full recount from source records inside a transaction to ensure
 * idempotency — this is safe because retries produce the same result.
 */
export const onActivityRecordForSummary = onDocumentCreated(
  {
    document: "users/{uid}/patients/{patientId}/activityRecords/{recordId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, patientId, recordId } = event.params;
    const data = snap.data() as ActivityRecord;

    if (!data.timestamp || !data.eventType) return;

    // Atomic idempotency lock
    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `summary_${recordId}`;
    if (!(await claimLock(lockPath, lockId))) return;

    const dateStr = toDateString(data.timestamp);
    const isToday = dateStr === toDateString(new Date());
    const dayStart = utcDayStart(dateStr);
    const dayEnd = utcDayEnd(dateStr);
    const summaryRef = admin.firestore()
      .doc(`${paths.dailySummaries(uid, patientId)}/${dateStr}`);

    // Fetch ALL records for the day to compute idempotent totals
    const dayRecordsSnap = await admin.firestore()
      .collection(paths.activityRecords(uid, patientId))
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(dayStart))
      .where("timestamp", "<", admin.firestore.Timestamp.fromDate(dayEnd))
      .orderBy("timestamp")
      .get();

    const boundarySnap = await admin.firestore()
      .collection(paths.activityRecords(uid, patientId))
      .where("timestamp", "<", admin.firestore.Timestamp.fromDate(dayStart))
      .orderBy("timestamp", "desc")
      .limit(20)
      .get();

    const allRecords = dayRecordsSnap.docs.map((doc) => doc.data() as ActivityRecord);

    const initiallyOutside = inferInitiallyOutside(
      boundarySnap.docs.map((doc) => doc.data() as ActivityRecord),
    );

    const activeMinutes = calculateActiveMinutes(allRecords, {
      dayStart,
      dayEnd,
      openIntervalEnd: isToday ? new Date() : dayEnd,
      initiallyOutside,
    });

    // Compute all metrics from source records (idempotent)
    let totalEvents = 0;
    let safeZoneExits = 0;
    let remindersTriggered = 0;
    let distanceMeters = 0;
    let lastLat: number | undefined;
    let lastLng: number | undefined;
    const visitedCellsMap: Record<string, true> = {};

    for (const rec of allRecords) {
      totalEvents++;
      if (rec.eventType === "safe_zone_exit") safeZoneExits++;
      if (rec.eventType === "reminder_triggered") remindersTriggered++;

      if (rec.eventType === "location_update" && rec.latitude != null && rec.longitude != null) {
        const cellKey = locationCellKey(rec.latitude, rec.longitude);
        visitedCellsMap[cellKey] = true;

        if (lastLat != null && lastLng != null) {
          const segmentDist = haversineDistance(lastLat, lastLng, rec.latitude, rec.longitude);
          distanceMeters += segmentDist;
        }
        lastLat = rec.latitude;
        lastLng = rec.longitude;
      }
    }

    const placesVisited = Object.keys(visitedCellsMap).length;

    await admin.firestore().runTransaction(async (txn) => {
      // Read inside transaction to avoid overwriting concurrent updates
      await txn.get(summaryRef);

      txn.set(summaryRef, {
        date: dateStr,
        patientId,
        totalEvents,
        safeZoneExits,
        remindersTriggered,
        distanceMeters,
        activeMinutes,
        placesVisited,
        visitedCells: visitedCellsMap,
        lastLat,
        lastLng,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });

    logger.info("Daily summary updated", { uid, patientId, dateStr });
  },
);
