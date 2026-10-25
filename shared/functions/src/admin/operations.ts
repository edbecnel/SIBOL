import { FieldValue, Firestore, Timestamp } from "firebase-admin/firestore";
import {
  assertActiveAccount,
  assertActiveOrganization,
  assertAuthenticated,
  AuthzError,
} from "../authz/assert";
import { membershipIdFor } from "../authz/identifiers";
import {
  capabilitySnapshot,
  membershipAuditSlice,
  writeAuditEvent,
} from "./audit";
import {
  assertCanManageOrg,
  assertCentralAdministrator,
  listMembershipsForOrg,
  loadAccount,
  loadMembership,
  loadOrganization,
} from "./context";
import { hashEmail, normalizeEmail } from "./email";
import { generateInvitationId, generateOrgId } from "./ids";
import { setOrganizationDirectoryInTransaction } from "./organizationDirectoryProjection";
import {
  assertAssignableCapabilities,
  countActiveOrgAdministrators,
  defaultStaffCapabilitiesForOrgType,
  INVITATION_TTL_MS,
  isOrgAdministrator,
  ORG_ADMIN_CAPABILITIES,
} from "./policy";

const INVITATIONS = "organizationStaffInvitations";

function orgTypeOf(
  org: { type?: string },
): "barangay" | "hospital" {
  if (org.type === "hospital") return "hospital";
  if (org.type === "barangay") return "barangay";
  throw new AuthzError("Invalid organization type.", "failed-precondition");
}

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export async function runBootstrapCentralAdminForEmulator(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
  emulatorAllowed: boolean,
) {
  if (!emulatorAllowed) {
    throw new AuthzError(
      "Central Administrator bootstrap is only available in the emulator.",
      "permission-denied",
    );
  }
  const uid = assertAuthenticated(authUid);
  const confirm = data.confirm === true;
  if (!confirm) {
    throw new AuthzError("confirm: true is required.", "invalid-argument");
  }
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  await db.collection("users").doc(uid).update({ isCentralAdmin: true });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "central_admin_bootstrap_emulator",
    outcome: "success",
    targetAccountUid: uid,
    after: { isCentralAdmin: true },
  });
  return { uid, isCentralAdmin: true };
}

export async function runCreateOrganization(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  assertCentralAdministrator(account);

  const type = assertNonEmptyString(data.type, "type");
  if (type !== "barangay" && type !== "hospital") {
    throw new AuthzError("type must be barangay or hospital.", "invalid-argument");
  }
  const name = assertNonEmptyString(data.name, "name");
  const initialOrgAdminEmail = assertNonEmptyString(
    data.initialOrgAdminEmail,
    "initialOrgAdminEmail",
  );
  const legacyBarangayLabel =
    typeof data.legacyBarangayLabel === "string"
      ? data.legacyBarangayLabel.trim()
      : undefined;

  const orgId = generateOrgId();
  const now = Timestamp.now();
  const invitationId = generateInvitationId();
  const emailHash = hashEmail(initialOrgAdminEmail);
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITATION_TTL_MS);
  const capabilities = [...ORG_ADMIN_CAPABILITIES];

  await db.runTransaction(async (tx) => {
    const orgRef = db.collection("organizations").doc(orgId);
    const orgData = {
      orgId,
      type,
      name,
      status: "active",
      ...(legacyBarangayLabel ? { legacyBarangayLabel } : {}),
      createdAt: now,
      updatedAt: now,
    };
    tx.create(orgRef, orgData);
    setOrganizationDirectoryInTransaction(tx, db, orgId, orgData, now);
    const invRef = db.collection(INVITATIONS).doc(invitationId);
    tx.create(invRef, {
      invitationId,
      orgId,
      emailHash,
      status: "pending",
      inviteKind: "org_admin",
      capabilities,
      invitedByUid: uid,
      createdAt: now,
      updatedAt: now,
      expiresAt,
    });
  });

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "organization_created",
    outcome: "success",
    targetOrgId: orgId,
    targetInvitationId: invitationId,
    after: { type, name, status: "active" },
  });

  return {
    orgId,
    invitationId,
    demoInvitationEmail: normalizeEmail(initialOrgAdminEmail),
  };
}

