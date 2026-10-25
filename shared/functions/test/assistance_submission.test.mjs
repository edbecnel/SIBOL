import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runSubmitTeenAssistanceRequest } from "../lib/teen/exportHandlers.js";

const projectId = "demo-sibol-assistance-submit";
const teenUid = "teenAssistSubmitUid12345678901";
const orgId = "barangay03";

let db;

before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error("FIRESTORE_EMULATOR_HOST must be set");
  }
  if (getApps().length === 0) {
    initializeApp({ projectId });
  }
  db = getFirestore();
  const now = Timestamp.now();
  await db.collection("organizations").doc(orgId).set({
    orgId,
    type: "barangay",
    name: "Barangay Demo",
    status: "active",
    legacyBarangayLabel: "Barangay Tres, Balingasag",
    createdAt: now,
    updatedAt: now,
  });
  await db.collection("users").doc(teenUid).set({
    role: "teen",
    displayName: "Teen",
    active: true,
    assignedBarangay: "Barangay Tres, Balingasag",
    selectedBarangayOrgId: orgId,
    createdAt: now,
  });
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("teen assistance submission idempotency", () => {
  it("creates assistance request with idempotency key", async () => {
    const key = `assist-${Date.now()}`;
    const result = await runSubmitTeenAssistanceRequest(db, teenUid, {
      idempotencyKey: key,
      category: "generalSupport",
      description: "Fictional assistance request for idempotency test.",
    });
    assert.ok(result.requestId);
    const snap = await db
      .collection("teenAssistanceRequests")
      .doc(result.requestId)
      .get();
    assert.equal(snap.exists, true);
    assert.equal(snap.data()?.teenUid, teenUid);
  });

  it("replays same idempotency key without duplicate document", async () => {
    const key = `assist-replay-${Date.now()}`;
    const first = await runSubmitTeenAssistanceRequest(db, teenUid, {
      idempotencyKey: key,
      category: "generalSupport",
      description: "Fictional assistance replay test payload.",
    });
    const second = await runSubmitTeenAssistanceRequest(db, teenUid, {
      idempotencyKey: key,
      category: "generalSupport",
      description: "Fictional assistance replay test payload.",
    });
    assert.equal(second.requestId, first.requestId);
    const all = await db
      .collection("teenAssistanceRequests")
      .where("submissionIdempotencyKey", "==", key)
      .get();
    assert.equal(all.size, 1);
  });

  it("rejects idempotency key with different payload", async () => {
    const key = `assist-mismatch-${Date.now()}`;
    await runSubmitTeenAssistanceRequest(db, teenUid, {
      idempotencyKey: key,
      category: "generalSupport",
      description: "First fictional assistance payload here.",
    });
    await assert.rejects(
      () =>
        runSubmitTeenAssistanceRequest(db, teenUid, {
          idempotencyKey: key,
          category: "generalSupport",
          description: "Different fictional assistance payload.",
        }),
      (err) => err instanceof AuthzError && err.code === "failed-precondition",
    );
  });
});
