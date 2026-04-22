import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, SAFE_ZONE_COOLDOWN_MS, paths } from "../config";
import { ActivityRecord, SafeZoneEventData } from "../types";
import { claimLock } from "../utils/idempotency";
import { sendPushToUser } from "../utils/notifications";
import { haversineDistance } from "../utils/geo";
import {
  isSafeZoneCooldownActive,
  pickPatientNameFromDoc,
} from "./safe_zone_notification_helpers";
import {
  processSafeZoneEventNotification,
} from "./safe_zone_event_processor";

interface SafeZoneDoc {
  id: string;
  name?: string;
  centerLat: number;
  centerLng: number;
  radiusMeters: number;
}

interface EvaluatedZoneState {
  status: "inside" | "outside";
  zone: SafeZoneDoc;
}

/**
 * Trigger: onLocationUpdateToSafeZoneEvaluation
 *
 * Evaluates safe zone state transitions from location_update events and stores
 * state under functionLocks/safezone_state for observability/debugging.
 *
 * Caregiver push notifications are intentionally sourced from watch-authored
 * safeZoneEvents documents (see onSafeZoneEventCreated).
 */
export const onLocationUpdateToSafeZoneEvaluation = onDocumentCreated(
  {
    document: "users/{uid}/patients/{patientId}/activityRecords/{recordId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, patientId, recordId } = event.params;
    const data = snap.data() as ActivityRecord;

    if (
      data.eventType !== "location_update" ||
      !data.timestamp ||
      data.latitude == null ||
      data.longitude == null
    ) {
      return;
    }

    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `safezone_eval_${recordId}`;
    if (!(await claimLock(lockPath, lockId))) return;

    const zonesSnap = await admin.firestore()
      .collection(paths.safeZones(uid, patientId))
      .where("isActive", "==", true)
      .get();

    if (zonesSnap.empty) {
      logger.info("No active safe zones configured", { uid, patientId, recordId });
      return;
    }

    const zones = zonesSnap.docs
      .map((doc) => {
        const raw = doc.data();
        const centerLat = Number(raw.centerLat);
        const centerLng = Number(raw.centerLng);
        const radiusMeters = Number(raw.radiusMeters);
        if (!Number.isFinite(centerLat) || !Number.isFinite(centerLng) || !Number.isFinite(radiusMeters)) {
          return null;
        }
        return {
          id: doc.id,
          name: typeof raw.name === "string" ? raw.name : undefined,
          centerLat,
          centerLng,
          radiusMeters,
        } as SafeZoneDoc;
      })
      .filter((z): z is SafeZoneDoc => z != null);

    if (zones.length === 0) {
      logger.warn("Active safe zones are malformed", { uid, patientId, recordId });
      return;
    }

    const evaluated = evaluateZoneState(data.latitude, data.longitude, zones);
    const stateRef = admin.firestore().doc(`${lockPath}/safezone_state`);

    await admin.firestore().runTransaction(async (t) => {
      const stateSnap = await t.get(stateRef);
      const previousState = stateSnap.data() as {
        status?: "inside" | "outside";
        safeZoneId?: string;
        lastRecordTimestamp?: FirebaseFirestore.Timestamp;
      } | undefined;

      const lastRecordTs = previousState?.lastRecordTimestamp?.toMillis?.() ?? 0;
      const incomingTs = data.timestamp?.toMillis?.() ?? 0;
      if (incomingTs > 0 && lastRecordTs > 0 && incomingTs < lastRecordTs) {
        logger.info("Skipping stale record (older than last processed)", {
          uid,
          patientId,
          recordId,
          incomingTs,
          lastRecordTs,
        });
        return;
      }

      const prevStatus = previousState?.status;
      const prevZoneId = previousState?.safeZoneId;
      const statusChanged =
        prevStatus == null ||
        prevStatus !== evaluated.status ||
        (evaluated.status === "inside" && prevZoneId !== evaluated.zone.id);

      t.set(stateRef, {
        status: evaluated.status,
        safeZoneId: evaluated.zone.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastRecordTimestamp: data.timestamp,
        sourceRecordId: recordId,
      }, { merge: true });

      if (statusChanged) {
        logger.info("Safe zone transition evaluated from location_update", {
          uid,
          patientId,
          recordId,
          status: evaluated.status,
          safeZoneId: evaluated.zone.id,
        });
      }
    });
  },
);

