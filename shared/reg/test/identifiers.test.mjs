import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  DEMO_BARANGAY_ORG_ID,
  DEMO_HOSPITAL_ORG_ID,
  isValidOrgId,
} from "../src/org_id.mjs";
import {
  membershipIdFor,
  parseMembershipId,
  membershipIdMatchesPayload,
} from "../src/membership_id.mjs";
import { validateCapabilityList, hasCapability, CAPABILITIES } from "../src/capabilities.mjs";

const sampleUid = "Zgw0Kon5TeenDemoUid1234567890";
const generatedOrg = "Kx9m2pL8vQ3nRw5yH4jT";

describe("orgId", () => {
  it("accepts canonical demonstration ids", () => {
    assert.equal(isValidOrgId(DEMO_BARANGAY_ORG_ID), true);
    assert.equal(isValidOrgId(DEMO_HOSPITAL_ORG_ID), true);
  });

  it("accepts server-generated firestore document ids", () => {
    assert.equal(isValidOrgId(generatedOrg), true);
  });

  it("rejects empty, path injection, and membership separator", () => {
    assert.equal(isValidOrgId(""), false);
    assert.equal(isValidOrgId("barangay/with/slash"), false);
    assert.equal(isValidOrgId("barangay__bad"), false);
    assert.equal(isValidOrgId("."), false);
    assert.equal(isValidOrgId(".."), false);
  });
});

describe("membershipId", () => {
  it("round-trips for demonstration org", () => {
    const id = membershipIdFor(DEMO_BARANGAY_ORG_ID, sampleUid);
    assert.equal(id, `mbr_barangay03__${sampleUid}`);
    const parsed = parseMembershipId(id);
    assert.deepEqual(parsed, { orgId: DEMO_BARANGAY_ORG_ID, accountUid: sampleUid });
    assert.equal(membershipIdMatchesPayload(id, DEMO_BARANGAY_ORG_ID, sampleUid), true);
  });

  it("round-trips for generated org id", () => {
    const id = membershipIdFor(generatedOrg, sampleUid);
    assert.equal(parseMembershipId(id)?.orgId, generatedOrg);
  });

  it("rejects ambiguous orgId", () => {
    assert.throws(() => membershipIdFor("barangay__bad", sampleUid));
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
