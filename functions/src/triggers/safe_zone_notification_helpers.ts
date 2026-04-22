export type SafeZoneTransitionEventType = "enter" | "exit";

const DEFAULT_PATIENT_NAME = "Patient";

export function pickPatientNameFromDoc(
  patientData: Record<string, unknown> | undefined,
): string {
  if (!patientData) {
    return DEFAULT_PATIENT_NAME;
  }

  const candidate = [
    patientData.name,
    patientData.patientName,
    patientData.displayName,
  ].find((value) => typeof value === "string" && value.trim().length > 0) as string | undefined;

  return candidate?.trim() || DEFAULT_PATIENT_NAME;
}

export function buildSafeZoneNotificationBody(
  patientName: string,
  eventType: SafeZoneTransitionEventType,
): string {
  const resolvedName = patientName.trim().length > 0 ? patientName.trim() : DEFAULT_PATIENT_NAME;
  return eventType === "exit"
    ? `${resolvedName} has left the safe zone`
    : `${resolvedName} has entered the safe zone`;
}

export function isSafeZoneCooldownActive(
  lastSentAt: Date | undefined,
  nowMs: number,
  cooldownMs: number,
): boolean {
  if (!lastSentAt) {
    return false;
  }

  return (nowMs - lastSentAt.getTime()) < cooldownMs;
}
