import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { runCreateCoordinationReferral } from "../lib/coordination/createCoordinationReferral.js";

const projectId = "demo-sibol-coord-fn";
const site = "Barangay Tres, Balingasag";
const orgId = "org0123456789012345678901";
const otherOrgId = "org1111111111111111111111";
const barangayUid = "barangayStaffUid123456789012";
const teenUid = "teenUserUid123456789012345";
const mophUid = "mophStaffUid1234567890123456";
const otherBnsUid = "otherBarangayStaffUid12345678901";
const assistanceId = "assist-ack-1";
const assistanceUnacked = "assist-sub-1";

let db;

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8195";
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  const now = Timestamp.now();
  const userBase = {
    displayName: "Demo",
    active: true,
    createdAt: now,
    assignedBarangay: site,
  };
  await db.collection("users").doc(barangayUid).set({
    ...userBase,
    role: "barangay",
  });
  await db.collection("users").doc(otherBnsUid).set({
    ...userBase,
    role: "barangay",
    assignedBarangay: "Other Demo Barangay",
  });
  await db.collection("users").doc(teenUid).set({ ...userBase, role: "teen" });
  await db.collection("users").doc(mophUid).set({ ...userBase, role: "moph" });

  const nowTs = Timestamp.now();
  await db.collection("organizations").doc(orgId).set({
    orgId,
    type: "barangay",
    name: site,
    status: "active",
    createdAt: nowTs,
    updatedAt: nowTs,
  });
  await db.collection("organizations").doc(otherOrgId).set({
    orgId: otherOrgId,
    type: "barangay",
    name: "Other Demo Barangay",
    status: "active",
    createdAt: nowTs,
    updatedAt: nowTs,
  });
  const membership = (oid, uid, caps) => ({
    membershipId: `mbr_${oid}__${uid}`,
    orgId: oid,
    accountUid: uid,
    status: "active",
    capabilities: caps,
    createdAt: nowTs,
    updatedAt: nowTs,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${barangayUid}`)
    .set(membership(orgId, barangayUid, ["coordination.barangay"]));
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${otherOrgId}__${otherBnsUid}`)
    .set(membership(otherOrgId, otherBnsUid, ["coordination.barangay"]));

  const assistanceBase = {
    teenUid,
    barangay: site,
    orgId,
    category: "generalSupport",
    description: "Teen original narrative must not appear on MOPH header.",
    createdAt: now,
  };
  await db.collection("teenAssistanceRequests").doc(assistanceId).set({
    ...assistanceBase,
    status: "acknowledged",
    acknowledgedAt: now,
    acknowledgedByUid: barangayUid,
  });
  await db.collection("teenAssistanceRequests").doc(assistanceUnacked).set({
    ...assistanceBase,
    status: "submitted",
  });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("createCoordinationReferral", () => {
  it("succeeds for acknowledged request", async () => {
    const result = await runCreateCoordinationReferral(db, barangayUid, {
      assistanceRequestId: assistanceId,
      barangayReferralSummary:
        "Fictional barangay summary for MOPH coordination without teen name.",
    });
    assert.ok(result.threadId);
    assert.match(result.displayRef, /^SIBOL-REF-[A-F0-9]{16}$/);
    assert.notEqual(result.displayRef, teenUid);

    const header = (
      await db.collection("caseCoordinationThreads").doc(result.threadId).get()
    ).data();
    assert.equal(header.barangay, site);
    assert.equal(header.orgId, orgId);
    assert.equal(header.category, "generalSupport");
    assert.equal(header.phase, "referred");
    assert.ok(!("teenUid" in header));
    assert.ok(!("description" in header));

    const binding = (
      await db
        .collection("caseCoordinationThreads")
        .doc(result.threadId)
        .collection("private")
        .doc("binding")
        .get()
    ).data();
    assert.equal(binding.teenUid, teenUid);
    assert.equal(binding.assistanceRequestId, assistanceId);

    const registry = (
      await db.collection("barangayCoordinationRegistry").doc(assistanceId).get()
    ).data();
    assert.equal(registry.threadId, result.threadId);
    assert.equal(registry.active, true);
  });

  it("rejects duplicate referral", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: assistanceId,
          barangayReferralSummary:
            "Second attempt should fail for same assistance id.",
        }),
      (err) => err.code === "failed-precondition",
    );
  });

  it("rejects unauthenticated", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, undefined, {
          assistanceRequestId: "x",
          barangayReferralSummary: "Valid length summary here.",
        }),
      (err) => err.code === "unauthenticated",
    );
  });

  it("rejects teen caller", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, teenUid, {
          assistanceRequestId: assistanceUnacked,
          barangayReferralSummary: "Teen must not create referrals ever.",
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects moph caller", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, mophUid, {
          assistanceRequestId: assistanceUnacked,
          barangayReferralSummary: "MOPH must not create referrals ever.",
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects wrong barangay", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, otherBnsUid, {
          assistanceRequestId: assistanceUnacked,
          barangayReferralSummary: "Wrong site barangay cannot refer this case.",
        }),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects unacknowledged request", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: assistanceUnacked,
          barangayReferralSummary: "Cannot refer before acknowledgment step.",
        }),
      (err) => err.code === "failed-precondition",
    );
  });

  it("rejects unknown request", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: "missing-id",
          barangayReferralSummary: "Unknown assistance request identifier.",
        }),
      (err) => err.code === "not-found",
    );
  });

  it("rejects short summary", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: "another-missing",
          barangayReferralSummary: "short",
        }),
      (err) => err.code === "invalid-argument",
    );
  });
});

describe("createCoordinationReferral concurrent duplicate", () => {
  const concurrentId = "assist-concurrent-1";

  before(async () => {
    const now = Timestamp.now();
    await db.collection("teenAssistanceRequests").doc(concurrentId).set({
      teenUid,
      barangay: site,
      orgId,
      category: "healthInformation",
      description: "Concurrent test assistance request.",
      status: "acknowledged",
      createdAt: now,
      acknowledgedAt: now,
      acknowledgedByUid: barangayUid,
    });
  });

  it("allows only one referral under concurrent attempts", async () => {
    const summary =
      "Concurrent duplicate prevention test summary for coordination.";
    const results = await Promise.allSettled([
      runCreateCoordinationReferral(db, barangayUid, {
        assistanceRequestId: concurrentId,
        barangayReferralSummary: summary,
      }),
      runCreateCoordinationReferral(db, barangayUid, {
        assistanceRequestId: concurrentId,
        barangayReferralSummary: summary,
      }),
    ]);
    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");
    assert.equal(fulfilled.length, 1);
    assert.equal(rejected.length, 1);
  });
});
