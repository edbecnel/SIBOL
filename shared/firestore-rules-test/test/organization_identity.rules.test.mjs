import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { before, after, describe, it } from "node:test";
import { initializeTestEnvironment, assertFails } from "@firebase/rules-unit-testing";

const rulesPath = resolve(
  fileURLToPath(new URL(".", import.meta.url)),
  "../../../firestore.rules",
);
const rules = readFileSync(rulesPath, "utf8");
const projectId = "demo-sibol-identity-rules";

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: { rules },
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe("organization identity collections", () => {
  it("denies client read/write on organizationIdentityKeys", async () => {
    const ctx = testEnv.authenticatedContext("any-user");
    const db = ctx.firestore();
    const ref = db.collection("organizationIdentityKeys").doc("psgc:barangay:SYNTH_B401");
    await assertFails(ref.set({ orgId: "forged" }));
    await assertFails(ref.get());
  });

  it("denies client read/write on organizationCreationIdempotency", async () => {
    const ctx = testEnv.authenticatedContext("central-admin");
    const db = ctx.firestore();
    const ref = db.collection("organizationCreationIdempotency").doc("uid__key");
    await assertFails(ref.set({ status: "completed" }));
    await assertFails(ref.get());
  });

  it("denies client read/write on assistanceSubmissionIdempotency", async () => {
    const ctx = testEnv.authenticatedContext("teen-user");
    const db = ctx.firestore();
    const ref = db.collection("assistanceSubmissionIdempotency").doc("teen__key");
    await assertFails(ref.set({ status: "completed" }));
    await assertFails(ref.get());
  });
});
