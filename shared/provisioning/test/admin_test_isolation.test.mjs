import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { assertAdminSdkTestIsolation } from "../src/admin_test_isolation.mjs";

function withEnv(overrides, fn) {
  const saved = {};
  for (const key of [
    "FIRESTORE_EMULATOR_HOST",
    "FIREBASE_AUTH_EMULATOR_HOST",
    "FIREBASE_PROJECT_ID",
    "FIRESTORE_COMPARE_PROJECT",
    "SIBOL_AUTHORIZED_PRODUCTION_READONLY",
  ]) {
    saved[key] = process.env[key];
  }
  Object.assign(process.env, overrides);
  return Promise.resolve(fn()).finally(() => {
    for (const [key, value] of Object.entries(saved)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });
}

describe("assertAdminSdkTestIsolation", () => {
  it("rejects missing emulator host", async () => {
    await withEnv({ FIRESTORE_EMULATOR_HOST: undefined }, () => {
      assert.throws(() => assertAdminSdkTestIsolation(), /FIRESTORE_EMULATOR_HOST/);
    });
  });

  it("rejects production project without readonly authorization", async () => {
    await withEnv(
      {
        FIRESTORE_EMULATOR_HOST: "127.0.0.1:8195",
        FIREBASE_PROJECT_ID: "sibol-286d0",
        SIBOL_AUTHORIZED_PRODUCTION_READONLY: undefined,
      },
      () => {
        assert.throws(() => assertAdminSdkTestIsolation(), /sibol-286d0/);
      },
    );
  });

  it("accepts canonical emulator project", async () => {
    await withEnv(
      {
        FIRESTORE_EMULATOR_HOST: "127.0.0.1:8195",
        FIREBASE_PROJECT_ID: "demo-sibol-emulator",
      },
      () => {
        const result = assertAdminSdkTestIsolation();
        assert.equal(result.projectId, "demo-sibol-emulator");
      },
    );
  });
});