export async function runListOrganizations(
  db: Firestore,
  authUid: string | undefined,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  assertCentralAdministrator(account);

  const snap = await db.collection("organizations").orderBy("name").get();
  return {
    organizations: snap.docs.map((d) => d.data()),
  };
}

export async function runSetOrganizationStatus(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  assertCentralAdministrator(account);

  const orgId = assertNonEmptyString(data.orgId, "orgId");
  const status = assertNonEmptyString(data.status, "status");
  if (status !== "active" && status !== "suspended") {
    throw new AuthzError("status must be active or suspended.", "invalid-argument");
  }
  const org = await loadOrganization(db, orgId);
  const before = { status: org.status };
  const now = Timestamp.now();
  await db.runTransaction(async (tx) => {
    const orgRef = db.collection("organizations").doc(orgId);
    tx.update(orgRef, {
      status,
      updatedAt: FieldValue.serverTimestamp(),
    });
    setOrganizationDirectoryInTransaction(
      tx,
      db,
      orgId,
      { ...org, status },
      now,
    );
  });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "organization_status_changed",
    outcome: "success",
    targetOrgId: orgId,
    before,
    after: { status },
  });
  return { orgId, status };
}

export async function runListOrganizationMemberships(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const orgId = assertNonEmptyString(data.orgId, "orgId");
  await assertCanManageOrg(db, uid, account, orgId);
  const memberships = await listMembershipsForOrg(db, orgId);
  return { memberships };
}

export async function runAppointOrganizationAdmin(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  assertCentralAdministrator(account);

  const orgId = assertNonEmptyString(data.orgId, "orgId");
  const email = assertNonEmptyString(data.email, "email");
  const org = await loadOrganization(db, orgId);
  if (org.status !== "active" && org.status !== "suspended") {
    throw new AuthzError("Organization is not appointable.", "failed-precondition");
  }

  const invitationId = generateInvitationId();
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITATION_TTL_MS);
  const emailHash = hashEmail(email);
  const capabilities = [...ORG_ADMIN_CAPABILITIES];

  const pendingSnap = await db
    .collection(INVITATIONS)
    .where("orgId", "==", orgId)
    .where("emailHash", "==", emailHash)
    .where("status", "==", "pending")
    .limit(1)
    .get();
  if (!pendingSnap.empty) {
    throw new AuthzError("A pending invitation already exists.", "already-exists");
  }

  await db.collection(INVITATIONS).doc(invitationId).create({
    invitationId,
    orgId,
    emailHash,
    status: "pending",
    inviteKind: "org_admin",
    capabilities,
    invitedByUid: uid,
    createdAt: now,
    updatedAt: now,
    expiresAt,
  });

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "org_admin_appointed",
    outcome: "success",
    targetOrgId: orgId,
    targetInvitationId: invitationId,
    after: capabilitySnapshot(capabilities),
  });

  return {
    invitationId,
    orgId,
    demoInvitationEmail: normalizeEmail(email),
  };
}

