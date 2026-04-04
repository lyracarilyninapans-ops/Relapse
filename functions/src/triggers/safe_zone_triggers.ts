import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, SAFE_ZONE_COOLDOWN_MS, paths } from "../config";
import { ActivityRecord, SafeZoneEventData } from "../types";
import { isProcessed, markProcessed } from "../utils/idempotency";
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
 * Trigger 3: onLocationUpdateToSafeZoneEvent
 * Derives safe zone enter/exit transitions from location_update events.
 */
export const onLocationUpdateToSafeZoneEvent = onDocumentCreated(
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
    if (await isProcessed(lockPath, lockId)) return;

    const zonesSnap = await admin.firestore()
      .collection(paths.safeZones(uid, patientId))
      .where("isActive", "==", true)
      .get();

    if (zonesSnap.empty) {
      await markProcessed(lockPath, lockId);
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
      await markProcessed(lockPath, lockId);
      logger.warn("Active safe zones are malformed", { uid, patientId, recordId });
      return;
    }

    const evaluated = evaluateZoneState(data.latitude, data.longitude, zones);
    const stateRef = admin.firestore().doc(`${lockPath}/safezone_state`);
    const stateSnap = await stateRef.get();
    const previousState = stateSnap.data() as {
      status?: "inside" | "outside";
      safeZoneId?: string;
    } | undefined;

    const statusChanged =
      previousState?.status == null ||
      previousState.status !== evaluated.status ||
      previousState.safeZoneId !== evaluated.zone.id;

    if (statusChanged) {
      const eventType = evaluated.status === "inside" ? "enter" : "exit";
      const eventId = `${recordId}_${eventType}`;

      await admin.firestore()
        .doc(`${paths.safeZoneEvents(uid, patientId)}/${eventId}`)
        .set({
          id: eventId,
          patientId,
          safeZoneId: evaluated.zone.id,
          eventType,
          timestamp: data.timestamp,
          latitude: data.latitude,
          longitude: data.longitude,
          source: "location_update",
          sourceRecordId: recordId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      logger.info("Safe zone transition detected", {
        uid,
        patientId,
        recordId,
        eventType,
        safeZoneId: evaluated.zone.id,
      });
    }

    await stateRef.set({
      status: evaluated.status,
      safeZoneId: evaluated.zone.id,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      sourceRecordId: recordId,
    }, { merge: true });

    await markProcessed(lockPath, lockId);
  },
);

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

/**
 * Trigger 4: onSafeZoneEventCreated
 * Sends immediate high-priority caregiver push alert on safe zone events.
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

    const lockPath = paths.functionLocks(uid, patientId);
    const lockId = `safezone_${eventId}`;
    if (await isProcessed(lockPath, lockId)) {
      logger.info("Safe zone event already processed", { lockId });
      return;
    }

    // Enforce cooldown window to prevent alert storms
    const cooldownId = `safezone_cooldown_${data.safeZoneId}_${data.eventType}`;
    const cooldownRef = admin.firestore().doc(`${lockPath}/${cooldownId}`);
    const cooldownSnap = await cooldownRef.get();

    if (cooldownSnap.exists) {
      const cooldownData = cooldownSnap.data();
      const lastSent = cooldownData?.processedAt?.toDate?.() as Date | undefined;
      if (lastSent && Date.now() - lastSent.getTime() < SAFE_ZONE_COOLDOWN_MS) {
        logger.info("Safe zone notification suppressed (cooldown)", {
          uid, patientId, eventId, safeZoneId: data.safeZoneId,
        });
        await markProcessed(lockPath, lockId);
        return;
      }
    }

    // Resolve safe zone name
    let zoneName = "Unknown Zone";
    try {
      const zoneDoc = await admin.firestore()
        .doc(`${paths.safeZones(uid, patientId)}/${data.safeZoneId}`)
        .get();
      if (zoneDoc.exists) {
        zoneName = zoneDoc.data()?.name || zoneName;
      }
    } catch (err) {
      logger.warn("Failed to resolve zone name", { err });
    }

    // Build notification
    const isExit = data.eventType === "exit";
    const title = isExit ? "Safe Zone Alert" : "Safe Zone Update";
    const body = isExit
      ? `Patient has left the safe zone "${zoneName}"`
      : `Patient has entered the safe zone "${zoneName}"`;

    const notifData: Record<string, string> = {
      type: `safe_zone_${data.eventType}`,
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

    // Update cooldown marker
    await cooldownRef.set({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await markProcessed(lockPath, lockId);
  },
);
