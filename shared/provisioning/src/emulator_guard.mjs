/**
 * Refuses demo seed/reset unless Firebase Admin targets emulators.
 * Do not infer safety from project id alone.
 */
export const EMULATOR_DEMO_PROJECT_ID = "sibol-286d0";

export function parseEmulatorHostEnv(name) {
  const raw = process.env[name];
  if (!raw || !String(raw).trim()) {
    return null;
  }
  const value = String(raw).trim();
  if (value.includes("://")) {
    return { invalid: true, reason: `${name} must be host:port, not a URL` };
  }
  const parts = value.split(":");
  if (parts.length !== 2 || !parts[0] || !parts[1]) {
    return { invalid: true, reason: `${name} must be host:port` };
  }
  const port = Number(parts[1]);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    return { invalid: true, reason: `${name} has invalid port` };
  }
  return { host: parts[0], port };
}

export function assertEmulatorEnvironment({ confirmFlag }) {
  const errors = [];

  if (confirmFlag !== true && confirmFlag !== "true") {
    errors.push(
      "Pass --confirm-emulator-demo to acknowledge emulator-only demonstration seeding.",
    );
  }

  const firestore = parseEmulatorHostEnv("FIRESTORE_EMULATOR_HOST");
  if (!firestore) {
    errors.push("FIRESTORE_EMULATOR_HOST is required (e.g. 127.0.0.1:8080).");
  } else if (firestore.invalid) {
    errors.push(firestore.reason);
  }

  const auth = parseEmulatorHostEnv("FIREBASE_AUTH_EMULATOR_HOST");
  if (!auth) {
    errors.push("FIREBASE_AUTH_EMULATOR_HOST is required (e.g. 127.0.0.1:9099).");
  } else if (auth.invalid) {
    errors.push(auth.reason);
  }

  const projectId =
    process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || null;
  if (!projectId) {
    errors.push("Set FIREBASE_PROJECT_ID to the emulator demo project id.");
  } else if (projectId !== EMULATOR_DEMO_PROJECT_ID) {
    errors.push(
      `FIREBASE_PROJECT_ID must be ${EMULATOR_DEMO_PROJECT_ID} for the integrated demo (got ${projectId}).`,
    );
  }

  if (process.env.GOOGLE_CLOUD_PROJECT && process.env.GOOGLE_CLOUD_PROJECT !== projectId) {
    errors.push("GOOGLE_CLOUD_PROJECT disagrees with FIREBASE_PROJECT_ID.");
  }

  if (errors.length) {
    return { ok: false, message: errors.join(" ") };
  }

  return {
    ok: true,
    projectId,
    firestoreHost: firestore.host,
    authHost: auth.host,
  };
}
