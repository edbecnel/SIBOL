export const TARGET_HOSPITAL_ORG_ID = "hospital01";

export const CoordinationStatus = {
  submitted: "submitted",
  received: "received",
  acceptedForCoordination: "acceptedForCoordination",
  additionalInformationRequested: "additionalInformationRequested",
  informationProvided: "informationProvided",
  unableToAccommodate: "unableToAccommodate",
  coordinationCompleted: "coordinationCompleted",
} as const;

export type CoordinationStatusValue =
  (typeof CoordinationStatus)[keyof typeof CoordinationStatus];

export const TERMINAL_COORDINATION_STATUSES: ReadonlySet<string> = new Set([
  CoordinationStatus.unableToAccommodate,
  CoordinationStatus.coordinationCompleted,
]);

export const MOPH_RESPONSE_MIN = 10;
export const MOPH_RESPONSE_MAX = 500;

const MOPH_ALLOWED: Record<string, readonly string[]> = {
  [CoordinationStatus.submitted]: [
    CoordinationStatus.received,
    CoordinationStatus.additionalInformationRequested,
    CoordinationStatus.unableToAccommodate,
  ],
  [CoordinationStatus.received]: [
    CoordinationStatus.acceptedForCoordination,
    CoordinationStatus.additionalInformationRequested,
    CoordinationStatus.unableToAccommodate,
  ],
  [CoordinationStatus.acceptedForCoordination]: [
    CoordinationStatus.coordinationCompleted,
    CoordinationStatus.additionalInformationRequested,
    CoordinationStatus.unableToAccommodate,
  ],
  [CoordinationStatus.additionalInformationRequested]: [],
  [CoordinationStatus.informationProvided]: [
    CoordinationStatus.received,
    CoordinationStatus.acceptedForCoordination,
    CoordinationStatus.unableToAccommodate,
    CoordinationStatus.coordinationCompleted,
  ],
};

export function assertMophTransitionAllowed(
  current: string,
  next: string,
): void {
  const allowed = MOPH_ALLOWED[current];
  if (!allowed || !allowed.includes(next)) {
    throw new Error(
      `Invalid coordination status transition from ${current} to ${next}.`,
    );
  }
}

export function phaseForCoordinationStatus(status: string): string {
  switch (status) {
    case CoordinationStatus.additionalInformationRequested:
      return "awaitingBarangay";
    case CoordinationStatus.informationProvided:
    case CoordinationStatus.received:
    case CoordinationStatus.acceptedForCoordination:
      return "awaitingMoph";
    case CoordinationStatus.unableToAccommodate:
    case CoordinationStatus.coordinationCompleted:
      return "closed";
    default:
      return "referred";
  }
}
