import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";
import {
  ORG_BARANGAY_DEMO,
  ORG_BARANGAY_OTHER,
  setupM2DemoAuth,
  seedMembership,
  CAPS,
} from "./helpers/org_auth_seed.mjs";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");
const projectId = "demo-sibol-rules-m2-matrix";

const barangayUid = "barangayStaffUid123456789012";
const inactiveUid = "inactiveBarangayUid1234567890";
const centralAdminUid = "centralAdminUid1234567890123";
const DEMO_BARANGAY = "Barangay 3, Balingasag";

let testEnv;

function validCase(overrides = {}) {
  const now = new Date();
  return {
    demoName: "Ana Demo",
    age: 16,
    barangay: DEMO_BARANGAY,
    orgId: ORG_BARANGAY_DEMO,
    caseStatus: "active",
    registeredAt: now,
    createdAt: now,
    updatedAt: now,
    reportStatus: "notSubmitted",
    notes: "Fictional",
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({ projectId, firestore: { rules } });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const base = {
      displayName: "Demo",
      active: true,
      createdAt: new Date(),
      assignedBarangay: DEMO_BARANGAY,
    };
    await db.collection("users").doc(barangayUid).set({ ...base, role: "barangay" });
    await db.collection("users").doc(inactiveUid).set({
      ...base,
      role: "barangay",
      active: false,
    });
    await db.collection("users").doc(centralAdminUid).set({
      ...base,
      role: "barangay",
      isCentralAdmin: true,
    });
    await setupM2DemoAuth(db, { barangayUid });
    await seedMembership(db, ORG_BARANGAY_DEMO, inactiveUid, CAPS.barangayFull);
    await seedMembership(db, ORG_BARANGAY_DEMO, centralAdminUid, [
      "org.manage_members",
    ]);
    await db.collection("cases").doc("case-same-org").set(validCase());
    await db.collection("cases").doc("case-other-org").set(
      validCase({ orgId: ORG_BARANGAY_OTHER }),
    );
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("M2 security matrix (supplemental)", () => {
  it("denies inactive account case read", async () => {
    const db = testEnv.authenticatedContext(inactiveUid).firestore();
    await assertFails(db.collection("cases").doc("case-same-org").get());
  });

  it("denies central admin without case capability", async () => {
    const db = testEnv.authenticatedContext(centralAdminUid).firestore();
    await assertFails(db.collection("cases").doc("case-same-org").get());
  });

  it("denies cross-org case read when membership is only for home org", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(db.collection("cases").doc("case-other-org").get());
  });

  it("denies follow-up read when parent case org not authorized", async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db
        .collection("cases")
        .doc("case-other-org")
        .collection("followUps")
        .doc("fu-1")
        .set({ scheduledAt: new Date(), notes: "x", createdAt: new Date() });
    });
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db
        .collection("cases")
        .doc("case-other-org")
        .collection("followUps")
        .doc("fu-1")
        .get(),
    );
  });

  it("allows same-org case read", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(db.collection("cases").doc("case-same-org").get());
  });
});
