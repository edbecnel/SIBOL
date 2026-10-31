#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { resolve, dirname } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "../../..");
const config = resolve(repoRoot, "firebase.emulator-functions-test.json");
const firestorePort = 8226;
const authPort = 8227;

if (process.env.FIREBASE_PROJECT_ID === "sibol-286d0") {
  console.error("Refusing consent tests with production project id.");
  process.exit(1);
}

const command =
  "node --test --test-concurrency=1 test/consent_referral.test.mjs test/createCoordinationReferral.test.mjs test/case_lifecycle_flow.test.mjs";

const result = spawnSync(
  `firebase emulators:exec --config "${config}" --only firestore,auth --project demo-sibol-coord-fn "${command}"`,
  {
    cwd: resolve(__dirname, ".."),
    stdio: "inherit",
    env: {
      ...process.env,
      FIRESTORE_EMULATOR_HOST: `127.0.0.1:${firestorePort}`,
      FIREBASE_AUTH_EMULATOR_HOST: `127.0.0.1:${authPort}`,
      FIREBASE_PROJECT_ID: "demo-sibol-coord-fn",
      GCLOUD_PROJECT: "demo-sibol-coord-fn",
      SIBOL_DISCLOSURE_LEGAL_GATE: "true",
    },
    shell: true,
  },
);

process.exit(result.status ?? 1);
