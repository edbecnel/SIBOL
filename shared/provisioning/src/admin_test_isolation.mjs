/**
 * Fail-closed guard for Admin SDK in automated tests (not production provisioning).
 */
const PRODUCTION_PROJECT = "sibol-286d0";
const CANONICAL_EMULATOR = "demo-sibol-emulator";

export function assertAdminSdkTestIsolation(options = {}) {
  const { allowAuthorizedProductionReadonly = false } = options;
  const errors = [];

  if (!process.env.FIRESTORE_EMULATOR_HOST?.trim()) {
    errors.push("FIRESTORE_EMULATOR_HOST must be set for Admin SDK tests.");
  } else if (
    !/^(127\.0\.0\.1|localhost|\[::1\]):/.test(
      process.env.FIRESTORE_EMULATOR_HOST.trim(),
    )
  ) {
    errors.push(
      `FIRESTORE_EMULATOR_HOST must be local (${process.env.FIRESTORE_EMULATOR_HOST}).`,
    );
  }

  const project =
    process.env.FIRESTORE_COMPARE_PROJECT ||
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT;

  if (!project) {
    errors.push("Set FIREBASE_PROJECT_ID or FIRESTORE_COMPARE_PROJECT for tests.");
  } else if (project === PRODUCTION_PROJECT) {
    if (
      !allowAuthorizedProductionReadonly ||
      process.env.SIBOL_AUTHORIZED_PRODUCTION_READONLY !== "true"
    ) {
      errors.push(
        `Admin SDK tests must not target production ${PRODUCTION_PROJECT}.`,
      );
    }
  } else if (
    project !== CANONICAL_EMULATOR &&
    !project.startsWith("demo-sibol-")
  ) {
    errors.push(
      `Unexpected test project id ${project}; use ${CANONICAL_EMULATOR} or demo-sibol-* harness.`,
    );
  }

  if (errors.length) {
    throw new Error(`ISOLATION: ${errors.join(" ")}`);
  }

  return { projectId: project };
}
