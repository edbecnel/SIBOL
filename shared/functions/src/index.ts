/**
 * SIBOL Cloud Functions — trusted server operations.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { emulatorBootstrapAllowed, mapAuthzToHttps } from "./admin/callable";
import {
  runAcceptStaffInvitation,
  runAppointOrganizationAdmin,
  runApproveMembership,
  runBootstrapCentralAdminForEmulator,
  runCreateOrganization,
  runCreateBarangayOrganization,
  runCreateHospitalOrganization,
  runInviteStaffMember,
  runListMyPendingInvitations,
  runListOrganizationMemberships,
  runListOrganizations,
  runListStaffInvitations,
  runReactivateMembership,
  runRevokeInvitation,
  runRevokeMembership,
  runSetOrganizationStatus,
  runSuspendMembership,
  runUpdateMembershipCapabilities,
} from "./admin/exportHandlers";
import { runCreateCoordinationReferral } from "./coordination/createCoordinationReferral";
import {
  runListBarangayDirectory,
  runRegisterTeenAccount,
} from "./teen/exportHandlers";
import type { RegisterTeenInput } from "./teen/registerTeenAccount";
import { runGetReferenceManifest } from "./geo/referenceManifest";

admin.initializeApp();

function adminCallable<T>(
  handler: (
    db: FirebaseFirestore.Firestore,
    uid: string | undefined,
    email: string | undefined,
    data: Record<string, unknown>,
  ) => Promise<T>,
) {
  return onCall(async (request) => {
    const db = admin.firestore();
    try {
      return await handler(
        db,
        request.auth?.uid,
        request.auth?.token.email as string | undefined,
        (request.data ?? {}) as Record<string, unknown>,
      );
    } catch (err) {
      mapAuthzToHttps(err);
    }
  });
}

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

export const bootstrapCentralAdminForEmulator = onCall(async (request) => {
  const db = admin.firestore();
  try {
    return await runBootstrapCentralAdminForEmulator(
      db,
      request.auth?.uid,
      (request.data ?? {}) as Record<string, unknown>,
      emulatorBootstrapAllowed(),
    );
  } catch (err) {
    mapAuthzToHttps(err);
  }
});

export const regCreateOrganization = adminCallable((db, uid, _email, data) =>
  runCreateOrganization(db, uid, data),
);
export const regCreateBarangayOrganization = adminCallable((db, uid, _email, data) =>
  runCreateBarangayOrganization(db, uid, data),
);
export const regCreateHospitalOrganization = adminCallable((db, uid, _email, data) =>
  runCreateHospitalOrganization(db, uid, data),
);
export const regGetReferenceManifest = onCall(async () => runGetReferenceManifest());
export const regListOrganizations = adminCallable((db, uid) =>
  runListOrganizations(db, uid),
);
export const regSetOrganizationStatus = adminCallable((db, uid, _email, data) =>
  runSetOrganizationStatus(db, uid, data),
);
export const regListOrganizationMemberships = adminCallable(
  (db, uid, _email, data) => runListOrganizationMemberships(db, uid, data),
);
export const regAppointOrganizationAdmin = adminCallable((db, uid, _email, data) =>
  runAppointOrganizationAdmin(db, uid, data),
);
export const regInviteStaffMember = adminCallable((db, uid, _email, data) =>
  runInviteStaffMember(db, uid, data),
);
export const regListStaffInvitations = adminCallable((db, uid, _email, data) =>
  runListStaffInvitations(db, uid, data),
);
export const regAcceptStaffInvitation = adminCallable((db, uid, email, data) =>
  runAcceptStaffInvitation(db, uid, email, data),
);
export const regListMyPendingInvitations = adminCallable((db, uid, email) =>
  runListMyPendingInvitations(db, uid, email),
);
export const regApproveMembership = adminCallable((db, uid, _email, data) =>
  runApproveMembership(db, uid, data),
);
export const regUpdateMembershipCapabilities = adminCallable(
  (db, uid, _email, data) => runUpdateMembershipCapabilities(db, uid, data),
);
export const regSuspendMembership = adminCallable((db, uid, _email, data) =>
  runSuspendMembership(db, uid, data),
);
export const regReactivateMembership = adminCallable((db, uid, _email, data) =>
  runReactivateMembership(db, uid, data),
);
export const regRevokeMembership = adminCallable((db, uid, _email, data) =>
  runRevokeMembership(db, uid, data),
);
export const regRevokeInvitation = adminCallable((db, uid, _email, data) =>
  runRevokeInvitation(db, uid, data),
);

export const regListBarangayDirectory = onCall(async (request) => {
  const db = admin.firestore();
  try {
    return await runListBarangayDirectory(db);
  } catch (err) {
    mapAuthzToHttps(err);
  }
});

export const regRegisterTeenAccount = onCall(async (request) => {
  const db = admin.firestore();
  try {
    return await runRegisterTeenAccount(
      db,
      request.auth?.uid,
      request.auth?.token.email_verified === true,
      (request.data ?? {}) as RegisterTeenInput,
    );
  } catch (err) {
    mapAuthzToHttps(err);
  }
});
