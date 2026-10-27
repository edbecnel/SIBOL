import { Auth } from "firebase-admin/auth";
import { Firestore } from "firebase-admin/firestore";
import { assertAuthenticated } from "../authz/assert";
import { loadAccount } from "./context";
import {
  denyNonBarangayStaffForTeenRecovery,
  resolveTeenRecoveryBarangayOrgId,
  TEEN_RECOVERY_LIST_LIMIT,
} from "./teenRecoveryAuthority";

export type TeenRecoveryListEntry = {
  teenUid: string;
  displayName: string;
  signInEmail: string;
};

export type ListTeensForBarangayOrgAdminRecoveryResult = {
  managedBarangayOrgId: string;
  organizationName: string | null;
  teens: TeenRecoveryListEntry[];
};

export async function runListTeensForBarangayOrgAdminRecovery(
  db: Firestore,
  auth: Auth,
  authUid: string | undefined,
  data: Record<string, unknown>,
): Promise<ListTeensForBarangayOrgAdminRecoveryResult> {
  const actorUid = assertAuthenticated(authUid);
  const account = await loadAccount(db, actorUid);
  denyNonBarangayStaffForTeenRecovery(account);

  const { orgId, organizationName } = await resolveTeenRecoveryBarangayOrgId(
    db,
    actorUid,
    data,
  );

  const snap = await db
    .collection("users")
    .where("role", "==", "teen")
    .where("selectedBarangayOrgId", "==", orgId)
    .where("active", "==", true)
    .limit(TEEN_RECOVERY_LIST_LIMIT)
    .get();

  const teens: TeenRecoveryListEntry[] = [];
  for (const doc of snap.docs) {
    const row = doc.data();
    const displayName =
      typeof row.displayName === "string" && row.displayName.trim()
        ? row.displayName.trim()
        : "Teen";
    let signInEmail = "";
    try {
      const authUser = await auth.getUser(doc.id);
      signInEmail = authUser.email ?? "";
    } catch {
      signInEmail = "";
    }
    teens.push({
      teenUid: doc.id,
      displayName,
      signInEmail,
    });
  }

  teens.sort((a, b) => a.displayName.localeCompare(b.displayName));

  return {
    managedBarangayOrgId: orgId,
    organizationName: organizationName ?? null,
    teens,
  };
}

/** Exported for tests — ensures list entries never include sensitive profile fields. */
export function sanitizeTeenListEntry(
  entry: TeenRecoveryListEntry,
): TeenRecoveryListEntry {
  return {
    teenUid: entry.teenUid,
    displayName: entry.displayName,
    signInEmail: entry.signInEmail,
  };
}
