import { Firestore, Timestamp } from "firebase-admin/firestore";
import { assertActiveAccount, assertAuthenticated, AuthzError } from "../authz/assert";
import { assertCentralAdministrator, loadAccount } from "./context";
import { hashEmail, normalizeEmail } from "./email";
import { generateInvitationId, generateOrgId } from "./ids";
import { INVITATION_TTL_MS, ORG_ADMIN_CAPABILITIES } from "./policy";
import { writeAuditEvent } from "./audit";
import {
  barangayIdentityKey,
  loadPsgcBundle,
  validateBarangaySelection,
} from "../geo/psgc";
import {
  claimIdempotency,
  completeIdempotencyInTransaction,
  idempotencyDocId,
  initIdempotencyInTransaction,
  requestFingerprint,
} from "./idempotency";
import { setOrganizationDirectoryInTransaction } from "./organizationDirectoryProjection";

const INVITATIONS = "organizationStaffInvitations";
const IDENTITY_KEYS = "organizationIdentityKeys";
const IDEMPOTENCY = "organizationCreationIdempotency";

function assertNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || !value.trim()) {
    throw new AuthzError(`${field} is required.`, "invalid-argument");
  }
  return value.trim();
}

export async function runCreateBarangayOrganization(
  db: Firestore,
  authUid: string | undefined,
  data: Record<string, unknown>,
) {
  const uid = assertAuthenticated(authUid);
  const account = await loadAccount(db, uid);
  assertActiveAccount(account);
  assertCentralAdministrator(account);

  const idempotencyKey = assertNonEmptyString(data.idempotencyKey, "idempotencyKey");
  const psgcVersion = assertNonEmptyString(data.psgcVersion, "psgcVersion");
  const psgcRegionCode = assertNonEmptyString(data.psgcRegionCode, "psgcRegionCode");
  const psgcCityMunCode = assertNonEmptyString(data.psgcCityMunCode, "psgcCityMunCode");
  const psgcBarangayCode = assertNonEmptyString(data.psgcBarangayCode, "psgcBarangayCode");
  const initialOrgAdminEmail = assertNonEmptyString(
    data.initialOrgAdminEmail,
    "initialOrgAdminEmail",
  );
  const psgcProvinceCode =
    typeof data.psgcProvinceCode === "string" && data.psgcProvinceCode.trim()
      ? data.psgcProvinceCode.trim()
      : null;
  const displayNameAlias =
    typeof data.displayNameAlias === "string" && data.displayNameAlias.trim()
      ? data.displayNameAlias.trim()
      : undefined;
  const legacyBarangayLabel =
    typeof data.legacyBarangayLabel === "string" && data.legacyBarangayLabel.trim()
      ? data.legacyBarangayLabel.trim()
      : undefined;

  const bundle = loadPsgcBundle(psgcVersion);
  if (bundle.synthetic && psgcBarangayCode.startsWith("SYNTH_") === false) {
    throw new AuthzError(
      "synthetic reference bundle requires SYNTH_ demonstration codes.",
      "invalid-argument",
    );
  }

  const selection = validateBarangaySelection(bundle, {
    psgcVersion,
    psgcRegionCode,
    psgcProvinceCode,
    psgcCityMunCode,
    psgcBarangayCode,
  });
  if (!selection.ok) {
    throw new AuthzError(selection.error, "invalid-argument");
  }

  const barangayNode = selection.nodes.find((n) => n.level === "barangay")!;
  const officialBarangayName = barangayNode.officialName;
  const displayName = displayNameAlias ?? officialBarangayName;

  const fingerprintPayload = {
    operation: "create_barangay_organization",
    psgcVersion,
    psgcRegionCode,
    psgcProvinceCode,
    psgcCityMunCode,
    psgcBarangayCode,
    initialOrgAdminEmail: normalizeEmail(initialOrgAdminEmail),
    displayNameAlias: displayNameAlias ?? null,
    legacyBarangayLabel: legacyBarangayLabel ?? null,
  };
  const fingerprint = requestFingerprint(fingerprintPayload);
  const idemClaim = await claimIdempotency(
    db,
    uid,
    idempotencyKey,
    "create_barangay_organization",
    fingerprint,
  );
  if (idemClaim.replay) {
    return idemClaim.response;
  }

  const identityKey = barangayIdentityKey(psgcBarangayCode);
  const orgId = generateOrgId();
  const now = Timestamp.now();
  const invitationId = generateInvitationId();
  const emailHash = hashEmail(initialOrgAdminEmail);
  const expiresAt = Timestamp.fromMillis(Date.now() + INVITATION_TTL_MS);
  const capabilities = [...ORG_ADMIN_CAPABILITIES];

  const idemRef = db.collection(IDEMPOTENCY).doc(idempotencyDocId(uid, idempotencyKey));

  const denormNames = (level: string) =>
    selection.nodes.find((n) => n.level === level)?.officialName;

  await db.runTransaction(async (tx) => {
    const keyRef = db.collection(IDENTITY_KEYS).doc(identityKey);
    const keySnap = await tx.get(keyRef);
    if (keySnap.exists) {
      throw new AuthzError("Barangay already registered.", "already-exists");
    }

    tx.create(keyRef, {
      identityKey,
      identityKind: "barangay_psgc",
      businessCode: psgcBarangayCode,
      orgId,
      referenceVersion: psgcVersion,
      reservedAt: now,
      createdByUid: uid,
    });

    const orgRef = db.collection("organizations").doc(orgId);
    const orgData = {
      orgId,
      type: "barangay",
      name: displayName,
      status: "active",
      psgcVersion,
      psgcRegionCode,
      ...(psgcProvinceCode ? { psgcProvinceCode } : {}),
      psgcCityMunCode,
      psgcBarangayCode,
      officialBarangayName,
      psgcRegionName: denormNames("region"),
      ...(denormNames("province")
        ? { psgcProvinceName: denormNames("province") }
        : {}),
      psgcCityMunName: denormNames("city_mun"),
      ...(displayNameAlias ? { displayNameAlias } : {}),
      ...(legacyBarangayLabel ? { legacyBarangayLabel } : {}),
      createdAt: now,
      updatedAt: now,
    };
    tx.create(orgRef, orgData);
    setOrganizationDirectoryInTransaction(tx, db, orgId, orgData, now);

    const invRef = db.collection(INVITATIONS).doc(invitationId);
    tx.create(invRef, {
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
      operation: "create_barangay_organization",
      status: "in_progress",
      requestFingerprint: fingerprint,
      createdAt: now,
    });

    const response = {
      orgId,
      invitationId,
      demoInvitationEmail: normalizeEmail(initialOrgAdminEmail),
    };
    completeIdempotencyInTransaction(tx, idemRef, response, now);
  });

  await writeAuditEvent(db, {
    actorUid: uid,
    operation: "organization_created",
    outcome: "success",
    targetOrgId: orgId,
    targetInvitationId: invitationId,
    after: { type: "barangay", psgcBarangayCode, status: "active" },
  });

  return {
    orgId,
    invitationId,
    demoInvitationEmail: normalizeEmail(initialOrgAdminEmail),
  };
}
