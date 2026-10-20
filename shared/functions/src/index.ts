/**
 * SIBOL Cloud Functions — Tranche 1 stub.
 *
 * Tranche 2 will implement `submitReport` as a trusted callable that:
 * - Verifies the caller is an active barangay user
 * - Validates the case exists and report payload
 * - Writes `reports/{id}` with `reportStatus: submitted` and `acceptedAt`
 * - Updates case `reportStatus` server-side
 *
 * Clients must NOT set MOPH visibility fields directly.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

export const healthCheck = onCall(async () => {
  return { ok: true, service: "sibol-functions", tranche: 1 };
});

export const submitReport = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  // Implemented in Tranche 2 (SIBOL-IMP-002).
  throw new HttpsError(
    "failed-precondition",
    "submitReport is not enabled until Tranche 2 authorization.",
  );
});
