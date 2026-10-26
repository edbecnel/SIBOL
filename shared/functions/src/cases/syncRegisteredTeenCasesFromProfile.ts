import { Firestore } from "firebase-admin/firestore";
import { AuthzError } from "../authz/assert";

export type SyncRegisteredTeenCasesFromProfileInput = {
  caseId?: string;
};

export type SyncRegisteredTeenCasesFromProfileResult = {
  updatedCaseIds: string[];
  syncedAt: string;
};

const DISABLED_MESSAGE =
  "Case identity is independent from teen site profiles. " +
  "Ongoing profile-to-case synchronization is disabled. " +
  "Use regResolveRegisteredTeenForCase when first linking a registered teen to a case.";

/**
 * Legacy callable retained for older clients. Performs no Firestore writes.
 */
export async function runSyncRegisteredTeenCasesFromProfile(
  _db: Firestore,
  authUid: string | undefined,
  _data: SyncRegisteredTeenCasesFromProfileInput,
): Promise<SyncRegisteredTeenCasesFromProfileResult> {
  if (!authUid) {
    throw new AuthzError("Authentication required.", "unauthenticated");
  }
  throw new AuthzError(DISABLED_MESSAGE, "failed-precondition");
}
