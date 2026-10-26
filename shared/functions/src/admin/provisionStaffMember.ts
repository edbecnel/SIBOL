import { Auth } from "firebase-admin/auth";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import {
  assertAuthenticated,
  assertPasswordChangeNotRequired,
  AuthzError,
} from "../authz/assert";
import { membershipIdFor } from "../authz/identifiers";
import { capabilitySnapshot, writeAuditEvent } from "./audit";
import {
  assertCanManageOrg,
  loadAccount,
  loadMembership,
  loadOrganization,
} from "./context";
import { normalizeEmail } from "./email";
import {
  assertAssignableCapabilities,
  defaultStaffCapabilitiesForOrgType,
} from "./policy";

const MIN_PASSWORD_LENGTH = 8;
const MIN_DISPLAY_NAME_LENGTH = 2;
const IDEMPOTENCY_COLLECTION = "staffProvisioningOperations";

function orgTypeOf(
  org: { type?: string },
): "barangay" | "hospital" {
  if (org.type === "hospital") return "hospital";
  if (org.type === "barangay") return "barangay";
  throw new AuthzError("Invalid organization type.", "failed-precondition");
}

function staffRoleForOrgType(orgType: "barangay" | "hospital"): "barangay" | "moph" {
  return orgType === "barangay" ? "barangay" : "moph";
}

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

function assertValidEmail(email: string): string {
  const normalized = normalizeEmail(email);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalized)) {
    throw new AuthzError("Invalid email address.", "invalid-argument");
  }
  return normalized;
}

function assertPasswordPolicy(password: unknown): void {
  if (typeof password !== "string" || password.length < MIN_PASSWORD_LENGTH) {
    throw new AuthzError(
      `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`,
      "invalid-argument",
    );
  }
}

function capabilitiesMatch(
  a: readonly string[],
  b: readonly string[],
): boolean {
  if (a.length !== b.length) return false;
  const setA = new Set(a);
  for (const cap of b) {
    if (!setA.has(cap)) return false;
  }
  return true;
}

export async function runProvisionStaffMember(
  db: Firestore,
  auth: Auth,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const actorUid = assertAuthenticated(authUid);
  const account = await loadAccount(db, actorUid);
  assertPasswordChangeNotRequired(account);
  const orgId = assertNonEmptyString(data.orgId, "orgId");
  const email = assertValidEmail(assertNonEmptyString(data.email, "email"));
  const displayName = assertNonEmptyString(data.displayName, "displayName");
  if (displayName.length < MIN_DISPLAY_NAME_LENGTH) {
    throw new AuthzError(
      `displayName must be at least ${MIN_DISPLAY_NAME_LENGTH} characters.`,
      "invalid-argument",
    );
  }
  assertPasswordPolicy(data.password);

  const { central } = await assertCanManageOrg(db, actorUid, account, orgId);
  const org = await loadOrganization(db, orgId);
  const orgType = orgTypeOf(org);

  let capabilities: string[];
  if (Array.isArray(data.capabilities) && data.capabilities.length) {
    capabilities = data.capabilities.map(String);
  } else {
    capabilities = [...defaultStaffCapabilitiesForOrgType(orgType)];
  }
  assertAssignableCapabilities(central, orgType, capabilities);

  const clientOperationId =
    typeof data.clientOperationId === "string" && data.clientOperationId.trim()
      ? data.clientOperationId.trim()
      : undefined;

  if (clientOperationId) {
    const opSnap = await db
      .collection(IDEMPOTENCY_COLLECTION)
      .doc(clientOperationId)
      .get();
    if (opSnap.exists) {
      const op = opSnap.data()!;
      if (op.orgId === orgId && op.email === email) {
        return {
          accountUid: op.accountUid as string,
          membershipId: op.membershipId as string,
          email,
          idempotentReplay: true,
        };
      }
      throw new AuthzError(
        "clientOperationId already used for a different request.",
        "already-exists",
      );
    }
  }

  let existingAuthUid: string | undefined;
  try {
    const existing = await auth.getUserByEmail(email);
    existingAuthUid = existing.uid;
  } catch (err: unknown) {
    const code = (err as { code?: string }).code;
    if (code !== "auth/user-not-found") {
      throw err;
    }
  }

  if (existingAuthUid) {
    const userSnap = await db.collection("users").doc(existingAuthUid).get();
    if (!userSnap.exists) {
      throw new AuthzError(
        "Email is already registered without a SIBOL profile. Contact support.",
        "already-exists",
      );
    }
    const membershipId = membershipIdFor(orgId, existingAuthUid);
    const membership = await loadMembership(db, membershipId).catch(() => null);
    if (
      membership &&
      membership.orgId === orgId &&
      membership.status === "active" &&
      capabilitiesMatch(membership.capabilities ?? [], capabilities)
    ) {
      return {
        accountUid: existingAuthUid,
        membershipId,
        email,
        idempotentReplay: true,
      };
    }
    throw new AuthzError(
      "An account with this email already exists.",
      "already-exists",
    );
  }

  const password = data.password as string;
  let newUid: string | undefined;

  try {
    const created = await auth.createUser({
      email,
      password,
      displayName,
    });
    newUid = created.uid;

    const role = staffRoleForOrgType(orgType);
    const membershipId = membershipIdFor(orgId, newUid);
    const now = Timestamp.now();

    await db.runTransaction(async (tx) => {
      const userRef = db.collection("users").doc(newUid!);
      const mRef = db.collection("organizationMemberships").doc(membershipId);
      const userSnap = await tx.get(userRef);
      if (userSnap.exists) {
        throw new AuthzError("Account already provisioned.", "already-exists");
      }

      const profile: Record<string, unknown> = {
        role,
        displayName,
        active: true,
        primaryOrgId: orgId,
        createdAt: now,
        updatedAt: now,
      };
      const legacyLabel = (org as { legacyBarangayLabel?: string })
        .legacyBarangayLabel;
      if (orgType === "barangay" && legacyLabel) {
        profile.assignedBarangay = legacyLabel;
      }

      tx.create(userRef, profile);
      tx.create(mRef, {
        membershipId,
        orgId,
        accountUid: newUid,
        status: "active",
        capabilities,
        invitedBy: actorUid,
        approvedBy: actorUid,
        createdAt: now,
        updatedAt: now,
      });

      if (clientOperationId) {
        tx.create(db.collection(IDEMPOTENCY_COLLECTION).doc(clientOperationId), {
          clientOperationId,
          orgId,
          email,
          accountUid: newUid,
          membershipId,
          createdAt: now,
        });
      }
    });

    await writeAuditEvent(db, {
      actorUid,
      operation: "staff_provisioned_direct",
      outcome: "success",
      targetOrgId: orgId,
      targetMembershipId: membershipId,
      targetAccountUid: newUid,
      after: capabilitySnapshot(capabilities),
    });

    return {
      accountUid: newUid,
      membershipId,
      email,
      idempotentReplay: false,
    };
  } catch (err) {
    if (newUid) {
      try {
        await auth.deleteUser(newUid);
      } catch {
        // Best-effort compensation; original error is authoritative.
      }
    }
    throw err;
  }
}
