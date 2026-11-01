import type { Firestore, Transaction } from "firebase-admin/firestore";
import { Timestamp } from "firebase-admin/firestore";
import {
  TEEN_COMM_COLLECTION,
  TEEN_COMM_IDEMPOTENCY,
  TEEN_COMM_MESSAGES,
  TEEN_COMM_TEMPLATE_VERSION,
  type TeenCommTemplateCodeValue,
  teenCommDisplayText,
} from "./constants";

export type TeenMessageWriteInput = {
  assistanceRequestId: string;
  teenUid: string;
  orgId: string;
  templateCode: TeenCommTemplateCodeValue;
  idempotencyKey: string;
  publisherUid?: string;
  publisherRole: "system" | "barangay";
  caseId?: string;
  threadId?: string;
  createdAt?: Date;
};

export type TeenMessageWriteResult = {
  messageId: string;
  idempotent: boolean;
};

export function teenCommIdempotencyDocId(
  orgId: string,
  idempotencyKey: string,
): string {
  return `${orgId}__${idempotencyKey}`;
}

export function readTeenCommIdempotencyInTransaction(
  tx: Transaction,
  db: Firestore,
  orgId: string,
  idempotencyKey: string,
): Promise<TeenMessageWriteResult | null> {
  return tx
    .get(
      db
        .collection(TEEN_COMM_IDEMPOTENCY)
        .doc(teenCommIdempotencyDocId(orgId, idempotencyKey)),
    )
    .then((snap) => {
      if (!snap.exists) {
        return null;
      }
      const data = snap.data()!;
      return {
        messageId: String(data.messageId ?? ""),
        idempotent: true,
      };
    });
}

export function writeTeenMessageInTransaction(
  tx: Transaction,
  db: Firestore,
  input: TeenMessageWriteInput,
): TeenMessageWriteResult {
  const now = input.createdAt ?? new Date();
  const messageRef = db
    .collection(TEEN_COMM_COLLECTION)
    .doc(input.assistanceRequestId)
    .collection(TEEN_COMM_MESSAGES)
    .doc();
  const messageId = messageRef.id;
  const displayText = teenCommDisplayText(input.templateCode);

  tx.set(messageRef, {
    messageId,
    idempotencyKey: input.idempotencyKey,
    assistanceRequestId: input.assistanceRequestId,
    teenUid: input.teenUid,
    orgId: input.orgId,
    templateCode: input.templateCode,
    templateVersion: TEEN_COMM_TEMPLATE_VERSION,
    displayText,
    createdAt: Timestamp.fromDate(now),
    publisherRole: input.publisherRole,
    ...(input.publisherUid ? { publisherUid: input.publisherUid } : {}),
    ...(input.caseId ? { caseId: input.caseId } : {}),
    ...(input.threadId ? { threadId: input.threadId } : {}),
  });

  tx.set(
    db
      .collection(TEEN_COMM_IDEMPOTENCY)
      .doc(teenCommIdempotencyDocId(input.orgId, input.idempotencyKey)),
    {
      messageId,
      assistanceRequestId: input.assistanceRequestId,
      orgId: input.orgId,
      idempotencyKey: input.idempotencyKey,
      createdAt: Timestamp.fromDate(now),
    },
  );

  return { messageId, idempotent: false };
}
