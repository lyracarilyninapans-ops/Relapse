/**
 * Format a Firestore Timestamp or Date to a yyyy-MM-dd string.
 */
export function toDateString(timestamp: { toDate?: () => Date } | Date): string {
  const date = "toDate" in timestamp && typeof timestamp.toDate === "function"
    ? timestamp.toDate()
    : timestamp as Date;
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}
