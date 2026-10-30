/**
 * Fail-closed guard for Firebase Admin integration tests (emulators:exec harness).
 * Prevents ADC + production project id from targeting live Firestore.
 */
const CANONICAL_EMULATOR_PROJECT = "demo-sibol-emulator";
const PRODUCTION_PROJECT = "sibol-286d0";

export function assertFunctionsIntegrationEmulatorEnv() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error(
      "FIRESTORE_EMULATOR_HOST must be set (run via firebase emulators:exec).",
    );
  }
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    throw new Error(
      "FIREBASE_AUTH_EMULATOR_HOST must be set (run via firebase emulators:exec).",
    );
  }

  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!/^(127\.0\.0\.1|localhost):/.test(host)) {
    throw new Error(
      `FIRESTORE_EMULATOR_HOST must be local (${host}).`,
    );
  }

  const projectId =
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT;

  if (projectId === PRODUCTION_PROJECT) {
    throw new Error(
      `FIREBASE_PROJECT_ID must not be production ${PRODUCTION_PROJECT} during emulator tests.`,
    );
  }
  if (
    projectId &&
    projectId !== CANONICAL_EMULATOR_PROJECT &&
    !projectId.startsWith("demo-sibol-")
  ) {
    throw new Error(
      `FIREBASE_PROJECT_ID must be ${CANONICAL_EMULATOR_PROJECT} or a demo-sibol-* test project (got ${projectId}).`,
    );
  }
}
