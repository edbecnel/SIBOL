import { createHash } from "node:crypto";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../authz/assert";

const COLLECTION = "organizationCreationIdempotency";

export function requestFingerprint(payload: Record<string, unknown>): string {
  const canonical = JSON.stringify(payload, Object.keys(payload).sort());
  return createHash("sha256").update(canonical).digest("hex");
}

export function idempotencyDocId(centralAdminUid: string, idempotencyKey: string): string {
  return `${centralAdminUid}__${idempotencyKey}`;
}

export type IdempotencyRecord = {
  idempotencyKey: string;
  centralAdminUid: string;
  operation: string;
  status: "in_progress" | "completed" | "failed";
  requestFingerprint: string;
  response?: Record<string, unknown>;
  createdAt: FirebaseFirestore.Timestamp;
  completedAt?: FirebaseFirestore.Timestamp;
};

export async function claimIdempotency(
  db: Firestore,
  centralAdminUid: string,
  idempotencyKey: string,
  operation: string,
  fingerprint: string,
): Promise<{ replay: false } | { replay: true; response: Record<string, unknown> }> {
  const ref = db.collection(COLLECTION).doc(idempotencyDocId(centralAdminUid, idempotencyKey));
  const snap = await ref.get();
  if (snap.exists) {
    const data = snap.data() as IdempotencyRecord;
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
      throw new AuthzError("creation already in progress.", "failed-precondition");
    }
  }
  return { replay: false };
}

export function completeIdempotencyInTransaction(
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

export function initIdempotencyInTransaction(
  tx: FirebaseFirestore.Transaction,
  ref: FirebaseFirestore.DocumentReference,
  record: Omit<IdempotencyRecord, "completedAt" | "response">,
): void {
  tx.create(ref, record);
}
