import * as admin from "firebase-admin";

/**
 * Atomically claim a processing lock for the given event.
 * Returns `true` if the lock was acquired (i.e. this is the first invocation).
 * Returns `false` if the event was already processed (lock document exists).
 *
 * Uses Firestore `create()` which fails with ALREADY_EXISTS if the document
 * already exists — this is atomic and eliminates the TOCTOU race between
 * a separate `isProcessed` read and `markProcessed` write.
 *
 * NOTE: These lock documents accumulate over time. Configure a Firestore
 * TTL policy on the `processedAt` field to auto-delete old locks
 * (e.g., after 7 days). See:
 * https://firebase.google.com/docs/firestore/ttl
 */
export async function claimLock(lockPath: string, eventId: string): Promise<boolean> {
  const lockRef = admin.firestore().doc(`${lockPath}/${eventId}`);
  try {
    await lockRef.create({
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true; // Lock acquired — first invocation
  } catch (err: unknown) {
    const firestoreErr = err as { code?: number | string };
    // code 6 = ALREADY_EXISTS (gRPC), "already-exists" (Admin SDK)
    if (firestoreErr.code === 6 || firestoreErr.code === "already-exists") {
      return false; // Already processed
    }
    throw err; // Unexpected error — rethrow
  }
}

// ── Legacy aliases (kept for backward compat, prefer claimLock) ──

/** @deprecated Use `claimLock` instead — it's atomic. */
export async function isProcessed(lockPath: string, eventId: string): Promise<boolean> {
  const doc = await admin.firestore().doc(`${lockPath}/${eventId}`).get();
  return doc.exists;
}

/** @deprecated Use `claimLock` instead — it's atomic. */
export async function markProcessed(lockPath: string, eventId: string): Promise<void> {
  await admin.firestore().doc(`${lockPath}/${eventId}`).set({
    processedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
