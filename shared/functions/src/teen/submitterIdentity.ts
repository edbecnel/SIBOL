import { Firestore } from "firebase-admin/firestore";

export type SubmitterIdentitySnapshot = {
  submitterDisplayName?: string;
  submitterAccountEmail?: string;
};

export type GetAccountEmailFn = (uid: string) => Promise<string | undefined>;

export async function resolveSubmitterIdentityFromAuthoritativeSources(
  db: Firestore,
  teenUid: string,
  getAccountEmail: GetAccountEmailFn,
): Promise<SubmitterIdentitySnapshot> {
  const snapshot: SubmitterIdentitySnapshot = {};

  const userSnap = await db.collection("users").doc(teenUid).get();
  if (userSnap.exists) {
    const rawName = userSnap.data()?.displayName;
    if (typeof rawName === "string" && rawName.trim().length > 0) {
      snapshot.submitterDisplayName = rawName.trim();
    }
  }

  try {
    const rawEmail = await getAccountEmail(teenUid);
    if (typeof rawEmail === "string" && rawEmail.trim().length > 0) {
      snapshot.submitterAccountEmail = rawEmail.trim();
    }
  } catch {
    // Email is optional; do not fail identity resolution.
  }

  return snapshot;
}

export function identitySnapshotsEqual(
  stored: SubmitterIdentitySnapshot,
  resolved: SubmitterIdentitySnapshot,
): boolean {
  return (
    (stored.submitterDisplayName ?? undefined) ===
      (resolved.submitterDisplayName ?? undefined) &&
    (stored.submitterAccountEmail ?? undefined) ===
      (resolved.submitterAccountEmail ?? undefined)
  );
}

export function storedIdentityFromAssistance(
  assistance: Record<string, unknown>,
): SubmitterIdentitySnapshot {
  const snapshot: SubmitterIdentitySnapshot = {};
  const name = assistance.submitterDisplayName;
  const email = assistance.submitterAccountEmail;
  if (typeof name === "string" && name.trim().length > 0) {
    snapshot.submitterDisplayName = name.trim();
  }
  if (typeof email === "string" && email.trim().length > 0) {
    snapshot.submitterAccountEmail = email.trim();
  }
  return snapshot;
}
