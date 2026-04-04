/**
 * Format a Firestore Timestamp or Date to a yyyy-MM-dd string in UTC.
 *
 * All date bucketing in Cloud Functions uses UTC to ensure consistency
 * regardless of the server's local timezone.
 */
export function toDateString(timestamp: { toDate?: () => Date } | Date): string {
  const date = "toDate" in timestamp && typeof timestamp.toDate === "function"
    ? timestamp.toDate()
    : timestamp as Date;
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/**
 * Get the start of a UTC day as a Date from a yyyy-MM-dd string.
 * Always returns midnight UTC.
 */
export function utcDayStart(dateStr: string): Date {
  return new Date(`${dateStr}T00:00:00Z`);
}

/**
 * Get the end of a UTC day (next midnight) as a Date from a yyyy-MM-dd string.
 */
export function utcDayEnd(dateStr: string): Date {
  return new Date(new Date(`${dateStr}T00:00:00Z`).getTime() + 86400000);
}
