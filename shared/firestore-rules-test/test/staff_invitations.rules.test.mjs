import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import {
  initializeTestEnvironment,
  assertFails,
} from "@firebase/rules-unit-testing";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");
const projectId = "demo-sibol-rules-inv";
const uid = "barangayStaffUid123456789012";

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("users").doc(uid).set({
      role: "barangay",
      active: true,
      displayName: "Staff",
      createdAt: new Date(),
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("organizationStaffInvitations (REG-B)", () => {
  it("denies client read and write", async () => {
    const db = testEnv.authenticatedContext(uid).firestore();
    await assertFails(
      db.collection("organizationStaffInvitations").doc("inv_test").get(),
    );
    await assertFails(
      db.collection("organizationStaffInvitations").doc("inv_test").set({
        invitationId: "inv_test",
        orgId: "barangay03",
        status: "pending",
      }),
    );
  });
});
