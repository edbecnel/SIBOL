import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from "@firebase/rules-unit-testing";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");

const projectId = "demo-sibol-rules";
const teenUid = "teen-user-1";
const teenUid2 = "teen-user-2";
const barangayUid = "barangay-user-1";
const barangayUidOther = "barangay-user-2";
const DEMO_BARANGAY = "Barangay Tres, Balingasag";
const OTHER_BARANGAY = "Other Demo Barangay";

let testEnv;

function validRequest(overrides = {}) {
  const now = new Date();
  return {
    teenUid,
    barangay: DEMO_BARANGAY,
    category: "generalSupport",
    description: "Fictional demo assistance request text.",
    status: "submitted",
    createdAt: now,
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const userBase = {
      displayName: "Demo",
      active: true,
      createdAt: new Date(),
      assignedBarangay: DEMO_BARANGAY,
    };
    await db.collection("users").doc(teenUid).set({
      ...userBase,
      role: "teen",
    });
    await db.collection("users").doc(teenUid2).set({
      ...userBase,
      role: "teen",
      displayName: "Teen Two",
    });
    await db.collection("users").doc(barangayUid).set({
      ...userBase,
      role: "barangay",
    });
    await db.collection("users").doc(barangayUidOther).set({
      ...userBase,
      role: "barangay",
      assignedBarangay: OTHER_BARANGAY,
      displayName: "Other BNS",
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("teenAssistanceRequests rules", () => {
  it("allows teen to create own request with provisioned barangay", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertSucceeds(
      db.collection("teenAssistanceRequests").doc("req-1").set(validRequest()),
    );
  });

  it("denies teen create with forged barangay", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db
        .collection("teenAssistanceRequests")
        .doc("req-forged-barangay")
        .set(validRequest({ barangay: OTHER_BARANGAY })),
    );
  });

  it("denies teen create with wrong teenUid", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db
        .collection("teenAssistanceRequests")
        .doc("req-bad-owner")
        .set(validRequest({ teenUid: teenUid2 })),
    );
  });

  it("allows teen to read own request", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertSucceeds(
      db.collection("teenAssistanceRequests").doc("req-1").get(),
    );
  });

  it("allows barangay read for assigned site", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertSucceeds(
      db.collection("teenAssistanceRequests").doc("req-1").get(),
    );
  });

  it("denies other barangay site read", async () => {
    const db = testEnv.authenticatedContext(barangayUidOther).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-1").get(),
    );
  });

  it("denies other teen read", async () => {
    const db = testEnv.authenticatedContext(teenUid2).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-1").get(),
    );
  });

  it("allows barangay acknowledge from submitted", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const now = new Date();
    await assertSucceeds(
      db.collection("teenAssistanceRequests").doc("req-1").update({
        status: "acknowledged",
        acknowledgedAt: now,
        acknowledgedByUid: barangayUid,
      }),
    );
  });

  it("denies repeat acknowledge", async () => {
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-1").update({
        status: "acknowledged",
        acknowledgedAt: new Date(),
        acknowledgedByUid: barangayUid,
      }),
    );
  });

  it("denies teen update", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-1").update({
        description: "Changed",
      }),
    );
  });

  it("denies unauthenticated read", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-1").get(),
    );
  });
});
