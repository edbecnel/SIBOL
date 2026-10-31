import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { runCreateCoordinationReferral } from "../lib/coordination/createCoordinationReferral.js";
import { minimumStructuredReferral } from "./helpers/structured_referral.mjs";
import {
  membershipDoc,
  orgId,
  otherOrgId,
  seedAcknowledgedAssistance,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";

const projectId = "demo-sibol-coord-fn";
const barangayUid = "barangayStaffUid123456789012";
const teenUid = "teenUserUid123456789012345";
const mophUid = "mophStaffUid1234567890123456";
const otherBnsUid = "otherBarangayStaffUid12345678901";
const assistanceId = "assist-ack-main";
const assistanceUnacked = "assist-sub-1";

let db;

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set by emulators:exec");
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
    primaryOrgId: orgId,
  });
  await db.collection("users").doc(otherBnsUid).set({
    ...userBase,
    role: "barangay",
    assignedBarangay: "Other Demo Barangay",
  });
  await db.collection("users").doc(teenUid).set({ ...userBase, role: "teen" });
  await db.collection("users").doc(mophUid).set({ ...userBase, role: "moph" });

  await seedBaseOrgs(db);
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${barangayUid}`)
    .set(membershipDoc(orgId, barangayUid, ["coordination.barangay"]));
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${otherOrgId}__${otherBnsUid}`)
    .set(membershipDoc(otherOrgId, otherBnsUid, ["coordination.barangay"]));

  await seedAcknowledgedAssistance(db, assistanceId, { teenUid, barangayUid });
  await seedAcknowledgedAssistance(db, assistanceUnacked, {
    teenUid,
    barangayUid,
    status: "submitted",
  });
});

after(async () => {
  for (const app of getApps()) {
    await deleteApp(app);
  }
});

describe("createCoordinationReferral", () => {
  it("succeeds for acknowledged request with structured minimum payload", async () => {
    const result = await runCreateCoordinationReferral(
      db,
      barangayUid,
      minimumStructuredReferral(assistanceId),
    );
    assert.ok(result.threadId);
    assert.match(result.displayRef, /^SIBOL-REF-[A-F0-9]{16}$/);
    assert.equal(result.disclosureMode, "minimum");

    const header = (
      await db.collection("caseCoordinationThreads").doc(result.threadId).get()
    ).data();
    assert.equal(header.barangay, site);
    assert.equal(header.orgId, orgId);
    assert.equal(header.category, "generalSupport");
    assert.equal(header.phase, "referred");
    assert.equal(header.structuredReferral, true);
    assert.ok(!("teenUid" in header));

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
  });

  it("rejects duplicate referral", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          minimumStructuredReferral(assistanceId),
        ),
      (err) => err.code === "failed-precondition",
    );
  });

  it("rejects legacy free-text summary", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, barangayUid, {
          assistanceRequestId: assistanceUnacked,
          barangayReferralSummary: "Legacy summary must not be accepted.",
        }),
      (err) => err.code === "invalid-argument",
    );
  });

  it("rejects unauthenticated", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(db, undefined, minimumStructuredReferral("x")),
      (err) => err.code === "unauthenticated",
    );
  });

  it("rejects teen caller", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          teenUid,
          minimumStructuredReferral(assistanceUnacked),
        ),
      (err) => err.code === "permission-denied",
    );
  });

  it("rejects unacknowledged request", async () => {
    await assert.rejects(
      () =>
        runCreateCoordinationReferral(
          db,
          barangayUid,
          minimumStructuredReferral(assistanceUnacked),
        ),
      (err) => err.code === "failed-precondition",
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
    const payload = minimumStructuredReferral(concurrentId);
    const results = await Promise.allSettled([
      runCreateCoordinationReferral(db, barangayUid, payload),
      runCreateCoordinationReferral(db, barangayUid, payload),
    ]);
    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");
    assert.equal(fulfilled.length, 1);
    assert.equal(rejected.length, 1);
  });
});
