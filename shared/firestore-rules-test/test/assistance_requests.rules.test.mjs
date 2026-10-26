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
  CAPS,
  ORG_BARANGAY_DEMO,
  ORG_BARANGAY_OTHER,
  seedMembership,
  setupM2DemoAuth,
} from "./helpers/org_auth_seed.mjs";

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
    orgId: ORG_BARANGAY_DEMO,
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
    await setupM2DemoAuth(db, {
      barangayUid,
      barangayUid2: barangayUidOther,
      teenUid,
      teenUid2,
      otherSite: OTHER_BARANGAY,
    });
    await db.collection("teenAssistanceRequests").doc("req-1").set(validRequest());
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("teenAssistanceRequests rules", () => {
  it("denies teen client create (server submission required)", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-client-create").set(validRequest()),
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

  it("allows barangay acknowledge for PSGC-aligned barangay label", async () => {
    const site = "Barangay 3, Balingasag";
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("teenAssistanceRequests").doc("req-psgc").set(
        validRequest({
          barangay: site,
          description: "Counseling referral demo request.",
          category: "counselingReferral",
        }),
      );
    });
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const now = new Date();
    await assertSucceeds(
      db.collection("teenAssistanceRequests").doc("req-psgc").update({
        status: "acknowledged",
        acknowledgedAt: now,
        acknowledgedByUid: barangayUid,
      }),
    );
  });

  it("denies org admin without coordination.barangay capability", async () => {
    const adminUid = "barangay-admin-only-uid123456";
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await db.collection("users").doc(adminUid).set({
        role: "barangay",
        displayName: "Org Admin",
        active: true,
        createdAt: new Date(),
        assignedBarangay: DEMO_BARANGAY,
        primaryOrgId: ORG_BARANGAY_DEMO,
      });
      await seedMembership(db, ORG_BARANGAY_DEMO, adminUid, CAPS.orgAdminOnly);
      await db.collection("teenAssistanceRequests").doc("req-admin-deny").set(validRequest());
    });
    const db = testEnv.authenticatedContext(adminUid).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-admin-deny").update({
        status: "acknowledged",
        acknowledgedAt: new Date(),
        acknowledgedByUid: adminUid,
      }),
    );
  });

  it("denies unauthenticated read", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-1").get(),
    );
  });

  it("denies barangay forging submitter identity on acknowledge", async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("teenAssistanceRequests").doc("req-forge-id").set(
        validRequest({
          submitterDisplayName: "Cached Teen",
          submitterAccountEmail: "real@sibol.local",
        }),
      );
    });
    const db = testEnv.authenticatedContext(barangayUid).firestore();
    const now = new Date();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-forge-id").update({
        status: "acknowledged",
        acknowledgedAt: now,
        acknowledgedByUid: barangayUid,
        submitterDisplayName: "Forged Name",
      }),
    );
  });

  it("denies teen client create even with forged identity fields", async () => {
    const db = testEnv.authenticatedContext(teenUid).firestore();
    await assertFails(
      db.collection("teenAssistanceRequests").doc("req-forged-identity").set(
        validRequest({
          submitterDisplayName: "Forged",
          submitterAccountEmail: "fake@sibol.local",
        }),
      ),
    );
  });
});
