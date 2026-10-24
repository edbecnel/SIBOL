import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const canonicalPath = resolve(__dirname, "../../emulator/canonical_ports.json");
const canonical = JSON.parse(readFileSync(canonicalPath, "utf8"));

export const EMULATOR_PROJECT_ID = canonical.projectId;
export const EMULATOR_AUTH_PORT = canonical.auth.port;
export const EMULATOR_FIRESTORE_PORT = canonical.firestore.port;
export const EMULATOR_FUNCTIONS_PORT = canonical.functions.port;
export const EMULATOR_UI_PORT = canonical.ui.port;

export const LOCAL_EMULATOR_HOSTS = new Set([
  "127.0.0.1",
  "localhost",
  "::1",
]);

export function defaultFirestoreEmulatorHost() {
  return `${canonical.firestore.host}:${canonical.firestore.port}`;
}

export function defaultAuthEmulatorHost() {
  return `${canonical.auth.host}:${canonical.auth.port}`;
}

export function canonicalFirestoreEndpoint() {
  return { host: canonical.firestore.host, port: canonical.firestore.port };
}

export function canonicalAuthEndpoint() {
  return { host: canonical.auth.host, port: canonical.auth.port };
}
