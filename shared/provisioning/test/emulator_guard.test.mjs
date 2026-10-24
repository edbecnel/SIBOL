import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  assertEmulatorEnvironment,
  EMULATOR_DEMO_PROJECT_ID,
} from "../src/emulator_guard.mjs";

describe("assertEmulatorEnvironment", () => {
  it("rejects when emulator hosts are missing", () => {
    const prevFs = process.env.FIRESTORE_EMULATOR_HOST;
    const prevAuth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
    const prevProject = process.env.FIREBASE_PROJECT_ID;
    delete process.env.FIRESTORE_EMULATOR_HOST;
    delete process.env.FIREBASE_AUTH_EMULATOR_HOST;
    delete process.env.FIREBASE_PROJECT_ID;

    const result = assertEmulatorEnvironment({ confirmFlag: true });
    assert.equal(result.ok, false);

    process.env.FIRESTORE_EMULATOR_HOST = prevFs;
    process.env.FIREBASE_AUTH_EMULATOR_HOST = prevAuth;
    process.env.FIREBASE_PROJECT_ID = prevProject;
  });

  it("accepts configured emulator demo project", () => {
    const prevFs = process.env.FIRESTORE_EMULATOR_HOST;
    const prevAuth = process.env.FIREBASE_AUTH_EMULATOR_HOST;
    const prevProject = process.env.FIREBASE_PROJECT_ID;

    process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
    process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
    process.env.FIREBASE_PROJECT_ID = EMULATOR_DEMO_PROJECT_ID;

    const result = assertEmulatorEnvironment({ confirmFlag: true });
    assert.equal(result.ok, true);
    assert.equal(result.projectId, EMULATOR_DEMO_PROJECT_ID);

    process.env.FIRESTORE_EMULATOR_HOST = prevFs;
    process.env.FIREBASE_AUTH_EMULATOR_HOST = prevAuth;
    process.env.FIREBASE_PROJECT_ID = prevProject;
  });
});
