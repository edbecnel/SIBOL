import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runResolveAssistanceRequestSubmitter } from "../lib/teen/resolveAssistanceRequestSubmitter.js";
import { runAcknowledgeTeenAssistanceRequest } from "../lib/teen/acknowledgeTeenAssistanceRequest.js";
import {
  membershipDoc,
  orgId,
  otherOrgId,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-resolve-submitter";
const teenUid = "teenResolveSubmitterUid123456789";
const barangayUid = "barangayResolveSubmitterUid1234567";
const barangayOtherUid = "barangayResolveOtherUid123456789";
const mophUid = "mophResolveSubmitterUid12345678901";
const legacyRequestId = "assist-req-resolve-legacy";

let db;

async function seedBarangayUser(uid, org, caps = ["coordination.barangay"]) {
  const now = Timestamp.now();
  await db.collection("users").doc(uid).set({
    role: "barangay",
    displayName: "Barangay Staff",
    active: true,
    assignedBarangay: site,
    primaryOrgId: org,
    createdAt: now,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${org}__${uid}`)
    .set(membershipDoc(org, uid, caps));
}

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  await seedBaseOrgs(db);
  const now = Timestamp.now();
  await db.collection("users").doc(teenUid).set({
    role: "teen",
    displayName: "Updated Teen Name",
    active: true,
    assignedBarangay: site,
    selectedBarangayOrgId: orgId,
    createdAt: now,
  });
  await seedBarangayUser(barangayUid, orgId);
  await seedBarangayUser(barangayOtherUid, otherOrgId);
  await db.collection("users").doc(mophUid).set({
    role: "moph",
    displayName: "MOPH Staff",
    active: true,
    createdAt: now,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_hospital01__${mophUid}`)
    .set(membershipDoc("hospital01", mophUid, ["coordination.hospital"]));

  await db.collection("teenAssistanceRequests").doc(legacyRequestId).set({
    teenUid,
    barangay: site,
    orgId,
    category: "generalSupport",
    description: "Legacy fictional request without identity snapshot fields.",
    status: "submitted",
    createdAt: now,
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("resolve assistance request submitter", () => {
  it("populates missing snapshot fields for legacy request", async () => {
    const result = await runResolveAssistanceRequestSubmitter(db, barangayUid, {
      requestId: legacyRequestId,
    }, {
      getAccountEmail: async () => "teen.resolve@sibol.local",
    });
    assert.equal(result.requestId, legacyRequestId);
    assert.equal(result.submitterDisplayName, "Updated Teen Name");
    assert.equal(result.submitterAccountEmail, "teen.resolve@sibol.local");
    assert.equal(result.snapshotUpdated, true);
    const snap = await db.collection("teenAssistanceRequests").doc(legacyRequestId).get();
    assert.equal(snap.data()?.submitterDisplayName, "Updated Teen Name");
    assert.equal(snap.data()?.submitterAccountEmail, "teen.resolve@sibol.local");
  });

  it("updates stale snapshot when authoritative identity changed", async () => {
    const requestId = "assist-req-resolve-stale";
    const now = Timestamp.now();
    await db.collection("teenAssistanceRequests").doc(requestId).set({
      teenUid,
      barangay: site,
      orgId,
      category: "generalSupport",
      description: "Fictional request with stale identity snapshot.",
      status: "submitted",
      createdAt: now,
      submitterDisplayName: "Old Name",
      submitterAccountEmail: "old@sibol.local",
    });
    const result = await runResolveAssistanceRequestSubmitter(db, barangayUid, {
      requestId,
    }, {
      getAccountEmail: async () => "teen.resolve@sibol.local",
    });
    assert.equal(result.snapshotUpdated, true);
    assert.equal(result.submitterDisplayName, "Updated Teen Name");
    assert.equal(result.submitterAccountEmail, "teen.resolve@sibol.local");
  });

  it("denies unrelated barangay site", async () => {
    await assert.rejects(
      () =>
        runResolveAssistanceRequestSubmitter(db, barangayOtherUid, {
          requestId: legacyRequestId,
        }),
      (err) => err instanceof AuthzError && err.code === "permission-denied",
    );
  });

  it("denies moph-only user", async () => {
    await assert.rejects(
      () =>
        runResolveAssistanceRequestSubmitter(db, mophUid, {
          requestId: legacyRequestId,
        }),
      (err) => err instanceof AuthzError && err.code === "permission-denied",
    );
  });

  it("denies unauthenticated caller", async () => {
    await assert.rejects(
      () =>
        runResolveAssistanceRequestSubmitter(db, undefined, {
          requestId: legacyRequestId,
        }),
      (err) => err instanceof AuthzError && err.code === "unauthenticated",
    );
  });

  it("handles missing profile name and account email", async () => {
    const orphanTeen = "teenResolveNoProfileUid123456789";
    const requestId = "assist-req-resolve-missing";
    const now = Timestamp.now();
    await db.collection("teenAssistanceRequests").doc(requestId).set({
      teenUid: orphanTeen,
      barangay: site,
      orgId,
      category: "generalSupport",
      description: "Fictional request for missing identity sources.",
      status: "submitted",
      createdAt: now,
    });
    const result = await runResolveAssistanceRequestSubmitter(db, barangayUid, {
      requestId,
    }, {
      getAccountEmail: async () => undefined,
    });
    assert.equal(result.submitterDisplayName, undefined);
    assert.equal(result.submitterAccountEmail, undefined);
    assert.equal(result.snapshotUpdated, false);
  });

  it("does not block acknowledgment after identity refresh", async () => {
    const requestId = "assist-req-resolve-then-ack";
    const now = Timestamp.now();
    await db.collection("teenAssistanceRequests").doc(requestId).set({
      teenUid,
      barangay: site,
      orgId,
      category: "generalSupport",
      description: "Fictional request for ack after identity resolve.",
      status: "submitted",
      createdAt: now,
    });
    await runResolveAssistanceRequestSubmitter(db, barangayUid, { requestId }, {
      getAccountEmail: async () => "teen.resolve@sibol.local",
    });
    const ack = await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: `ack-after-resolve-${Date.now()}`,
      requestId,
      orgId,
    });
    assert.equal(ack.status, "acknowledged");
    const snap = await db.collection("teenAssistanceRequests").doc(requestId).get();
    assert.equal(snap.data()?.status, "acknowledged");
    assert.equal(snap.data()?.submitterDisplayName, "Updated Teen Name");
  });
});
