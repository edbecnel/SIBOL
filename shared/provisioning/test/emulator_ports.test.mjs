import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  EMULATOR_AUTH_PORT,
  EMULATOR_FIRESTORE_PORT,
  EMULATOR_FUNCTIONS_PORT,
  EMULATOR_PROJECT_ID,
  defaultFirestoreEmulatorHost,
} from "../src/emulator_ports.mjs";

describe("canonical emulator ports", () => {
  it("matches firebase.json local development profile", () => {
    assert.equal(EMULATOR_PROJECT_ID, "demo-sibol-emulator");
    assert.equal(EMULATOR_AUTH_PORT, 9099);
    assert.equal(EMULATOR_FIRESTORE_PORT, 8195);
    assert.equal(EMULATOR_FUNCTIONS_PORT, 5001);
    assert.equal(defaultFirestoreEmulatorHost(), "127.0.0.1:8195");
  });
});
