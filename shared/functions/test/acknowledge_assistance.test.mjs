import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { AuthzError } from "../lib/authz/assert.js";
import { runAcknowledgeTeenAssistanceRequest } from "../lib/teen/acknowledgeTeenAssistanceRequest.js";
import {
  membershipDoc,
  orgId,
  seedBaseOrgs,
  site,
} from "./helpers/coordination_seed.mjs";
const projectId = "demo-sibol-ack-assist";
const teenUid = "teenAckAssistUid12345678901";
const barangayUid = "barangayAckAssistUid123456789";
const barangayUid2 = "barangayAckAssistUid223456789";
const requestId = "assist-req-ack-001";

let db;

async function seedSubmittedRequest(id = requestId) {
  const now = Timestamp.now();
  await db.collection("teenAssistanceRequests").doc(id).set({
    teenUid,
    barangay: site,
    orgId,
    category: "generalSupport",
    description: "Fictional assistance request for acknowledgment tests.",
    status: "submitted",
    createdAt: now,
  });
}

async function seedBarangayUser(uid, caps = ["coordination.barangay"]) {
  const now = Timestamp.now();
  await db.collection("users").doc(uid).set({
    role: "barangay",
    displayName: "Barangay Staff",
    active: true,
    assignedBarangay: site,
    primaryOrgId: orgId,
    createdAt: now,
  });
  await db
    .collection("organizationMemberships")
    .doc(`mbr_${orgId}__${uid}`)
    .set(membershipDoc(orgId, uid, caps));
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
  await db.collection("users").doc(teenUid).set({
    role: "teen",
    displayName: "Teen",
    active: true,
    assignedBarangay: site,
    selectedBarangayOrgId: orgId,
    createdAt: Timestamp.now(),
  });
  await seedBarangayUser(barangayUid);
  await seedBarangayUser(barangayUid2);
  await seedSubmittedRequest();
});

after(async () => {
  const apps = getApps();
  if (apps.length) await deleteApp(apps[0]);
});

describe("acknowledge teen assistance idempotency", () => {
  it("acknowledges submitted request exactly once", async () => {
    const key = `ack-${Date.now()}-once`;
    const result = await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: key,
      requestId,
      orgId,
    });
    assert.equal(result.status, "acknowledged");
    assert.equal(result.idempotent, false);
    const snap = await db.collection("teenAssistanceRequests").doc(requestId).get();
    assert.equal(snap.data()?.status, "acknowledged");
    assert.equal(snap.data()?.acknowledgedByUid, barangayUid);
    assert.equal(snap.data()?.acknowledgmentIdempotencyKey, key);
  });

  it("replays the same acknowledgment operation", async () => {
    const id = "assist-req-ack-replay";
    await seedSubmittedRequest(id);
    const key = `ack-replay-${Date.now()}`;
    const first = await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: key,
      requestId: id,
      orgId,
    });
    const second = await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: key,
      requestId: id,
      orgId,
    });
    assert.equal(second.requestId, first.requestId);
    assert.equal(second.idempotent, true);
    const all = await db
      .collection("teenAssistanceRequests")
      .where("acknowledgmentIdempotencyKey", "==", key)
      .get();
    assert.equal(all.size, 1);
  });

  it("conflicts when another actor acknowledged first", async () => {
    const id = "assist-req-ack-conflict";
    await seedSubmittedRequest(id);
    const firstKey = `ack-a-${Date.now()}`;
    await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: firstKey,
      requestId: id,
      orgId,
    });
    await assert.rejects(
      () =>
        runAcknowledgeTeenAssistanceRequest(db, barangayUid2, {
          idempotencyKey: `ack-b-${Date.now()}`,
          requestId: id,
          orgId,
        }),
      (err) =>
        err instanceof AuthzError &&
        err.code === "failed-precondition" &&
        err.message.includes("acknowledgment-conflict"),
    );
  });

  it("conflicts on duplicate operation key after completion by same actor", async () => {
    const id = "assist-req-ack-dup-op";
    await seedSubmittedRequest(id);
    const firstKey = `ack-dup-1-${Date.now()}`;
    await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: firstKey,
      requestId: id,
      orgId,
    });
    await assert.rejects(
      () =>
        runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
          idempotencyKey: `ack-dup-2-${Date.now()}`,
          requestId: id,
          orgId,
        }),
      (err) =>
        err instanceof AuthzError &&
        err.message.includes("acknowledgment-conflict: duplicate"),
    );
  });

  it("resolves to confirmed outcome after lost idempotency replay", async () => {
    const id = "assist-req-ack-lost";
    await seedSubmittedRequest(id);
    const key = `ack-lost-${Date.now()}`;
    const first = await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: key,
      requestId: id,
      orgId,
    });
    await db.collection("assistanceAcknowledgmentIdempotency").doc(`${barangayUid}__${key}`).delete();
    const second = await runAcknowledgeTeenAssistanceRequest(db, barangayUid, {
      idempotencyKey: key,
      requestId: id,
      orgId,
    });
    assert.equal(second.status, "acknowledged");
    assert.equal(second.requestId, first.requestId);
    assert.equal(second.idempotent, true);
  });

  it("denies unauthorized barangay without coordination capability", async () => {
    const id = "assist-req-ack-deny";
    await seedSubmittedRequest(id);
    const noCapUid = "barangayAckNoCapUid12345678901";
    await seedBarangayUser(noCapUid, ["org.administration"]);
    await assert.rejects(
      () =>
        runAcknowledgeTeenAssistanceRequest(db, noCapUid, {
          idempotencyKey: `ack-deny-${Date.now()}`,
          requestId: id,
          orgId,
        }),
      (err) => err instanceof AuthzError && err.code === "permission-denied",
    );
  });
});
