import { createHash } from "node:crypto";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../authz/assert";

export function requestFingerprint(payload: Record<string, unknown>): string {
  const canonical = JSON.stringify(payload, Object.keys(payload).sort());
  return createHash("sha256").update(canonical).digest("hex");
}

export function userIdempotencyDocId(actorUid: string, idempotencyKey: string): string {
  return `${actorUid}__${idempotencyKey}`;
}

export type WorkflowIdempotencyRecord = {
  idempotencyKey: string;
  actorUid: string;
  operation: string;
  status: "in_progress" | "completed" | "failed";
  requestFingerprint: string;
  response?: Record<string, unknown>;
  createdAt: FirebaseFirestore.Timestamp;
  completedAt?: FirebaseFirestore.Timestamp;
};

export async function claimUserIdempotency(
  db: Firestore,
  collection: string,
  actorUid: string,
  idempotencyKey: string,
  operation: string,
  fingerprint: string,
): Promise<{ replay: false } | { replay: true; response: Record<string, unknown> }> {
  const ref = db
    .collection(collection)
    .doc(userIdempotencyDocId(actorUid, idempotencyKey));
  const snap = await ref.get();
  if (snap.exists) {
    const data = snap.data() as WorkflowIdempotencyRecord;
    if (data.requestFingerprint !== fingerprint) {
      throw new AuthzError(
        "idempotency key reused with different payload.",
        "failed-precondition",
      );
    }
    if (data.status === "completed" && data.response) {
      return { replay: true, response: data.response };
    }
    if (data.status === "in_progress") {
      throw new AuthzError("operation already in progress.", "failed-precondition");
    }
  }
  return { replay: false };
}

export function completeUserIdempotencyInTransaction(
  tx: FirebaseFirestore.Transaction,
  ref: FirebaseFirestore.DocumentReference,
  response: Record<string, unknown>,
  now: Timestamp,
): void {
  tx.set(
    ref,
    {
      status: "completed",
      response,
      completedAt: now,
    },
    { merge: true },
  );
}

export function initUserIdempotencyInTransaction(
  tx: FirebaseFirestore.Transaction,
  ref: FirebaseFirestore.DocumentReference,
  record: Omit<WorkflowIdempotencyRecord, "completedAt" | "response">,
): void {
  tx.create(ref, record);
}
