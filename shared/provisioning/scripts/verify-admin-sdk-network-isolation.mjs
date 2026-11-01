#!/usr/bin/env node
/**
 * Gate G — Admin SDK isolation with enforced non-local network denial.
 * Run: node shared/provisioning/scripts/verify-admin-sdk-network-isolation.mjs
 */
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const provisioningRoot = resolve(__dirname, "..");
const denyPreload = resolve(__dirname, "network-deny-nonlocal.mjs");
const worker = resolve(__dirname, "verify-admin-sdk-network-isolation.worker.mjs");

function runWorker(env, label) {
  const result = spawnSync(
    process.execPath,
    ["--import", denyPreload, worker, label],
    {
      cwd: provisioningRoot,
      env: { ...process.env, ...env },
      encoding: "utf8",
    },
  );
  return {
    label,
    status: result.status,
    stdout: result.stdout?.trim() ?? "",
    stderr: result.stderr?.trim() ?? "",
  };
}

const cases = [
  {
    label: "missing-emulator-host",
    env: {
      FIRESTORE_EMULATOR_HOST: "",
      FIREBASE_PROJECT_ID: "demo-sibol-emulator",
    },
    expectStatus: 0,
    expectMarker: "REJECTED_BEFORE_ADMIN_INIT",
  },
  {
    label: "production-project-id",
    env: {
      FIRESTORE_EMULATOR_HOST: "127.0.0.1:8195",
      FIREBASE_PROJECT_ID: "sibol-286d0",
    },
    expectStatus: 0,
    expectMarker: "REJECTED_BEFORE_ADMIN_INIT",
  },
  {
    label: "adc-production-without-emulator",
    env: {
      FIRESTORE_EMULATOR_HOST: "",
      GCLOUD_PROJECT: "sibol-286d0",
      GOOGLE_CLOUD_PROJECT: "sibol-286d0",
    },
    expectStatus: 0,
    expectMarker: "REJECTED_BEFORE_ADMIN_INIT",
  },
  {
    label: "direct-worker-no-wrapper-bypass",
    env: {
      FIRESTORE_EMULATOR_HOST: "127.0.0.1:8195",
      FIREBASE_PROJECT_ID: "sibol-286d0",
      SIBOL_GATE_G_DIRECT: "1",
    },
    expectStatus: 0,
    expectMarker: "REJECTED_BEFORE_ADMIN_INIT",
  },
  {
    label: "valid-emulator-local-only",
    env: {
      FIRESTORE_EMULATOR_HOST: "127.0.0.1:8195",
      FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099",
      FIREBASE_PROJECT_ID: "demo-sibol-emulator",
    },
    expectStatus: 0,
    expectMarker: "LOCAL_EMULATOR_OK",
  },
];

let failed = 0;
for (const c of cases) {
  const out = runWorker(c.env, c.label);
  const combined = `${out.stdout}\n${out.stderr}`;
  if (out.status !== c.expectStatus || !combined.includes(c.expectMarker)) {
    failed += 1;
    console.error(`FAIL Gate G case ${c.label}`);
    console.error(combined);
  } else {
    console.log(`OK Gate G case ${c.label}: ${c.expectMarker}`);
  }
}

if (failed) {
  process.exit(1);
}
console.log("OK: Gate G Admin SDK network-denial verification complete");