export async function runInviteStaffMember(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const orgId = assertNonEmptyString(data.orgId, "orgId");
  const email = assertNonEmptyString(data.email, "email");
  const { central } = await assertCanManageOrg(db, uid, account, orgId);
  const org = await loadOrganization(db, orgId);
  const orgType = orgTypeOf(org);

  let capabilities: string[];
  if (Array.isArray(data.capabilities) && data.capabilities.length) {
    capabilities = data.capabilities.map(String);
  } else {
    capabilities = defaultStaffCapabilitiesForOrgType(orgType);
  }
  assertAssignableCapabilities(central, orgType, capabilities);

  const emailHash = hashEmail(email);
  const pendingSnap = await db
    .collection(INVITATIONS)
    .where("orgId", "==", orgId)
    .where("emailHash", "==", emailHash)
    .where("status", "==", "pending")
    .limit(1)
    .get();
  if (!pendingSnap.empty) {
    throw new AuthzError("A pending invitation already exists.", "already-exists");
  }

  const invitationId = generateInvitationId();
  const now = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITATION_TTL_MS);

  await db.collection(INVITATIONS).doc(invitationId).create({
    invitationId,
    orgId,
    emailHash,
    status: "pending",
    inviteKind: "staff",
    capabilities,
    invitedByUid: uid,
    createdAt: now,
    updatedAt: now,
    expiresAt,
  });

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "staff_invited",
    outcome: "success",
    targetOrgId: orgId,
    targetInvitationId: invitationId,
    after: capabilitySnapshot(capabilities),
  });

  return {
    invitationId,
    orgId,
    demoInvitationEmail: normalizeEmail(email),
  };
}

export async function runListStaffInvitations(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const orgId = assertNonEmptyString(data.orgId, "orgId");
  await assertCanManageOrg(db, uid, account, orgId);
  const snap = await db
    .collection(INVITATIONS)
    .where("orgId", "==", orgId)
    .orderBy("createdAt", "desc")
    .get();
  return {
    invitations: snap.docs.map((d) => {
      const row = d.data();
      return {
        invitationId: row.invitationId,
        orgId: row.orgId,
        status: row.status,
        inviteKind: row.inviteKind,
        capabilities: row.capabilities,
        invitedByUid: row.invitedByUid,
        createdAt: row.createdAt,
        expiresAt: row.expiresAt,
        acceptedByUid: row.acceptedByUid ?? null,
      };
    }),
  };
}

