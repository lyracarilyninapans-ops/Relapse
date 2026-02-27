import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { REGION, WATCH_DISCONNECT_THRESHOLD_MS, BATTERY_THRESHOLDS, paths } from "../config";
import { WatchStatus } from "../types";
import { sendPushToUser } from "../utils/notifications";

/**
 * Trigger 4: onWatchStatusChanged
 * Notifies on disconnect and low battery transitions.
 */
export const onWatchStatusChanged = onDocumentWritten(
  {
    document: "users/{uid}/patients/{patientId}/watchStatus/current",
    region: REGION,
  },
  async (event) => {
    const { uid, patientId } = event.params;
    const beforeData = event.data?.before?.data() as WatchStatus | undefined;
    const afterData = event.data?.after?.data() as WatchStatus | undefined;

    if (!afterData) return;

    const lockPath = paths.functionLocks(uid, patientId);

    // --- Disconnect handling ---
    if (beforeData?.isConnected && !afterData.isConnected) {
      // Watch just disconnected - schedule a delayed check
      // For simplicity, we set a marker and check on the next write.
      // In production, use Cloud Tasks for precise delay.
      const disconnectMarkerRef = admin.firestore()
        .doc(`${lockPath}/watch_disconnect_pending`);

      await disconnectMarkerRef.set({
        disconnectedAt: admin.firestore.FieldValue.serverTimestamp(),
        notified: false,
      });

      logger.info("Watch disconnected, marker set", { uid, patientId });
    }

    if (!beforeData?.isConnected && afterData.isConnected) {
      // Watch reconnected - clear pending disconnect alert
      const disconnectMarkerRef = admin.firestore()
        .doc(`${lockPath}/watch_disconnect_pending`);
      await disconnectMarkerRef.delete();
      logger.info("Watch reconnected, cleared disconnect marker", { uid, patientId });
    }

    // Check if disconnect has been sustained
    if (!afterData.isConnected) {
      const markerRef = admin.firestore()
        .doc(`${lockPath}/watch_disconnect_pending`);
      const markerSnap = await markerRef.get();
      const markerData = markerSnap.data();

      if (markerData && !markerData.notified) {
        const disconnectedAt = markerData.disconnectedAt?.toDate?.() as Date | undefined;
        if (disconnectedAt && Date.now() - disconnectedAt.getTime() >= WATCH_DISCONNECT_THRESHOLD_MS) {
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
          await markerRef.update({ notified: true });
          logger.info("Watch disconnect notification sent", { uid, patientId });
        }
      }
    }

    // --- Battery handling ---
    const prevBattery = beforeData?.batteryLevel ?? 100;
    const currentBattery = afterData.batteryLevel;

    if (currentBattery != null) {
      for (const threshold of BATTERY_THRESHOLDS) {
        if (currentBattery <= threshold && prevBattery > threshold) {
          // Check if we already sent for this threshold
          const batteryLockId = `battery_${threshold}`;
          const batteryLockRef = admin.firestore()
            .doc(`${lockPath}/${batteryLockId}`);
          const batteryLock = await batteryLockRef.get();

          if (!batteryLock.exists) {
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
            await batteryLockRef.set({
              processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            logger.info("Battery warning sent", { uid, patientId, threshold, currentBattery });
          }
          break; // Only send one notification per update
        }
      }

      // Reset battery locks when battery goes above all thresholds
      if (currentBattery > BATTERY_THRESHOLDS[0]) {
        for (const threshold of BATTERY_THRESHOLDS) {
          await admin.firestore()
            .doc(`${lockPath}/battery_${threshold}`)
            .delete()
            .catch(() => { /* ignore if doesn't exist */ });
        }
      }
    }
  },
);