/**
 * Trigger: onSafeZoneEventCreated
 *
 * Sends caregiver safe-zone push notifications from watch-confirmed
 * safeZoneEvents documents. This is the authoritative notification source.
 */
export const onSafeZoneEventCreated = onDocumentCreated(
  {
    document: "users/{uid}/patients/{patientId}/safeZoneEvents/{eventId}",
    region: REGION,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { uid, patientId, eventId } = event.params;
    const data = snap.data() as SafeZoneEventData;

    const result = await processSafeZoneEventNotification(
      { uid, patientId, eventId, data },
      {
        claimLock: (lockPath, lockId) => claimLock(lockPath, lockId),
        shouldAllowAndMarkCooldown: async (cooldownDocPath, nowMs) => {
          const cooldownRef = admin.firestore().doc(cooldownDocPath);
          return admin.firestore().runTransaction(async (t) => {
            const cooldownSnap = await t.get(cooldownRef);
            if (cooldownSnap.exists) {
              const cooldownData = cooldownSnap.data();
              const lastSent = cooldownData?.processedAt?.toDate?.() as Date | undefined;
              if (isSafeZoneCooldownActive(lastSent, nowMs, SAFE_ZONE_COOLDOWN_MS)) {
                return false;
              }
            }

            t.set(cooldownRef, {
              processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return true;
          });
        },
        resolvePatientName,
        sendPush: (pushUid, title, body, notifData) =>
          sendPushToUser(pushUid, title, body, notifData),
      },
    );

    if (result === "malformed") {
      logger.warn("Malformed safe zone event payload", { uid, patientId, eventId });
      return;
    }

    if (result === "already_processed") {
      logger.info("Safe zone event already processed", { uid, patientId, eventId });
      return;
    }

    if (result === "cooldown_suppressed") {
      logger.info("Safe zone notification suppressed (cooldown)", {
        uid,
        patientId,
        eventId,
        safeZoneId: data.safeZoneId,
        eventType: data.eventType,
      });
      return;
    }

    logger.info("Safe zone notification sent", {
      uid,
      patientId,
      eventId,
      safeZoneId: data.safeZoneId,
      eventType: data.eventType,
    });
  },
);

async function resolvePatientName(uid: string, patientId: string): Promise<string> {
  try {
    const patientSnap = await admin.firestore().doc(paths.patient(uid, patientId)).get();
    if (!patientSnap.exists) {
      return "Patient";
    }

    const patientData = patientSnap.data() as Record<string, unknown> | undefined;
    return pickPatientNameFromDoc(patientData);
  } catch (err) {
    logger.warn("Failed to resolve patient name for safe zone notification", {
      uid,
      patientId,
      err,
    });
    return "Patient";
  }
}

function evaluateZoneState(
  latitude: number,
  longitude: number,
  zones: SafeZoneDoc[],
): EvaluatedZoneState {
  let nearestZone: SafeZoneDoc | null = null;
  let nearestDistance = Number.POSITIVE_INFINITY;

  let containingZone: SafeZoneDoc | null = null;
  let containingDistance = Number.POSITIVE_INFINITY;

  for (const zone of zones) {
    const distance = haversineDistance(
      latitude,
      longitude,
      zone.centerLat,
      zone.centerLng,
    );

    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearestZone = zone;
    }

    if (distance <= zone.radiusMeters && distance < containingDistance) {
      containingDistance = distance;
      containingZone = zone;
    }
  }

  if (containingZone) {
    return {
      status: "inside",
      zone: containingZone,
    };
  }

  if (!nearestZone) {
    throw new Error("Unable to evaluate safe zone state: no zones available");
  }

  return {
    status: "outside",
    zone: nearestZone,
  };
}
