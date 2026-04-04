type TimestampLike = { toDate?: () => Date } | Date;

export interface TimedEvent {
  eventType: string;
  timestamp: TimestampLike;
}

interface ActiveMinutesOptions {
  dayStart: Date;
  dayEnd: Date;
  openIntervalEnd?: Date;
  initiallyOutside?: boolean;
}

const EXIT_EVENT = "safe_zone_exit";
const ENTER_EVENT = "safe_zone_enter";

function toDate(value: TimestampLike): Date {
  if ("toDate" in value && typeof value.toDate === "function") {
    return value.toDate();
  }
  return value as Date;
}

function clampToDay(value: Date, dayStart: Date, dayEnd: Date): Date {
  if (value <= dayStart) return dayStart;
  if (value >= dayEnd) return dayEnd;
  return value;
}

/**
 * Determines if the patient was outside at the start of the day by
 * inspecting events before dayStart and finding the latest enter/exit event.
 */
export function inferInitiallyOutside(historyEvents: TimedEvent[]): boolean {
  for (const event of historyEvents) {
    if (event.eventType === EXIT_EVENT) return true;
    if (event.eventType === ENTER_EVENT) return false;
  }
  return false;
}

/**
 * Calculates minutes spent outside safe zone for a given day window.
 */
export function calculateActiveMinutes(
  events: TimedEvent[],
  options: ActiveMinutesOptions,
): number {
  const sorted = [...events].sort((a, b) =>
    toDate(a.timestamp).getTime() - toDate(b.timestamp).getTime(),
  );

  const dayStartMs = options.dayStart.getTime();
  const openIntervalEnd = clampToDay(
    options.openIntervalEnd ?? options.dayEnd,
    options.dayStart,
    options.dayEnd,
  );
  const openIntervalEndMs = openIntervalEnd.getTime();

  let outsideSinceMs: number | null = options.initiallyOutside ? dayStartMs : null;
  let totalOutsideMs = 0;

  for (const event of sorted) {
    const eventMs = clampToDay(toDate(event.timestamp), options.dayStart, options.dayEnd).getTime();

    if (event.eventType === EXIT_EVENT) {
      if (outsideSinceMs == null) {
        outsideSinceMs = eventMs;
      }
      continue;
    }

    if (event.eventType === ENTER_EVENT && outsideSinceMs != null) {
      if (eventMs > outsideSinceMs) {
        totalOutsideMs += eventMs - outsideSinceMs;
      }
      outsideSinceMs = null;
    }
  }

  if (outsideSinceMs != null && openIntervalEndMs > outsideSinceMs) {
    totalOutsideMs += openIntervalEndMs - outsideSinceMs;
  }

  return Math.floor(totalOutsideMs / 60000);
}
