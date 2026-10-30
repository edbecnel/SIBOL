/**
 * Refuses demo seed/reset unless Firebase Admin targets local emulators.
 * Do not infer safety from project id or ADC alone.
 */
import {
  canonicalAuthEndpoint,
  canonicalFirestoreEndpoint,
  defaultAuthEmulatorHost,
  defaultFirestoreEmulatorHost,
  EMULATOR_AUTH_PORT,
  EMULATOR_FIRESTORE_PORT,
  EMULATOR_PROJECT_ID,
  LOCAL_EMULATOR_HOSTS,
} from "./emulator_ports.mjs";
import { checkTcpReachable } from "./emulator_reachable.mjs";

export { EMULATOR_PROJECT_ID as EMULATOR_DEMO_PROJECT_ID };

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

function assertLocalHost(name, host) {
  if (!LOCAL_EMULATOR_HOSTS.has(host)) {
    return `${name} host must be local (127.0.0.1, localhost, or ::1); got ${host}.`;
  }
  return null;
}

function assertCanonicalPort(name, port, canonicalPort, serviceLabel) {
  if (port !== canonicalPort) {
    return (
      `${name} port ${port} does not match canonical ${serviceLabel} emulator port ${canonicalPort} ` +
      `(see firebase.json and shared/emulator/canonical_ports.json). ` +
      `Unset ${name} to use the default or align your running emulators.`
    );
  }
  return null;
}

/**
 * @param {{ confirmFlag?: boolean, checkReachable?: boolean }} options
 */
export async function assertEmulatorEnvironment(options = {}) {
  const { confirmFlag, checkReachable = false } = options;
  const errors = [];

  if (confirmFlag !== true && confirmFlag !== "true") {
    errors.push(
      "Pass --confirm-emulator-demo to acknowledge emulator-only demonstration seeding.",
    );
  }

  const firestore = parseEmulatorHostEnv("FIRESTORE_EMULATOR_HOST");
  if (!firestore) {
    errors.push(
      `FIRESTORE_EMULATOR_HOST is required (e.g. ${defaultFirestoreEmulatorHost()}).`,
    );
  } else if (firestore.invalid) {
    errors.push(firestore.reason);
  } else {
    const localErr = assertLocalHost("FIRESTORE_EMULATOR_HOST", firestore.host);
    if (localErr) errors.push(localErr);
    const portErr = assertCanonicalPort(
      "FIRESTORE_EMULATOR_HOST",
      firestore.port,
      EMULATOR_FIRESTORE_PORT,
      "Firestore",
    );
    if (portErr) errors.push(portErr);
  }

  const auth = parseEmulatorHostEnv("FIREBASE_AUTH_EMULATOR_HOST");
  if (!auth) {
    errors.push(
      `FIREBASE_AUTH_EMULATOR_HOST is required (e.g. ${defaultAuthEmulatorHost()}).`,
    );
  } else if (auth.invalid) {
    errors.push(auth.reason);
  } else {
    const localErr = assertLocalHost("FIREBASE_AUTH_EMULATOR_HOST", auth.host);
    if (localErr) errors.push(localErr);
    const portErr = assertCanonicalPort(
      "FIREBASE_AUTH_EMULATOR_HOST",
      auth.port,
      EMULATOR_AUTH_PORT,
      "Authentication",
    );
    if (portErr) errors.push(portErr);
  }

  const projectId =
    process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT || null;
  if (!projectId) {
    errors.push("Set FIREBASE_PROJECT_ID to the emulator demo project id.");
  } else if (projectId !== EMULATOR_PROJECT_ID) {
    errors.push(
      `FIREBASE_PROJECT_ID must be ${EMULATOR_PROJECT_ID} for the integrated demo (got ${projectId}).`,
    );
  }

  const PRODUCTION_PROJECT_ID = "sibol-286d0";
  if (projectId === PRODUCTION_PROJECT_ID) {
    errors.push(
      `FIREBASE_PROJECT_ID must not be production ${PRODUCTION_PROJECT_ID} during emulator operations. Use ${EMULATOR_PROJECT_ID}.`,
    );
  }

  if (process.env.GOOGLE_CLOUD_PROJECT && process.env.GOOGLE_CLOUD_PROJECT !== projectId) {
    errors.push("GOOGLE_CLOUD_PROJECT disagrees with FIREBASE_PROJECT_ID.");
  }

  if (errors.length) {
    return { ok: false, message: errors.join(" ") };
  }

  if (checkReachable) {
    const fsCanon = canonicalFirestoreEndpoint();
    const authCanon = canonicalAuthEndpoint();
    const [fsOk, authOk] = await Promise.all([
      checkTcpReachable(firestore.host, firestore.port),
      checkTcpReachable(auth.host, auth.port),
    ]);
    if (!fsOk) {
      errors.push(
        `Firestore emulator not reachable at ${firestore.host}:${firestore.port}. ` +
          `Start: firebase emulators:start --project ${EMULATOR_PROJECT_ID} --only auth,firestore,functions`,
      );
    }
    if (!authOk) {
      errors.push(
        `Auth emulator not reachable at ${auth.host}:${auth.port}.`,
      );
    }
    if (errors.length) {
      return { ok: false, message: errors.join(" ") };
    }
  }

  return {
    ok: true,
    projectId,
    firestoreHost: firestore.host,
    firestorePort: firestore.port,
    authHost: auth.host,
    authPort: auth.port,
  };
}
