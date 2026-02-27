import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, paths } from "../config";
import { ActivityRecord } from "../types";
import { isProcessed, markProcessed } from "../utils/idempotency";
import { toDateString } from "../utils/dates";
import { haversineDistance, locationCellKey } from "../utils/geo";

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

    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `activity_${recordId}`;
    if (await isProcessed(lockPath, lockId)) {
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

    await markProcessed(lockPath, lockId);
    logger.info("Activity record processed", { uid, patientId, recordId, eventType: data.eventType });
  },
);

/**
 * Trigger 2: onActivityRecordForSummary
 * Incrementally maintains dailySummaries/{date} for Activity Screen cards.
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

    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `summary_${recordId}`;
    if (await isProcessed(lockPath, lockId)) return;

    const dateStr = toDateString(data.timestamp);
    const summaryRef = admin.firestore()
      .doc(`${paths.dailySummaries(uid, patientId)}/${dateStr}`);

    await admin.firestore().runTransaction(async (txn) => {
      const summarySnap = await txn.get(summaryRef);
      const existing = summarySnap.data() || {
        date: dateStr,
        totalEvents: 0,
        safeZoneExits: 0,
        remindersTriggered: 0,
        distanceMeters: 0,
        activeMinutes: 0,
        placesVisited: 0,
      };

      const updates: Record<string, unknown> = {
        totalEvents: (existing.totalEvents || 0) + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (data.eventType === "safe_zone_exit") {
        updates.safeZoneExits = (existing.safeZoneExits || 0) + 1;
      }
      if (data.eventType === "reminder_triggered") {
        updates.remindersTriggered = (existing.remindersTriggered || 0) + 1;
      }

      // Distance calculation for sequential location points
      if (data.eventType === "location_update" && data.latitude != null && data.longitude != null) {
        // Track places visited via location cells
        const cellKey = locationCellKey(data.latitude, data.longitude);
        const visitedCells: string[] = existing.visitedCells || [];
        if (!visitedCells.includes(cellKey)) {
          visitedCells.push(cellKey);
          updates.visitedCells = visitedCells;
          updates.placesVisited = visitedCells.length;
        }

        // Compute segment distance from last known location
        if (existing.lastLat != null && existing.lastLng != null) {
          const segmentDist = haversineDistance(
            existing.lastLat, existing.lastLng,
            data.latitude, data.longitude,
          );
          updates.distanceMeters = (existing.distanceMeters || 0) + segmentDist;
        }

        updates.lastLat = data.latitude;
        updates.lastLng = data.longitude;
      }

      txn.set(summaryRef, { ...existing, ...updates }, { merge: true });
    });

    await markProcessed(lockPath, lockId);
    logger.info("Daily summary updated", { uid, patientId, dateStr });
  },
);
