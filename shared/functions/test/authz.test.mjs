import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  assertActiveAccount,
  assertActiveOrganization,
  assertActiveMembership,
  assertCapability,
  assertContextOrgId,
  AuthzError,
} from "../lib/authz/assert.js";
import { CAPABILITIES } from "../lib/authz/capabilities.js";
import { membershipIdFor } from "../lib/authz/identifiers.js";

const orgId = "org0123456789012345678901";
const uid = "Zgw0Kon5TeenDemoUid1234567890";

describe("authz assert", () => {
  it("membershipIdFor matches shared reg shape", () => {
    assert.equal(membershipIdFor(orgId, uid), `mbr_${orgId}__${uid}`);
  });

  it("assertContextOrgId rejects mismatch", () => {
    assert.throws(
      () => assertContextOrgId(orgId, "org9999999999999999999999"),
      AuthzError,
    );
  });

  it("assertCapability denies admin without case.read", () => {
    const membership = {
      orgId,
      accountUid: uid,
      status: "active",
      capabilities: [CAPABILITIES.ORG_MANAGE_MEMBERS],
    };
    assert.throws(
      () => assertCapability(membership, CAPABILITIES.CASE_READ),
      AuthzError,
    );
  });

  it("assertActiveMembership requires active status", () => {
    assert.throws(
      () =>
        assertActiveMembership(
          { orgId, accountUid: uid, status: "suspended", capabilities: [] },
          orgId,
          uid,
        ),
      AuthzError,
    );
  });

  it("assertActiveAccount", () => {
    assert.throws(() => assertActiveAccount({ active: false }), AuthzError);
  });

  it("assertActiveOrganization", () => {
    assert.throws(() => assertActiveOrganization({ status: "suspended" }), AuthzError);
    assert.throws(() => assertActiveOrganization(undefined), AuthzError);
  });
});
