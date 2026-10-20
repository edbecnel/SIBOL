import assert from "node:assert/strict";
import { describe, it, beforeEach, afterEach } from "node:test";

import { assertProjectConfirmation } from "../src/config.mjs";
import {
  formatDryRunReport,
  planProvisioningOperations,
  runLocalPreflight,
} from "../src/preflight.mjs";

const ENV_KEYS = [
  "FIREBASE_PROJECT_ID",
  "SIBOL_DEMO_PASSWORD_TEEN",
  "SIBOL_DEMO_PASSWORD_BARANGAY",
  "SIBOL_DEMO_PASSWORD_MOPH",
];

describe("project confirmation", () => {
  it("fails when confirm flag missing", () => {
    const result = assertProjectConfirmation("sibol-286d0", null);
    assert.equal(result.ok, false);
  });

  it("fails on project mismatch", () => {
    const result = assertProjectConfirmation("sibol-286d0", "other-project");
    assert.equal(result.ok, false);
    assert.match(result.message, /mismatch/i);
  });
});

describe("runLocalPreflight", () => {
  const previous = {};

  beforeEach(() => {
    for (const key of ENV_KEYS) {
      previous[key] = process.env[key];
      delete process.env[key];
    }
  });

  afterEach(() => {
    for (const key of ENV_KEYS) {
      if (previous[key] === undefined) {
        delete process.env[key];
      } else {
        process.env[key] = previous[key];
      }
    }
  });

  it("fails when passwords are missing", () => {
    process.env.FIREBASE_PROJECT_ID = "sibol-286d0";
    const result = runLocalPreflight({
      argv: ["--dry-run", "--confirm-project=sibol-286d0"],
      requirePasswords: true,
    });
    assert.equal(result.ok, false);
    assert.equal(result.stage, "credentials");
    assert.match(result.message, /SIBOL_DEMO_PASSWORD_TEEN/);
  });

  it("passes local validation when env is complete", () => {
    process.env.FIREBASE_PROJECT_ID = "sibol-286d0";
    process.env.SIBOL_DEMO_PASSWORD_TEEN = "local-test-secret-teen";
    process.env.SIBOL_DEMO_PASSWORD_BARANGAY = "local-test-secret-barangay";
    process.env.SIBOL_DEMO_PASSWORD_MOPH = "local-test-secret-moph";
    const result = runLocalPreflight({
      argv: ["--dry-run", "--confirm-project=sibol-286d0"],
      requirePasswords: true,
    });
    assert.equal(result.ok, true);
    assert.equal(result.casePlans.length, 5);
  });
});

describe("dry-run operation planning", () => {
  it("skips overwrite when remote case exists", () => {
    process.env.FIREBASE_PROJECT_ID = "sibol-286d0";
    const preflight = runLocalPreflight({
      argv: ["--dry-run", "--confirm-project=sibol-286d0"],
      requirePasswords: false,
    });
    assert.equal(preflight.ok, true);

    const users = preflight.users;
    const operations = planProvisioningOperations({
      users,
      casePlans: preflight.casePlans,
      remoteSnapshot: {
        authByEmail: {
          "teen.demo@sibol.local": { uid: "uid-teen" },
        },
        profiles: {
          "uid-teen": { role: "teen", active: true },
        },
        cases: {
          "demo-case-001": { demoName: "Existing" },
        },
      },
    });

    assert.ok(
      operations.some(
        (o) => o.type === "case_exists" && o.action === "skip_overwrite",
      ),
    );
    assert.ok(
      operations.some(
        (o) => o.type === "auth_user_exists" && o.action === "skip_create_preserve_password",
      ),
    );

    const report = formatDryRunReport(
      { ...preflight, projectId: "sibol-286d0", users },
      operations,
    );
    assert.match(report, /dry-run/i);
    assert.doesNotMatch(report, /local-test-secret/);
  });
});
