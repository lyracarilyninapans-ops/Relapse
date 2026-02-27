import * as admin from "firebase-admin";

/** Check if an event has already been processed to ensure idempotency. */
export async function isProcessed(lockPath: string, eventId: string): Promise<boolean> {
  const doc = await admin.firestore().doc(`${lockPath}/${eventId}`).get();
  return doc.exists;
}

/** Mark an event as processed. */
export async function markProcessed(lockPath: string, eventId: string): Promise<void> {
  await admin.firestore().doc(`${lockPath}/${eventId}`).set({
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
