import { SAFE_ZONE_COOLDOWN_MS, paths } from "../config";
import { SafeZoneEventData } from "../types";
import { buildSafeZoneNotificationBody } from "./safe_zone_notification_helpers";

export type SafeZoneEventProcessStatus =
  | "malformed"
  | "already_processed"
  | "cooldown_suppressed"
  | "sent";

export interface SafeZoneEventProcessInput {
  uid: string;
  patientId: string;
  eventId: string;
  data: SafeZoneEventData;
}

export interface SafeZoneEventProcessDeps {
  claimLock: (lockPath: string, lockId: string) => Promise<boolean>;
  shouldAllowAndMarkCooldown: (cooldownDocPath: string, nowMs: number) => Promise<boolean>;
  resolvePatientName: (uid: string, patientId: string) => Promise<string>;
  sendPush: (
    uid: string,
    title: string,
    body: string,
    data: Record<string, string>,
  ) => Promise<number>;
  nowMs?: () => number;
}

export function buildSafeZoneNotificationTitle(eventType: SafeZoneEventData["eventType"]): string {
  return eventType === "exit" ? "Safe Zone Alert" : "Safe Zone Update";
}

export function buildSafeZoneNotificationData(
  patientId: string,
  eventId: string,
  eventType: SafeZoneEventData["eventType"],
): Record<string, string> {
  return {
    type: `safe_zone_${eventType}`,
    patientId,
    eventId,
    screen: "activity",
    channelId: "safe_zone_alerts",
  };
}

export async function processSafeZoneEventNotification(
  input: SafeZoneEventProcessInput,
  deps: SafeZoneEventProcessDeps,
): Promise<SafeZoneEventProcessStatus> {
  const { uid, patientId, eventId, data } = input;

  if (!data.safeZoneId || !data.eventType || !data.timestamp) {
    return "malformed";
  }

  const lockPath = paths.functionLocks(uid, patientId);
  const lockId = `safezone_${eventId}`;
  const lockAcquired = await deps.claimLock(lockPath, lockId);
  if (!lockAcquired) {
    return "already_processed";
  }

  const nowMs = deps.nowMs?.() ?? Date.now();
  const cooldownId = `safezone_cooldown_${data.safeZoneId}_${data.eventType}`;
  const cooldownDocPath = `${lockPath}/${cooldownId}`;
  const cooldownAllowed = await deps.shouldAllowAndMarkCooldown(cooldownDocPath, nowMs);
  if (!cooldownAllowed) {
    return "cooldown_suppressed";
  }

  const patientName = await deps.resolvePatientName(uid, patientId);
  const title = buildSafeZoneNotificationTitle(data.eventType);
  const body = buildSafeZoneNotificationBody(patientName, data.eventType);
  const notifData = buildSafeZoneNotificationData(patientId, eventId, data.eventType);

  await deps.sendPush(uid, title, body, notifData);
  return "sent";
}

export { SAFE_ZONE_COOLDOWN_MS };
