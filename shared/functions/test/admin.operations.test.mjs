import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import {
  runAcceptStaffInvitation,
  runAppointOrganizationAdmin,
  runApproveMembership,
  runBootstrapCentralAdminForEmulator,
  runCreateOrganization,
  runInviteStaffMember,
  runListOrganizationMemberships,
  runRevokeInvitation,
  runReactivateMembership,
  runRevokeMembership,
  runSetOrganizationStatus,
  runSuspendMembership,
  runUpdateMembershipCapabilities,
} from "../lib/admin/exportHandlers.js";
import { CAPABILITIES } from "../lib/authz/capabilities.js";
import { isValidOrgId, membershipIdFor } from "../lib/authz/identifiers.js";
import { generateOrgId } from "../lib/admin/ids.js";

const projectId = "demo-sibol-coord-fn";
const centralUid = "centralAdminUid1234567890123";
const orgAdminUid = "orgAdminStaffUid123456789012";
const staffUid = "staffMemberUid123456789012345";
const outsiderUid = "outsiderStaffUid12345678901234";
const wrongEmailUid = "wrongEmailUserUid1234567890123";

const centralEmail = "central.admin@sibol.local";
const orgAdminEmail = "org.admin@sibol.local";
const staffEmail = "staff.member@sibol.local";
const backupAdminEmail = "backup.admin@sibol.local";

let db;
let orgId;

function expectDenied(fn, code) {
  return assert.rejects(fn, (err) => {
    assert.ok(err instanceof AuthzError);
    if (code) assert.equal(err.code, code);
    return true;
  });
}

async function seedUser(uid, { role, email, isCentralAdmin = false }) {
  await db.collection("users").doc(uid).set({
    role,
    displayName: "Demo",
    active: true,
    createdAt: new Date(),
    ...(isCentralAdmin ? { isCentralAdmin: true } : {}),
  });
}

