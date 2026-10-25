import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import assert from "node:assert/strict";
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
const orgA = "barangay03";
const orgB = "org9876543210987654321098";
const staffUid = "barangayStaffUid123456789012";
const otherUid = "otherStaffUid123456789012345";
const teenUid = "teen-user-1";

function membershipId(orgId, uid) {
  return `mbr_${orgId}__${uid}`;
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = new Date();

    await db.collection("users").doc(staffUid).set({
      role: "barangay",
      displayName: "Staff",
      active: true,
      createdAt: now,
    });
    await db.collection("users").doc(otherUid).set({
      role: "barangay",
      displayName: "Other",
      active: true,
      createdAt: now,
    });
    await db.collection("users").doc(teenUid).set({
      role: "teen",
      displayName: "Teen",
      active: true,
      createdAt: now,
    });

    await db.collection("organizations").doc(orgA).set({
      orgId: orgA,
      type: "barangay",
      name: "Demo Barangay A",
      status: "active",
      createdAt: now,
      updatedAt: now,
    });
    await db.collection("organizations").doc(orgB).set({
      orgId: orgB,
      type: "barangay",
      name: "Demo Barangay B",
      status: "active",
      createdAt: now,
      updatedAt: now,
    });
    const suspendedOrg = "orgsuspend0000000000000001";
    await db.collection("organizations").doc(suspendedOrg).set({
      orgId: suspendedOrg,
      type: "barangay",
      name: "Suspended Org",
      status: "suspended",
      createdAt: now,
      updatedAt: now,
    });

    await db
      .collection("organizationMemberships")
      .doc(membershipId(orgA, staffUid))
      .set({
        membershipId: membershipId(orgA, staffUid),
        orgId: orgA,
        accountUid: staffUid,
        status: "active",
        capabilities: ["case.read", "org.manage_members"],
        createdAt: now,
        updatedAt: now,
      });

    await db
      .collection("organizationMemberships")
      .doc(membershipId(orgB, otherUid))
      .set({
        membershipId: membershipId(orgB, otherUid),
        orgId: orgB,
        accountUid: otherUid,
        status: "active",
        capabilities: ["case.read"],
        createdAt: now,
        updatedAt: now,
      });

    await db
      .collection("organizationMemberships")
      .doc(membershipId(orgA, otherUid))
      .set({
        membershipId: membershipId(orgA, otherUid),
        orgId: orgA,
        accountUid: otherUid,
        status: "suspended",
        capabilities: ["case.read"],
        createdAt: now,
        updatedAt: now,
      });

    await db.collection("auditEvents").doc("audit-1").set({
      eventType: "test",
      createdAt: now,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("organizations (REG-A)", () => {
  it("allows read with active membership and active org", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertSucceeds(db.collection("organizations").doc(orgA).get());
  });

  it("denies read for org without membership", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(db.collection("organizations").doc(orgB).get());
  });

  it("denies read for suspended organization", async () => {
    const db = testEnv.authenticatedContext(otherUid).firestore();
    const suspendedOrg = "orgsuspend0000000000000001";
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection("organizationMemberships")
        .doc(membershipId(suspendedOrg, otherUid))
        .set({
          membershipId: membershipId(suspendedOrg, otherUid),
          orgId: suspendedOrg,
          accountUid: otherUid,
          status: "active",
          capabilities: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        });
    });
    const staffDb = testEnv.authenticatedContext(otherUid).firestore();
    await assertFails(staffDb.collection("organizations").doc(suspendedOrg).get());
  });

  it("denies client create and update", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(
      db.collection("organizations").doc("org9999999999999999999991").set({
        orgId: "org9999999999999999999991",
        type: "barangay",
        name: "Hack",
        status: "active",
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });
});

describe("organizationMemberships (REG-A)", () => {
  it("allows user to read own membership", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertSucceeds(
      db.collection("organizationMemberships").doc(membershipId(orgA, staffUid)).get(),
    );
  });

  it("denies collection query by accountUid (Flutter legacy shape)", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(
      db
        .collection("organizationMemberships")
        .where("accountUid", "==", staffUid)
        .get(),
    );
  });

  it("denies reading membership with malformed document id", async () => {
    const badId = "mbr_not_canonical_doc_id_1234567890";
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection("organizationMemberships").doc(badId).set({
        membershipId: badId,
        orgId: orgA,
        accountUid: staffUid,
        status: "active",
        capabilities: ["case.read"],
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(db.collection("organizationMemberships").doc(badId).get());
  });

  it("denies reading another user membership", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(
      db.collection("organizationMemberships").doc(membershipId(orgB, otherUid)).get(),
    );
  });

  it("denies suspended membership org read", async () => {
    const db = testEnv.authenticatedContext(otherUid).firestore();
    await assertFails(db.collection("organizations").doc(orgA).get());
  });

  it("denies client membership write and privilege escalation", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(
      db.collection("organizationMemberships").doc(membershipId(orgA, staffUid)).update({
        capabilities: ["case.read", "case.write", "org.manage_members"],
      }),
    );
  });
});

describe("auditEvents (REG-A)", () => {
  it("denies client read and write", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(db.collection("auditEvents").doc("audit-1").get());
    await assertFails(
      db.collection("auditEvents").doc("audit-2").set({ eventType: "hack" }),
    );
  });
});

describe("users isCentralAdmin (REG-A)", () => {
  it("denies client setting isCentralAdmin", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(
      db.collection("users").doc(staffUid).update({ isCentralAdmin: true }),
    );
  });
});

describe("capabilityGranted helper exposure", () => {
  it("admin membership without case.read does not grant org B access", async () => {
    const db = testEnv.authenticatedContext(staffUid).firestore();
    await assertFails(db.collection("organizations").doc(orgB).get());
  });
});
