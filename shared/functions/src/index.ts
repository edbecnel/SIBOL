/**
 * SIBOL Cloud Functions — trusted server operations.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { runCreateCoordinationReferral } from "./coordination/createCoordinationReferral";

admin.initializeApp();

export const healthCheck = onCall(async () => {
  return { ok: true, service: "sibol-functions", tranche: 1 };
});

export const submitReport = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  throw new HttpsError(
    "failed-precondition",
    "submitReport is not enabled until Tranche 2 authorization.",
  );
});

export const createCoordinationReferral = onCall(async (request) => {
  const db = admin.firestore();
  return runCreateCoordinationReferral(
    db,
    request.auth?.uid,
    request.data ?? {},
  );
});