async function seedOrgAdminMembership(uid, targetOrgId) {
  const membershipId = membershipIdFor(targetOrgId, uid);
  const now = Timestamp.now();
  await db.collection("organizationMemberships").doc(membershipId).set({
    membershipId,
    orgId: targetOrgId,
    accountUid: uid,
    status: "active",
    capabilities: [
      CAPABILITIES.ORG_MANAGE_MEMBERS,
      CAPABILITIES.ORG_MANAGE_ROLES,
      CAPABILITIES.CASE_READ,
    ],
    createdAt: now,
    updatedAt: now,
  });
}

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  await seedUser(centralUid, { role: "barangay", isCentralAdmin: true });
  await seedUser(orgAdminUid, { role: "barangay" });
  await seedUser(staffUid, { role: "barangay" });
  await seedUser(outsiderUid, { role: "barangay" });
  await seedUser(wrongEmailUid, { role: "barangay" });

  const created = await runCreateOrganization(db, centralUid, {
    type: "barangay",
    name: "REG-B Test Barangay",
    initialOrgAdminEmail: orgAdminEmail,
  });
  orgId = created.orgId;
  await runAcceptStaffInvitation(db, orgAdminUid, orgAdminEmail, {
    invitationId: created.invitationId,
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("REG-B admin operations", () => {
  it("generateOrgId produces valid server identifiers without org prefix", () => {
    const id = generateOrgId();
    assert.equal(isValidOrgId(id), true);
    assert.equal(id.startsWith("org"), false);
  });

  it("denies non-central organization creation", async () => {
    await expectDenied(
      () =>
        runCreateOrganization(db, outsiderUid, {
          type: "barangay",
          name: "Illegal Org",
          initialOrgAdminEmail: "x@y.local",
        }),
      "permission-denied",
    );
  });

  it("allows org admin to list memberships in own org", async () => {
    const result = await runListOrganizationMemberships(db, orgAdminUid, { orgId });
    assert.ok(result.memberships.length >= 1);
  });

  it("denies cross-org membership listing", async () => {
    const other = await runCreateOrganization(db, centralUid, {
      type: "hospital",
      name: "Other Hospital",
      initialOrgAdminEmail: backupAdminEmail,
    });
    await expectDenied(
      () => runListOrganizationMemberships(db, orgAdminUid, { orgId: other.orgId }),
      "permission-denied",
    );
  });

  it("invites staff and requires approval", async () => {
    const staffInviteUid = "staffInviteUid12345678901234";
    await seedUser(staffInviteUid, { role: "barangay" });
    const invite = await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: staffEmail,
      capabilities: [CAPABILITIES.CASE_READ],
    });
    const accepted = await runAcceptStaffInvitation(db, staffInviteUid, staffEmail, {
      invitationId: invite.invitationId,
    });
    assert.equal(accepted.status, "pending");
    await expectDenied(
      () =>
        runApproveMembership(db, staffInviteUid, {
          membershipId: accepted.membershipId,
        }),
      "permission-denied",
    );
    const approved = await runApproveMembership(db, orgAdminUid, {
      membershipId: accepted.membershipId,
    });
    assert.equal(approved.status, "active");
  });

  it("denies self capability elevation", async () => {
    const membershipId = membershipIdFor(orgId, orgAdminUid);
    await expectDenied(
      () =>
        runUpdateMembershipCapabilities(db, orgAdminUid, {
          membershipId,
          capabilities: [CAPABILITIES.ORG_MANAGE_MEMBERS, CAPABILITIES.CASE_READ],
        }),
      "permission-denied",
    );
  });

  it("denies org admin granting org management capabilities", async () => {
    const membershipId = membershipIdFor(orgId, "staffInviteUid12345678901234");
    await expectDenied(
      () =>
        runUpdateMembershipCapabilities(db, orgAdminUid, {
          membershipId,
          capabilities: [CAPABILITIES.ORG_MANAGE_MEMBERS, CAPABILITIES.CASE_READ],
        }),
      "permission-denied",
    );
  });

  it("denies duplicate pending invitation", async () => {
    await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: "dup.invite@sibol.local",
    });
    await expectDenied(
      () =>
        runInviteStaffMember(db, orgAdminUid, {
          orgId,
          email: "dup.invite@sibol.local",
        }),
      "already-exists",
    );
  });

  it("denies wrong-recipient invitation acceptance", async () => {
    const invite = await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: "recipient.only@sibol.local",
    });
    await expectDenied(
      () =>
        runAcceptStaffInvitation(db, wrongEmailUid, "wrong@sibol.local", {
          invitationId: invite.invitationId,
        }),
      "permission-denied",
    );
  });

  it("denies revoked invitation acceptance", async () => {
    const invite = await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: "revoked.user@sibol.local",
    });
    await runRevokeInvitation(db, orgAdminUid, { invitationId: invite.invitationId });
    await expectDenied(
      () =>
        runAcceptStaffInvitation(db, staffUid, "revoked.user@sibol.local", {
          invitationId: invite.invitationId,
        }),
      "permission-denied",
    );
  });

  it("denies expired invitation acceptance", async () => {
    const invite = await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: "expired.user@sibol.local",
    });
    await db.collection("organizationStaffInvitations").doc(invite.invitationId).update({
      expiresAt: Timestamp.fromMillis(Date.now() - 1000),
    });
    await expectDenied(
      () =>
        runAcceptStaffInvitation(db, staffUid, "expired.user@sibol.local", {
          invitationId: invite.invitationId,
        }),
      "permission-denied",
    );
  });

  it("denies invitation replay", async () => {
    const replayUid = "replayInviteUid123456789012345";
    await seedUser(replayUid, { role: "barangay" });
    const invite = await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: "replay.user@sibol.local",
    });
    await runAcceptStaffInvitation(db, replayUid, "replay.user@sibol.local", {
      invitationId: invite.invitationId,
    });
    await expectDenied(
      () =>
        runAcceptStaffInvitation(db, replayUid, "replay.user@sibol.local", {
          invitationId: invite.invitationId,
        }),
      "permission-denied",
    );
  });

  it("protects last active organization administrator", async () => {
    const membershipId = membershipIdFor(orgId, orgAdminUid);
    await expectDenied(
      () => runRevokeMembership(db, centralUid, { membershipId }),
      "failed-precondition",
    );
  });

  it("denies suspended organization staff invite", async () => {
    await runSetOrganizationStatus(db, centralUid, { orgId, status: "suspended" });
    await expectDenied(
      () =>
        runInviteStaffMember(db, orgAdminUid, {
          orgId,
          email: "blocked@sibol.local",
        }),
      "permission-denied",
    );
    await runSetOrganizationStatus(db, centralUid, { orgId, status: "active" });
  });

  it("denies approving non-pending membership", async () => {
    const membershipId = membershipIdFor(orgId, "staffInviteUid12345678901234");
    await expectDenied(
      () => runApproveMembership(db, orgAdminUid, { membershipId }),
      "failed-precondition",
    );
  });

  it("writes audit events for organization creation", async () => {
    const snap = await db
      .collection("auditEvents")
      .where("operation", "==", "organization_created")
      .limit(1)
      .get();
    assert.ok(!snap.empty);
    assert.equal(snap.docs[0].data().actorUid, centralUid);
  });

  it("bootstrap central admin only in emulator", async () => {
    const result = await runBootstrapCentralAdminForEmulator(
      db,
      outsiderUid,
      { confirm: true },
      true,
    );
    assert.equal(result.isCentralAdmin, true);
    await expectDenied(
      () =>
        runBootstrapCentralAdminForEmulator(
          db,
          outsiderUid,
          { confirm: true },
          false,
        ),
      "permission-denied",
    );
  });

  it("central admin can appoint backup org admin", async () => {
    const appointed = await runAppointOrganizationAdmin(db, centralUid, {
      orgId,
      email: backupAdminEmail,
    });
    assert.ok(appointed.invitationId);
  });

  it("denies inactive account administration", async () => {
    const inactiveUid = "inactiveAdminUid1234567890123";
    await db.collection("users").doc(inactiveUid).set({
      role: "barangay",
      displayName: "Inactive",
      active: false,
      createdAt: new Date(),
      isCentralAdmin: true,
    });
    await expectDenied(
      () =>
        runCreateOrganization(db, inactiveUid, {
          type: "barangay",
          name: "Inactive Org",
          initialOrgAdminEmail: "x@sibol.local",
        }),
      "permission-denied",
    );
  });

  it("allows only one concurrent invitation acceptance", async () => {
    const concurrentUid = "concurrentAcceptUid1234567890123";
    await seedUser(concurrentUid, { role: "barangay" });
    const invite = await runInviteStaffMember(db, orgAdminUid, {
      orgId,
      email: "concurrent.accept@sibol.local",
    });
    const results = await Promise.allSettled([
      runAcceptStaffInvitation(db, concurrentUid, "concurrent.accept@sibol.local", {
        invitationId: invite.invitationId,
      }),
      runAcceptStaffInvitation(db, concurrentUid, "concurrent.accept@sibol.local", {
        invitationId: invite.invitationId,
      }),
    ]);
    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");
    assert.equal(fulfilled.length, 1);
    assert.equal(rejected.length, 1);
  });

  it("reactivates suspended staff membership", async () => {
    const membershipId = membershipIdFor(orgId, "staffInviteUid12345678901234");
    await runSuspendMembership(db, orgAdminUid, { membershipId });
    const reactivated = await runReactivateMembership(db, orgAdminUid, {
      membershipId,
    });
    assert.equal(reactivated.status, "active");
  });
});