export async function runAcceptStaffInvitation(
  db: Firestore,
  authUid: string | undefined,
  authEmail: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  if (!authEmail) {
    throw new AuthzError("Authenticated email required.", "failed-precondition");
  }
  const invitationId = assertNonEmptyString(data.invitationId, "invitationId");
  const emailHash = hashEmail(authEmail);

  const membershipId = await db.runTransaction(async (tx) => {
    const invRef = db.collection(INVITATIONS).doc(invitationId);
    const invSnap = await tx.get(invRef);
    if (!invSnap.exists) {
      throw new AuthzError("Invitation not found.", "not-found");
    }
    const inv = invSnap.data()!;
    if (inv.status === "revoked") {
      throw new AuthzError("Invitation was revoked.", "permission-denied");
    }
    if (inv.status === "accepted") {
      throw new AuthzError("Invitation already used.", "permission-denied");
    }
    if (inv.status !== "pending") {
      throw new AuthzError("Invitation is not pending.", "failed-precondition");
    }
    const expiresAt = inv.expiresAt as Timestamp;
    if (expiresAt.toMillis() < Date.now()) {
      tx.update(invRef, {
        status: "expired",
        updatedAt: FieldValue.serverTimestamp(),
      });
      throw new AuthzError("Invitation expired.", "permission-denied");
    }
    if (inv.emailHash !== emailHash) {
      throw new AuthzError("Invitation is not for this account.", "permission-denied");
    }

    const orgId = inv.orgId as string;
    const orgRef = db.collection("organizations").doc(orgId);
    const orgSnap = await tx.get(orgRef);
    if (!orgSnap.exists || orgSnap.data()?.status !== "active") {
      throw new AuthzError("Organization is not active.", "permission-denied");
    }

    const mId = membershipIdFor(orgId, uid);
    const mRef = db.collection("organizationMemberships").doc(mId);
    const mSnap = await tx.get(mRef);
    if (mSnap.exists) {
      throw new AuthzError("Membership already exists.", "already-exists");
    }

    const now = Timestamp.now();
    const capabilities = inv.capabilities as string[];
    const inviteKind = inv.inviteKind as string;
    const status = inviteKind === "org_admin" ? "active" : "pending";

    tx.create(mRef, {
      membershipId: mId,
      orgId,
      accountUid: uid,
      status,
      capabilities,
      invitedBy: inv.invitedByUid,
      ...(status === "active" ? { approvedBy: inv.invitedByUid } : {}),
      createdAt: now,
      updatedAt: now,
    });

    tx.update(invRef, {
      status: "accepted",
      acceptedByUid: uid,
      acceptedAt: now,
      updatedAt: now,
    });

    if (inviteKind === "org_admin") {
      tx.update(db.collection("users").doc(uid), {
        primaryOrgId: orgId,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    return mId;
  });

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "invitation_accepted",
    outcome: "success",
    targetInvitationId: invitationId,
    targetMembershipId: membershipId,
    targetAccountUid: uid,
  });

  const membership = await loadMembership(db, membershipId);
  return { membershipId, status: membership.status };
}

export async function runApproveMembership(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const membershipId = assertNonEmptyString(data.membershipId, "membershipId");
  const membership = await loadMembership(db, membershipId);
  const orgId = membership.orgId!;
  if (membership.accountUid === uid) {
    throw new AuthzError("Cannot approve your own membership.", "permission-denied");
  }
  await assertCanManageOrg(db, uid, account, orgId);
  if (membership.status !== "pending") {
    throw new AuthzError("Membership is not pending approval.", "failed-precondition");
  }
  const before = membershipAuditSlice(membership);
  await db.collection("organizationMemberships").doc(membershipId).update({
    status: "active",
    approvedBy: uid,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "membership_approved",
    outcome: "success",
    targetOrgId: orgId,
    targetMembershipId: membershipId,
    targetAccountUid: membership.accountUid,
    before,
    after: { status: "active" },
  });
  return { membershipId, status: "active" };
}

export async function runUpdateMembershipCapabilities(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const membershipId = assertNonEmptyString(data.membershipId, "membershipId");
  if (!Array.isArray(data.capabilities)) {
    throw new AuthzError("capabilities array required.", "invalid-argument");
  }
  const capabilities = data.capabilities.map(String);
  const membership = await loadMembership(db, membershipId);
  const orgId = membership.orgId!;
  if (membership.accountUid === uid) {
    throw new AuthzError("Cannot change your own capabilities.", "permission-denied");
  }
  const { central } = await assertCanManageOrg(db, uid, account, orgId);
  const org = await loadOrganization(db, orgId);
  assertAssignableCapabilities(central, orgTypeOf(org), capabilities);

  const orgMemberships = await listMembershipsForOrg(db, orgId);
  const wasAdmin = isOrgAdministrator(membership);
  const willBeAdmin = isOrgAdministrator({
    ...membership,
    status: membership.status,
    capabilities,
  });
  if (wasAdmin && !willBeAdmin) {
    const remaining = countActiveOrgAdministrators(
      orgMemberships.filter((m) => m.membershipId !== membershipId),
    );
    if (remaining < 1) {
      throw new AuthzError(
        "Cannot remove the last Organization Administrator.",
        "failed-precondition",
      );
    }
  }

  const before = membershipAuditSlice(membership);
  await db.collection("organizationMemberships").doc(membershipId).update({
    capabilities,
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "membership_capabilities_updated",
    outcome: "success",
    targetOrgId: orgId,
    targetMembershipId: membershipId,
    before,
    after: capabilitySnapshot(capabilities),
  });
  return { membershipId, capabilities };
}

export async function runSuspendMembership(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  return runMembershipLifecycleUpdate(db, authUid, data, "suspended", "membership_suspended");
}

export async function runReactivateMembership(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const membershipId = assertNonEmptyString(data.membershipId, "membershipId");
  const membership = await loadMembership(db, membershipId);
  const orgId = membership.orgId!;
  await assertCanManageOrg(db, uid, account, orgId);
  if (membership.status !== "suspended") {
    throw new AuthzError("Membership is not suspended.", "failed-precondition");
  }
  const org = await loadOrganization(db, orgId);
  assertActiveOrganization(org);
  const before = membershipAuditSlice(membership);
  await db.collection("organizationMemberships").doc(membershipId).update({
    status: "active",
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "membership_reactivated",
    outcome: "success",
    targetOrgId: orgId,
    targetMembershipId: membershipId,
    before,
    after: { status: "active" },
  });
  return { membershipId, status: "active" };
}

export async function runRevokeMembership(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  return runMembershipLifecycleUpdate(db, authUid, data, "revoked", "membership_revoked");
}

async function runMembershipLifecycleUpdate(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
  targetStatus: "suspended" | "revoked",
  auditOperation: string,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const membershipId = assertNonEmptyString(data.membershipId, "membershipId");
  const membership = await loadMembership(db, membershipId);
  const orgId = membership.orgId!;
  if (membership.accountUid === uid) {
    throw new AuthzError("Cannot change your own membership.", "permission-denied");
  }
  await assertCanManageOrg(db, uid, account, orgId);

  if (isOrgAdministrator(membership) && membership.status === "active") {
    const orgMemberships = await listMembershipsForOrg(db, orgId);
    const remaining = countActiveOrgAdministrators(
      orgMemberships.filter((m) => m.membershipId !== membershipId),
    );
    if (remaining < 1) {
      throw new AuthzError(
        "Cannot remove the last Organization Administrator.",
        "failed-precondition",
      );
    }
  }

  const before = membershipAuditSlice(membership);
  await db.collection("organizationMemberships").doc(membershipId).update({
    status: targetStatus,
    ...(targetStatus === "revoked" ? { revokedAt: FieldValue.serverTimestamp() } : {}),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: auditOperation,
    outcome: "success",
    targetOrgId: orgId,
    targetMembershipId: membershipId,
    before,
    after: { status: targetStatus },
  });
  return { membershipId, status: targetStatus };
}

export async function runRevokeInvitation(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  const invitationId = assertNonEmptyString(data.invitationId, "invitationId");
  const invRef = db.collection(INVITATIONS).doc(invitationId);
  const invSnap = await invRef.get();
  if (!invSnap.exists) {
    throw new AuthzError("Invitation not found.", "not-found");
  }
  const inv = invSnap.data()!;
  await assertCanManageOrg(db, uid, account, inv.orgId as string);
  if (inv.status !== "pending") {
    throw new AuthzError("Only pending invitations can be revoked.", "failed-precondition");
  }
  await invRef.update({
    status: "revoked",
    revokedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "invitation_revoked",
    outcome: "success",
    targetOrgId: inv.orgId,
    targetInvitationId: invitationId,
  });
  return { invitationId, status: "revoked" };
}

export async function runListMyPendingInvitations(
  db: Firestore,
  authUid: string | undefined,
  authEmail: string | undefined,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  if (!authEmail) {
    return { invitations: [] };
  }
  const emailHash = hashEmail(authEmail);
  const snap = await db
    .collection(INVITATIONS)
    .where("emailHash", "==", emailHash)
    .where("status", "==", "pending")
    .get();
  const invitations = [];
  for (const doc of snap.docs) {
    const row = doc.data();
    const expiresAt = row.expiresAt as Timestamp;
    if (expiresAt.toMillis() < Date.now()) continue;
    const org = await loadOrganization(db, row.orgId as string);
    invitations.push({
      invitationId: row.invitationId,
      orgId: row.orgId,
      orgName: org.name,
      inviteKind: row.inviteKind,
      capabilities: row.capabilities,
      expiresAt: row.expiresAt,
    });
  }
  return { invitations };
}
