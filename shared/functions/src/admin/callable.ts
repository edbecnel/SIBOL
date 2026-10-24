import { HttpsError } from "firebase-functions/v2/https";
import { AuthzError } from "../authz/assert";

export function mapAuthzToHttps(err: unknown): never {
  if (err instanceof AuthzError) {
    throw new HttpsError(err.code, err.message);
  }
  throw err;
}

export function emulatorBootstrapAllowed(): boolean {
  return (
    process.env.FUNCTIONS_EMULATOR === "true" ||
    Boolean(process.env.FIRESTORE_EMULATOR_HOST)
  );
}
