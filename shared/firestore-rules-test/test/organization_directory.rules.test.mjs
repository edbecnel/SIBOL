import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import { Timestamp } from "firebase/firestore";
import {
  ORG_BARANGAY_DEMO,
  ORG_HOSPITAL_DEMO,
  setupM2DemoAuth,
} from "./helpers/org_auth_seed.mjs";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const barangayUid = "barangay-user-1";
const teenUid = "teen-user-1";
const mophUid = "moph-user-1";

let testEnv;

function directoryDoc(orgId, overrides = {}) {
  const now = Timestamp.now();
  return {
    orgId,
    name: overrides.name ?? "Barangay 3 (Poblacion)",
    type: overrides.type ?? "barangay",
    status: overrides.status ?? "active",
    updatedAt: now,
    ...overrides,
  };
}

async function seedDirectory(db, orgId, overrides = {}) {
  await db.collection("organizationDirectory").doc(orgId).set(directoryDoc(orgId, overrides));
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    const now = new Date();
    const userBase = { active: true, createdAt: now };
    await adminDb.collection("users").doc(teenUid).set({
      ...userBase,
      role: "teen",
      displayName: "Teen Demo",
    });
    await adminDb.collection("users").doc(barangayUid).set({
      ...userBase,
      role: "barangay",
      displayName: "Barangay Demo",
    });
    await adminDb.collection("users").doc(mophUid).set({
      ...userBase,
      role: "moph",
      displayName: "MOPH Demo",
    });
    await setupM2DemoAuth(adminDb, {
      barangayUid,
      teenUid,
      mophUid,
      site: "Barangay 3, Balingasag",
    });
    await seedDirectory(adminDb, ORG_BARANGAY_DEMO, {
      name: "Barangay 3 (Poblacion)",
      geographicSiteLabel: "Barangay 3, Balingasag",
    });
    await seedDirectory(adminDb, ORG_HOSPITAL_DEMO, {
      name: "Misamis Oriental Provincial Hospital",
      type: "hospital",
    });
  });
});

after(async () => {
  await testEnv?.cleanup();
});

describe("organizationDirectory (ORG-NAME-003 A01)", () => {
  it("allows active teen get by orgId", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertSucceeds(db.collection("organizationDirectory").doc(ORG_BARANGAY_DEMO).get());
  });

  it("allows MOPH get barangay directory entry", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertSucceeds(db.collection("organizationDirectory").doc(ORG_BARANGAY_DEMO).get());
  });

  it("denies client list on organizationDirectory", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(db.collection("organizationDirectory").get());
  });

  it("denies client create on organizationDirectory", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("organizationDirectory").doc("neworg01").set(directoryDoc("neworg01")),
    );
  });

  it("allows get for suspended directory status", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await seedDirectory(context.firestore(), ORG_BARANGAY_DEMO, {
        name: "Barangay 3 (Poblacion)",
        status: "suspended",
      });
    });
    const db = testEnv.authenticatedContext(mophUid).firestore();
    const snap = await assertSucceeds(
      db.collection("organizationDirectory").doc(ORG_BARANGAY_DEMO).get(),
    );
    if (!snap.exists) throw new Error("expected doc");
    if (snap.data().status !== "suspended") throw new Error("expected suspended");
  });

  it("does not grant organizations read via directory access", async () => {
    const db = testEnv.authenticatedContext(mophUid).firestore();
    await assertFails(db.collection("organizations").doc(ORG_BARANGAY_DEMO).get());
  });

  it("denies get when organizationDirectory document does not exist", async () => {
    const missingOrgId = "missing01";
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("organizationDirectory").doc(missingOrgId).get(),
    );
  });
});
