import { HttpsError } from "firebase-functions/v2/https";
import { DisclosureCategoryCodes } from "./categoryCatalog";

export type AuthorizedProfileDocument = Record<string, string>;

function computeAgeFromDob(dateOfBirth: string): string {
  const [y, m, d] = dateOfBirth.split("-").map(Number);
  const today = new Date();
  let age = today.getFullYear() - y;
  const monthDiff = today.getMonth() + 1 - m;
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < d)) {
    age -= 1;
  }
  return String(age);
}

export function buildAuthorizedProfileDocument(
  _teenUid: string,
  teenUser: Record<string, unknown>,
  authorizedCategories: readonly string[],
  otherEssentialJustification?: string,
): AuthorizedProfileDocument {
  const profile: AuthorizedProfileDocument = {};
  for (const code of authorizedCategories) {
    switch (code) {
      case DisclosureCategoryCodes.legalName: {
        const name = teenUser.displayName;
        if (typeof name !== "string" || !name.trim()) {
          throw new HttpsError(
            "failed-precondition",
            "Authorized legal name is unavailable on the teen profile.",
          );
        }
        profile.legalName = name.trim();
        break;
      }
      case DisclosureCategoryCodes.dateOfBirthOrAge: {
        const dob = teenUser.dateOfBirth;
        if (typeof dob !== "string" || !dob.trim()) {
          throw new HttpsError(
            "failed-precondition",
            "Authorized date of birth is unavailable on the teen profile.",
          );
        }
        profile.dateOfBirthOrAge = `${dob.trim()} (age ${computeAgeFromDob(dob.trim())})`;
        break;
      }
      case DisclosureCategoryCodes.contactPhone: {
        const phone = teenUser.contactPhone;
        if (typeof phone !== "string" || !phone.trim()) {
          throw new HttpsError(
            "failed-precondition",
            "Authorized contact phone is unavailable on the teen profile.",
          );
        }
        profile.contactPhone = phone.trim();
        break;
      }
      case DisclosureCategoryCodes.contactEmail: {
        const email = teenUser.contactEmail;
        if (typeof email !== "string" || !email.trim()) {
          throw new HttpsError(
            "failed-precondition",
            "Authorized contact email is unavailable on the teen profile.",
          );
        }
        profile.contactEmail = email.trim();
        break;
      }
      case DisclosureCategoryCodes.otherEssential: {
        const justification = otherEssentialJustification?.trim();
        if (!justification || justification.length < 10 || justification.length > 200) {
          throw new HttpsError(
            "failed-precondition",
            "other_essential requires a stored justification (10–200 characters).",
          );
        }
        profile.otherEssential = justification;
        break;
      }
      default:
        throw new HttpsError(
          "invalid-argument",
          `Unsupported authorized category: ${code}`,
        );
    }
  }
  return profile;
}
