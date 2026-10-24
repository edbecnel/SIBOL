import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { isValidOrgId } from "../src/org_id.mjs";
import {
  membershipIdFor,
  parseMembershipId,
  membershipIdMatchesPayload,
} from "../src/membership_id.mjs";
import { validateCapabilityList, hasCapability, CAPABILITIES } from "../src/capabilities.mjs";

const sampleOrg = "org0123456789012345678901";
const sampleUid = "Zgw0Kon5TeenDemoUid1234567890";

describe("orgId", () => {
  it("accepts canonical format", () => {
    assert.equal(isValidOrgId(sampleOrg), true);
  });

  it("rejects double underscore and short ids", () => {
    assert.equal(isValidOrgId("org__invalid0000000000000"), false);
    assert.equal(isValidOrgId("orgshort"), false);
  });
});

describe("membershipId", () => {
  it("round-trips", () => {
    const id = membershipIdFor(sampleOrg, sampleUid);
    assert.equal(id, `mbr_${sampleOrg}__${sampleUid}`);
    const parsed = parseMembershipId(id);
    assert.deepEqual(parsed, { orgId: sampleOrg, accountUid: sampleUid });
    assert.equal(membershipIdMatchesPayload(id, sampleOrg, sampleUid), true);
  });

  it("rejects ambiguous orgId", () => {
    assert.throws(() => membershipIdFor("org__bad0000000000000000000", sampleUid));
  });
});

describe("capabilities", () => {
  it("validates closed set", () => {
    assert.deepEqual(validateCapabilityList([CAPABILITIES.ORG_MANAGE_MEMBERS]), []);
    assert.ok(validateCapabilityList(["case.read", "unknown"]).length > 0);
  });

  it("hasCapability", () => {
    assert.equal(hasCapability([CAPABILITIES.CASE_READ], CAPABILITIES.CASE_READ), true);
    assert.equal(
      hasCapability([CAPABILITIES.ORG_MANAGE_MEMBERS], CAPABILITIES.CASE_READ),
      false,
    );
  });
});
