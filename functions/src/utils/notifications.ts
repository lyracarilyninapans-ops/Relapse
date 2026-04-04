import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { DeviceRecord } from "../types";

/**
 * Send a push notification to all devices registered for a given user.
 * Sends to all devices in parallel for lower latency.
 * Returns the number of messages successfully sent.
 *
 * NOTE: Stale FCM tokens are cleaned up reactively on send failure.
 * Consider adding a periodic Cloud Function or Firestore TTL to purge
 * devices that haven't updated their token in > 30 days.
 */
export async function sendPushToUser(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string> = {},
): Promise<number> {
  const devicesSnap = await admin
    .firestore()
    .collection(`users/${uid}/devices`)
    .get();

  if (devicesSnap.empty) {
    logger.info("No devices found for user", { uid });
    return 0;
  }

  const results = await Promise.allSettled(
    devicesSnap.docs
      .filter((doc) => {
        const device = doc.data() as DeviceRecord;
        return Boolean(device.fcmToken);
      })
      .map(async (doc) => {
        const device = doc.data() as DeviceRecord;
        try {
          await admin.messaging().send({
            token: device.fcmToken,
            notification: { title, body },
            data,
            android: {
              priority: "high",
              notification: { channelId: data["channelId"] || "safe_zone_alerts" },
            },
          });
          return { success: true, docRef: doc.ref } as const;
        } catch (err: unknown) {
          const error = err as { code?: string };
          logger.warn("FCM send failed", {
            uid,
            deviceId: doc.id,
            error: error.code || String(err),
          });

          // Remove stale tokens
          if (
            error.code === "messaging/registration-token-not-registered" ||
            error.code === "messaging/invalid-registration-token" ||
            error.code === "messaging/mismatched-credential"
          ) {
            await doc.ref.delete();
            logger.info("Removed stale FCM token", { uid, deviceId: doc.id });
          }

          return { success: false, docRef: doc.ref } as const;
        }
      }),
  );

  const sent = results.filter(
    (r) => r.status === "fulfilled" && r.value.success,
  ).length;

  return sent;
}
