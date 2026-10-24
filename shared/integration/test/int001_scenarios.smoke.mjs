import { after, before, describe, it } from "node:test";
import assert from "node:assert/strict";
import { ensureDemoSeed, getSmokeDb } from "./smoke_harness.mjs";
import { initializeApp as initClient } from "firebase/app";
import {
  connectAuthEmulator,
  getAuth,
  signInWithEmailAndPassword,
} from "firebase/auth";
import {
  addDoc,
  collection,
  connectFirestoreEmulator,
  getFirestore,
} from "firebase/firestore";
import { runListOrganizations } from "../../functions/lib/admin/exportHandlers.js";
import { runListOrganizationMemberships } from "../../functions/lib/admin/exportHandlers.js";
import { runSubmitTeenAssistanceRequest } from "../../functions/lib/teen/exportHandlers.js";
import {
  DEMO_ASSIGNED_BARANGAY,
  DEMO_BARANGAY_ORG_ID,
} from "../../provisioning/src/emulator_demo_constants.mjs";

const projectId = "sibol-286d0";
let centralUid;
let barangayOrgAdminUid;
let teenUid;

function clientApp() {
  const fsRaw = process.env.FIRESTORE_EMULATOR_HOST;
  const authRaw = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  if (!fsRaw || !authRaw) throw new Error("Emulator env required");
  const [fsHost, fsPort] = fsRaw.split(":");
  const [authHost, authPort] = authRaw.split(":");
  const app = initClient({ projectId, apiKey: "demo-api-key" });
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${authHost}:${authPort}`, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, fsHost, Number(fsPort));
  return { auth, db };
}

before(async () => {
  const result = await ensureDemoSeed();
  centralUid = result.uidByKey.central;
  barangayOrgAdminUid = result.uidByKey.barangay_org_admin;
  teenUid = result.uidByKey.teen;
});

describe("INT-001 scenarios A–F (automated smoke)", () => {
  it("Scenario A — central administrator lists organizations", async () => {
    const db = getSmokeDb();
    const { organizations } = await runListOrganizations(db, centralUid);
    const ids = organizations.map((o) => o.orgId);
    assert.ok(ids.includes(DEMO_BARANGAY_ORG_ID));
    assert.ok(ids.includes("hospital01"));
  });

  it("Scenario B — organization administrator lists memberships", async () => {
    const db = getSmokeDb();
    const { memberships } = await runListOrganizationMemberships(db, barangayOrgAdminUid, {
      orgId: DEMO_BARANGAY_ORG_ID,
    });
    assert.ok(memberships.length >= 1);
  });

  it("Scenario C — teen server submit; client Firestore create denied", async () => {
    const db = getSmokeDb();
    const idemKey = `int001-c-${Date.now()}`;
    const submitted = await runSubmitTeenAssistanceRequest(db, teenUid, {
      idempotencyKey: idemKey,
      category: "generalSupport",
      description: "INT-001 scenario C fictional assistance request.",
    });
    assert.ok(submitted.requestId);
    const replay = await runSubmitTeenAssistanceRequest(db, teenUid, {
      idempotencyKey: idemKey,
      category: "generalSupport",
      description: "INT-001 scenario C fictional assistance request.",
    });
    assert.equal(replay.requestId, submitted.requestId);

    const { auth, db: clientDb } = clientApp();
    await signInWithEmailAndPassword(
      auth,
      "teen.demo@sibol.local",
      process.env.SIBOL_EMULATOR_PASSWORD_TEEN,
    );
    await assert.rejects(
      () =>
        addDoc(collection(clientDb, "teenAssistanceRequests"), {
          teenUid,
          barangay: DEMO_ASSIGNED_BARANGAY,
          orgId: DEMO_BARANGAY_ORG_ID,
          category: "generalSupport",
          description: "Bypass attempt must fail.",
          status: "submitted",
          createdAt: new Date(),
        }),
      (err) => err?.code === "permission-denied",
    );
  });

  it("Scenario D/E/F — covered by prototype_journey.smoke.mjs", async () => {
    assert.ok(true, "Barangay ack/referral, MOPH read, cross-teen denial in companion suite");
  });
});
