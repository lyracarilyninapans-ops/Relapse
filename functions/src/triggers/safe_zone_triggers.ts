import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, SAFE_ZONE_COOLDOWN_MS, paths } from "../config";
import { SafeZoneEventData } from "../types";
import { isProcessed, markProcessed } from "../utils/idempotency";
import { sendPushToUser } from "../utils/notifications";

/**
 * Trigger 3: onSafeZoneEventCreated
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

    const sent = await sendPushToUser(uid, title, body, notifData);
    logger.info("Safe zone push sent", { uid, patientId, eventId, sent });

    // Update cooldown marker
    await cooldownRef.set({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await markProcessed(lockPath, lockId);
  },
);
