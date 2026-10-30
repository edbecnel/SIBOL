import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  assertEmulatorEnvironment,
  EMULATOR_DEMO_PROJECT_ID,
  parseEmulatorHostEnv,
} from "../src/emulator_guard.mjs";
import {
  EMULATOR_AUTH_PORT,
  EMULATOR_FIRESTORE_PORT,
} from "../src/emulator_ports.mjs";

function withEnv(overrides, fn) {
  const saved = {};
  for (const key of [
    "FIRESTORE_EMULATOR_HOST",
    "FIREBASE_AUTH_EMULATOR_HOST",
    "FIREBASE_PROJECT_ID",
    "GOOGLE_CLOUD_PROJECT",
  ]) {
    saved[key] = process.env[key];
  }
  Object.assign(process.env, overrides);
  return fn().finally(() => {
    for (const [key, value] of Object.entries(saved)) {
      if (value === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = value;
      }
    }
  });
}

const validEnv = {
  FIRESTORE_EMULATOR_HOST: `127.0.0.1:${EMULATOR_FIRESTORE_PORT}`,
  FIREBASE_AUTH_EMULATOR_HOST: `127.0.0.1:${EMULATOR_AUTH_PORT}`,
  FIREBASE_PROJECT_ID: EMULATOR_DEMO_PROJECT_ID,
};

describe("parseEmulatorHostEnv", () => {
  it("rejects URL-style values", () => {
    const prev = process.env.FIRESTORE_EMULATOR_HOST;
    process.env.FIRESTORE_EMULATOR_HOST = "http://127.0.0.1:8195";
    const parsed = parseEmulatorHostEnv("FIRESTORE_EMULATOR_HOST");
    assert.equal(parsed.invalid, true);
    process.env.FIRESTORE_EMULATOR_HOST = prev;
  });
});

describe("assertEmulatorEnvironment", () => {
  it("rejects when emulator hosts are missing", async () => {
    await withEnv(
      {
        FIRESTORE_EMULATOR_HOST: undefined,
        FIREBASE_AUTH_EMULATOR_HOST: undefined,
        FIREBASE_PROJECT_ID: undefined,
      },
      async () => {
        const result = await assertEmulatorEnvironment({ confirmFlag: true });
        assert.equal(result.ok, false);
      },
    );
  });

  it("accepts configured emulator demo project on canonical ports", async () => {
    await withEnv(validEnv, async () => {
      const result = await assertEmulatorEnvironment({ confirmFlag: true });
      assert.equal(result.ok, true);
      assert.equal(result.projectId, EMULATOR_DEMO_PROJECT_ID);
    });
  });

  it("rejects non-local Firestore host", async () => {
    await withEnv(
      {
        ...validEnv,
        FIRESTORE_EMULATOR_HOST: `example.com:${EMULATOR_FIRESTORE_PORT}`,
      },
      async () => {
        const result = await assertEmulatorEnvironment({ confirmFlag: true });
        assert.equal(result.ok, false);
        assert.match(result.message, /local/);
      },
    );
  });

  it("rejects mismatched Firestore port", async () => {
    await withEnv(
      {
        ...validEnv,
        FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080",
      },
      async () => {
        const result = await assertEmulatorEnvironment({ confirmFlag: true });
        assert.equal(result.ok, false);
        assert.match(result.message, /8080/);
        assert.match(result.message, /8195/);
      },
    );
  });

  it("rejects missing confirm flag", async () => {
    await withEnv(validEnv, async () => {
      const result = await assertEmulatorEnvironment({ confirmFlag: false });
      assert.equal(result.ok, false);
    });
  });

  it("rejects wrong project id", async () => {
    await withEnv(
      { ...validEnv, FIREBASE_PROJECT_ID: "other-project" },
      async () => {
        const result = await assertEmulatorEnvironment({ confirmFlag: true });
        assert.equal(result.ok, false);
      },
    );
  });

  it("rejects production project id sibol-286d0", async () => {
    await withEnv(
      { ...validEnv, FIREBASE_PROJECT_ID: "sibol-286d0" },
      async () => {
        const result = await assertEmulatorEnvironment({ confirmFlag: true });
        assert.equal(result.ok, false);
        assert.match(result.message, /sibol-286d0/);
      },
    );
  });
});
