#!/usr/bin/env node
/**
 * Runs Functions Firestore integration tests inside a dedicated emulator instance.
 * Uses firebase.emulator-functions-test.json (ports 8226/4421/4521) to avoid
 * conflicting with shared/firestore-rules-test (8215/4410/4510).
 */
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { resolve, dirname } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, "../../..");
const config = resolve(repoRoot, "firebase.emulator-functions-test.json");
const firestorePort = 8226;

const command =
  "node --test --test-concurrency=1 test/teen.assignedBarangay.test.mjs test/createCoordinationReferral.test.mjs test/createCoordinationReferral.authz.test.mjs test/admin.operations.test.mjs test/teen.registration.test.mjs test/org_identity.test.mjs test/assistance_submission.test.mjs test/acknowledge_assistance.test.mjs";

const result = spawnSync(
  `firebase emulators:exec --config "${config}" --only firestore --project demo-sibol-coord-fn "${command}"`,
  {
    cwd: resolve(__dirname, ".."),
    stdio: "inherit",
    env: {
      ...process.env,
      FIRESTORE_EMULATOR_HOST: `127.0.0.1:${firestorePort}`,
    },
    shell: true,
  },
);

if (result.error) {
  console.error(result.error);
  process.exit(1);
}
process.exit(result.status ?? 1);
