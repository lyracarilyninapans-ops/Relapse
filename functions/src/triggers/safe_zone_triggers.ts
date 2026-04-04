import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, SAFE_ZONE_COOLDOWN_MS, paths } from "../config";
import { ActivityRecord } from "../types";
import { claimLock } from "../utils/idempotency";
import { sendPushToUser } from "../utils/notifications";
import { haversineDistance } from "../utils/geo";

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
 * Merged Trigger: onLocationUpdateToSafeZoneEvaluation
 *
 * Evaluates safe zone transitions from location_update events AND sends
 * FCM push notifications to the caregiver — all in a single invocation.
 *
 * Uses atomic claimLock to prevent duplicate processing, and a Firestore
 * transaction for state + cooldown to prevent duplicate notifications.
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

    // Atomic idempotency lock — claim FIRST, before any work or pushes
    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `safezone_eval_${recordId}`;
    if (!(await claimLock(lockPath, lockId))) return;

    // Fetch active safe zones
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
    const eventType = evaluated.status === "inside" ? "enter" : "exit";
    const eventId = `${recordId}_${eventType}`;

    const stateRef = admin.firestore().doc(`${lockPath}/safezone_state`);
    const cooldownId = `safezone_cooldown_${evaluated.zone.id}_${eventType}`;
    const cooldownRef = admin.firestore().doc(`${lockPath}/${cooldownId}`);

    const shouldSendPush = await admin.firestore().runTransaction(async (t) => {
      // 1. Read state & cooldown concurrently inside transaction
      const [stateSnap, cooldownSnap] = await Promise.all([
        t.get(stateRef),
        t.get(cooldownRef),
      ]);

      const previousState = stateSnap.data() as {
        status?: "inside" | "outside";
        safeZoneId?: string;
        lastRecordTimestamp?: FirebaseFirestore.Timestamp;
      } | undefined;

      // ── Fix 1: Skip stale records ─────────────────────────────────
      // When the watch batch-uploads activity records, older "inside"
      // records can arrive after a newer "outside" record has already
      // transitioned the state. Comparing timestamps prevents old
      // records from corrupting the current zone state.
      const lastRecordTs = previousState?.lastRecordTimestamp?.toMillis?.() ?? 0;
      const incomingTs = data.timestamp?.toMillis?.() ?? 0;
      if (incomingTs > 0 && lastRecordTs > 0 && incomingTs < lastRecordTs) {
        logger.info("Skipping stale record (older than last processed)", {
          uid, patientId, recordId, incomingTs, lastRecordTs,
        });
        return false;
      }

      // Only consider it a real transition if:
      // - The inside/outside status actually changed, OR
      // - The patient moved into a DIFFERENT zone (but was already inside one)
      // Ignore changes in "nearest zone" when outside all zones to prevent
      // flip-flop false transitions.
      const prevStatus = previousState?.status;
      const prevZoneId = previousState?.safeZoneId;
      const statusChanged =
        prevStatus == null ||
        prevStatus !== evaluated.status ||
        (evaluated.status === "inside" && prevZoneId !== evaluated.zone.id);

      if (!statusChanged) {
        // State hasn't changed. Update timestamp so we know device is alive.
        t.set(stateRef, {
          status: evaluated.status,
          safeZoneId: evaluated.zone.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastRecordTimestamp: data.timestamp,
          sourceRecordId: recordId,
        }, { merge: true });
        return false;
      }

      // 2. State DID change. Update state.
      t.set(stateRef, {
        status: evaluated.status,
        safeZoneId: evaluated.zone.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastRecordTimestamp: data.timestamp,
        sourceRecordId: recordId,
      }, { merge: true });

      // Note: safeZoneEvents are written by the watch directly via
      // SyncService.syncSafeZoneEventsToFirestore(). We intentionally
      // do NOT write events here to prevent duplicate documents.

      logger.info("Safe zone transition registered in TX", {
        uid, patientId, recordId, eventType, safeZoneId: evaluated.zone.id,
      });

      // 4. Check Cooldown
      if (cooldownSnap.exists) {
        const cooldownData = cooldownSnap.data();
        const lastSent = cooldownData?.processedAt?.toDate?.() as Date | undefined;
        if (lastSent && Date.now() - lastSent.getTime() < SAFE_ZONE_COOLDOWN_MS) {
          logger.info("Safe zone notification suppressed (cooldown)", {
            uid, patientId, eventId, safeZoneId: evaluated.zone.id,
          });
          return false;
        }
      }

      // 5. Update Cooldown Marker
      t.set(cooldownRef, {
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return true;
    });

    if (shouldSendPush) {
      await sendSafeZonePushInternal(uid, patientId, eventId, eventType, evaluated.zone.id);
    }
  },
);

/**
 * Sends a high-priority FCM push notification to the caregiver.
 * Cooldown checks and limits are done transactionally beforehand.
 */
async function sendSafeZonePushInternal(
  uid: string,
  patientId: string,
  eventId: string,
  eventType: "enter" | "exit",
  safeZoneId: string,
): Promise<void> {
  const isExit = eventType === "exit";
  const title = isExit ? "Safe Zone Alert" : "Safe Zone Update";
  const body = isExit
    ? `Patient has left the safe zone`
    : `Patient has entered the safe zone`;

  const notifData: Record<string, string> = {
    type: `safe_zone_${eventType}`,
    patientId,
    eventId,
    screen: "activity",
    channelId: "safe_zone_alerts",
  };

  logger.info("Attempting to send push notification", { uid, patientId, title, notifData });
  try {
    const sent = await sendPushToUser(uid, title, body, notifData);
    logger.info("Safe zone push result", { uid, patientId, eventId, sent });
  } catch (pushErr) {
    logger.error("Failed to send safe zone push", { uid, patientId, eventId, pushErr });
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
