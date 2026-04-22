import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, WATCH_DISCONNECT_THRESHOLD_MS, BATTERY_THRESHOLDS, paths } from "../config";
import { WatchStatus } from "../types";
import { sendPushToUser } from "../utils/notifications";

/**
 * Trigger 4: onWatchStatusChanged
 * Notifies on disconnect and low battery transitions.
 *
 * Uses Firestore transactions for battery and disconnect marker operations
 * to prevent duplicate notifications from concurrent triggering.
 */
export const onWatchStatusChanged = onDocumentWritten(
  {
    // Watch updates are written as `watchStatus` map on the patient document.
    document: "users/{uid}/patients/{patientId}",
    region: REGION,
  },
  async (event) => {
    const { uid, patientId } = event.params;
    const beforeDoc = event.data?.before?.data() as Record<string, unknown> | undefined;
    const afterDoc = event.data?.after?.data() as Record<string, unknown> | undefined;
    const beforeData = parseWatchStatus(beforeDoc?.watchStatus);
    const afterData = parseWatchStatus(afterDoc?.watchStatus);

    if (!afterData) return;

    const lockPath = paths.functionLocks(uid, patientId);
    const disconnectMarkerRef = admin.firestore()
      .doc(`${lockPath}/watch_disconnect_pending`);

    // --- Disconnect handling (transactional) ---
    if (beforeData?.isConnected && !afterData.isConnected) {
      // Watch just disconnected — atomically set marker
      await admin.firestore().runTransaction(async (t) => {
        t.set(disconnectMarkerRef, {
          disconnectedAt: admin.firestore.FieldValue.serverTimestamp(),
          notified: false,
        });
      });
      logger.info("Watch disconnected, marker set", { uid, patientId });
    }

    if (!beforeData?.isConnected && afterData.isConnected) {
      // Watch reconnected — clear pending disconnect alert
      await disconnectMarkerRef.delete();
      logger.info("Watch reconnected, cleared disconnect marker", { uid, patientId });
    }

    // Check if disconnect has been sustained (transactional read + update)
    if (!afterData.isConnected) {
      const shouldNotify = await admin.firestore().runTransaction(async (t) => {
        const markerSnap = await t.get(disconnectMarkerRef);
        const markerData = markerSnap.data();

        if (!markerData || markerData.notified) return false;

        const disconnectedAt = markerData.disconnectedAt?.toDate?.() as Date | undefined;
        if (!disconnectedAt) return false;

        if (Date.now() - disconnectedAt.getTime() >= WATCH_DISCONNECT_THRESHOLD_MS) {
          t.update(disconnectMarkerRef, { notified: true });
          return true;
        }
        return false;
      });

      if (shouldNotify) {
        await sendPushToUser(uid,
          "Watch Disconnected",
          "The paired watch has been disconnected for over 10 minutes.",
          {
            type: "watch_disconnected",
            patientId,
            screen: "activity",
            channelId: "watch_status",
          },
        );
        logger.info("Watch disconnect notification sent", { uid, patientId });
      }
    }

    // --- Battery handling (transactional) ---
    const prevBattery = beforeData?.batteryLevel ?? 100;
    const currentBattery = afterData.batteryLevel;

    if (currentBattery != null) {
      for (const threshold of BATTERY_THRESHOLDS) {
        if (currentBattery <= threshold && prevBattery > threshold) {
          const batteryLockId = `battery_${threshold}`;
          const batteryLockRef = admin.firestore()
            .doc(`${lockPath}/${batteryLockId}`);

          // Atomically check-and-claim battery lock
          const shouldSendBattery = await admin.firestore().runTransaction(async (t) => {
            const lockSnap = await t.get(batteryLockRef);
            if (lockSnap.exists) return false; // Already notified for this threshold
            t.set(batteryLockRef, {
              processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            return true;
          });

          if (shouldSendBattery) {
            await sendPushToUser(uid,
              "Watch Battery Low",
              `Watch battery is at ${currentBattery}%. Please charge soon.`,
              {
                type: "watch_low_battery",
                patientId,
                batteryLevel: String(currentBattery),
                channelId: "watch_status",
              },
            );
            logger.info("Battery warning sent", { uid, patientId, threshold, currentBattery });
          }
          break; // Only send one notification per update
        }
      }

      // Reset battery locks when battery goes above all thresholds
      if (currentBattery > BATTERY_THRESHOLDS[0]) {
        const batch = admin.firestore().batch();
        for (const threshold of BATTERY_THRESHOLDS) {
          batch.delete(admin.firestore().doc(`${lockPath}/battery_${threshold}`));
        }
        await batch.commit().catch(() => { /* ignore if don't exist */ });
      }
    }
  },
);

function parseWatchStatus(input: unknown): WatchStatus | undefined {
  if (!input || typeof input !== "object") return undefined;

  const raw = input as Record<string, unknown>;
  const isConnected = Boolean(raw.isConnected);
  const batteryRaw = raw.batteryLevel;
  const batteryLevel = typeof batteryRaw === "number"
    ? batteryRaw
    : typeof batteryRaw === "string"
      ? Number.parseInt(batteryRaw, 10)
      : undefined;

  return {
    isConnected,
    batteryLevel: Number.isFinite(batteryLevel as number) ? batteryLevel : undefined,
  };
}
