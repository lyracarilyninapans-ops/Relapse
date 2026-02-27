import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { DeviceRecord } from "../types";

/**
 * Send a push notification to all devices registered for a given user.
 * Returns the number of messages successfully sent.
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

  let sent = 0;
  for (const doc of devicesSnap.docs) {
    const device = doc.data() as DeviceRecord;
    if (!device.fcmToken) continue;

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
      sent++;
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
        error.code === "messaging/invalid-registration-token"
      ) {
        await doc.ref.delete();
        logger.info("Removed stale FCM token", { uid, deviceId: doc.id });
      }
    }
  }

  return sent;
}
