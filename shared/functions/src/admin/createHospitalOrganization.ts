import { Firestore, Timestamp } from "firebase-admin/firestore";
import { assertActiveAccount, assertAuthenticated, AuthzError } from "../authz/assert";
import { assertCentralAdministrator, loadAccount } from "./context";
import { hashEmail, normalizeEmail } from "./email";
import { generateInvitationId, generateOrgId } from "./ids";
import { INVITATION_TTL_MS, ORG_ADMIN_CAPABILITIES } from "./policy";
import { writeAuditEvent } from "./audit";
import { loadPsgcBundle, validateBarangaySelection } from "../geo/psgc";
import {
  hospitalIdentityKey,
  loadNhfrBundle,
  validateHospitalFacility,
} from "../geo/nhfr";
import {
  claimIdempotency,
  completeIdempotencyInTransaction,
  idempotencyDocId,
  initIdempotencyInTransaction,
  requestFingerprint,
} from "./idempotency";

const INVITATIONS = "organizationStaffInvitations";
const IDENTITY_KEYS = "organizationIdentityKeys";
const IDEMPOTENCY = "organizationCreationIdempotency";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export async function runCreateHospitalOrganization(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  assertCentralAdministrator(account);

  const idempotencyKey = assertNonEmptyString(data.idempotencyKey, "idempotencyKey");
  const nhfrSnapshotVersion = assertNonEmptyString(
    data.nhfrSnapshotVersion,
    "nhfrSnapshotVersion",
  );
  const nhfrFacilityCode = assertNonEmptyString(data.nhfrFacilityCode, "nhfrFacilityCode");
  const psgcVersion = assertNonEmptyString(data.psgcVersion, "psgcVersion");
  const psgcRegionCode = assertNonEmptyString(data.psgcRegionCode, "psgcRegionCode");
  const psgcCityMunCode = assertNonEmptyString(data.psgcCityMunCode, "psgcCityMunCode");
  const initialOrgAdminEmail = assertNonEmptyString(
    data.initialOrgAdminEmail,
    "initialOrgAdminEmail",
  );
  const psgcProvinceCode =
    typeof data.psgcProvinceCode === "string" && data.psgcProvinceCode.trim()
      ? data.psgcProvinceCode.trim()
      : null;
  const psgcBarangayCode =
    typeof data.psgcBarangayCode === "string" && data.psgcBarangayCode.trim()
      ? data.psgcBarangayCode.trim()
      : null;

  const nhfrBundle = loadNhfrBundle(nhfrSnapshotVersion);
  const facilityResult = validateHospitalFacility(nhfrBundle, nhfrFacilityCode);
  if (!facilityResult.ok) {
    throw new AuthzError(facilityResult.error, "invalid-argument");
  }
  const facility = facilityResult.row;

  if (psgcBarangayCode) {
    const psgcBundle = loadPsgcBundle(psgcVersion);
    const sel = validateBarangaySelection(psgcBundle, {
      psgcVersion,
      psgcRegionCode,
      psgcProvinceCode,
      psgcCityMunCode,
      psgcBarangayCode,
    });
    if (!sel.ok) {
      throw new AuthzError(sel.error, "invalid-argument");
    }
  } else {
    const psgcBundle = loadPsgcBundle(psgcVersion);
    const byCode = new Map(psgcBundle.nodes.map((n) => [n.code, n]));
    const city = byCode.get(psgcCityMunCode);
    const region = byCode.get(psgcRegionCode);
    if (!city || city.level !== "city_mun" || !region || region.level !== "region") {
      throw new AuthzError("invalid geographic selection.", "invalid-argument");
    }
  }

  const displayNameAlias =
    typeof data.displayNameAlias === "string" && data.displayNameAlias.trim()
      ? data.displayNameAlias.trim()
      : undefined;
  const displayName = displayNameAlias ?? facility.facilityOfficialName;

  const fingerprint = requestFingerprint({
    operation: "create_hospital_organization",
    nhfrSnapshotVersion,
    nhfrFacilityCode,
    psgcVersion,
    psgcRegionCode,
    psgcProvinceCode,
    psgcCityMunCode,
    psgcBarangayCode,
    initialOrgAdminEmail: normalizeEmail(initialOrgAdminEmail),
    displayNameAlias: displayNameAlias ?? null,
  });

  const idemClaim = await claimIdempotency(
    db,
    uid,
    idempotencyKey,
    "create_hospital_organization",
    fingerprint,
  );
  if (idemClaim.replay) {
    return idemClaim.response;
  }

  const identityKey = hospitalIdentityKey(nhfrFacilityCode);
  const orgId = generateOrgId();
  const now = Timestamp.now();
  const invitationId = generateInvitationId();
  const emailHash = hashEmail(initialOrgAdminEmail);
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITATION_TTL_MS);
  const capabilities = [...ORG_ADMIN_CAPABILITIES];
  const idemRef = db.collection(IDEMPOTENCY).doc(idempotencyDocId(uid, idempotencyKey));

  await db.runTransaction(async (tx) => {
    const keyRef = db.collection(IDENTITY_KEYS).doc(identityKey);
    if ((await tx.get(keyRef)).exists) {
      throw new AuthzError("Hospital already registered.", "already-exists");
    }
    tx.create(keyRef, {
      identityKey,
      identityKind: "hospital_nhfr",
      businessCode: nhfrFacilityCode,
      orgId,
      referenceVersion: nhfrSnapshotVersion,
      reservedAt: now,
      createdByUid: uid,
    });
    const orgRef = db.collection("organizations").doc(orgId);
    tx.create(orgRef, {
      orgId,
      type: "hospital",
      name: displayName,
      status: "active",
      nhfrSnapshotVersion,
      nhfrFacilityCode,
      facilityOfficialName: facility.facilityOfficialName,
      psgcVersion,
      psgcRegionCode,
      ...(psgcProvinceCode ? { psgcProvinceCode } : {}),
      psgcCityMunCode,
      ...(psgcBarangayCode ? { psgcBarangayCode } : {}),
      ...(displayNameAlias ? { displayNameAlias } : {}),
      createdAt: now,
      updatedAt: now,
    });
    tx.create(db.collection(INVITATIONS).doc(invitationId), {
      invitationId,
      orgId,
      emailHash,
      status: "pending",
      inviteKind: "org_admin",
      capabilities,
      invitedByUid: uid,
      createdAt: now,
      updatedAt: now,
      expiresAt,
    });
    initIdempotencyInTransaction(tx, idemRef, {
      idempotencyKey,
      centralAdminUid: uid,
      operation: "create_hospital_organization",
      status: "in_progress",
      requestFingerprint: fingerprint,
      createdAt: now,
    });
    completeIdempotencyInTransaction(tx, idemRef, {
      orgId,
      invitationId,
      demoInvitationEmail: normalizeEmail(initialOrgAdminEmail),
    }, now);
  });

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "organization_created",
    outcome: "success",
    targetOrgId: orgId,
    targetInvitationId: invitationId,
    after: { type: "hospital", nhfrFacilityCode, status: "active" },
  });

  return {
    orgId,
    invitationId,
    demoInvitationEmail: normalizeEmail(initialOrgAdminEmail),
  };
}
