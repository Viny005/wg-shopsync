/**
 * Vertrauenswuerdiger Backend-Prozess fuer UC-04 - WG beitreten
 * (siehe docs/spec/S3-inbetriebnahme.md, Abschnitt "WG-Beitritt per
 * Einladungscode" und A09 ADR-08).
 *
 * Die Firestore Security Rules verhindern bewusst, dass ein Client
 * eigenstaendig eine Membership in einer fremden WG erzeugt. Diese
 * Callable Function laeuft mit Firebase-Admin-Rechten und umgeht damit
 * die clientseitigen Rules kontrolliert, nachdem sie den Einladungscode
 * serverseitig validiert hat.
 */

import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions";

initializeApp();
setGlobalOptions({ region: "europe-west3", maxInstances: 10 });

const db = getFirestore();

const INVITE_CODE_PATTERN = /^[A-Z0-9]{6}$/;

interface JoinWgRequestData {
  inviteCode?: unknown;
}

interface JoinWgResponse {
  wgId: string;
  wgName: string;
}

/**
 * Bestimmt den anzuzeigenden Namen des beitretenden Nutzers. Bevorzugt den
 * bereits bestehenden displayName aus einer frueheren Membership desselben
 * Nutzers (Konsistenz ueber mehrere WGs im Zeitverlauf hinweg, siehe
 * WgService._loadOwnDisplayName im Client), sonst faellt auf den in
 * Firebase Authentication hinterlegten Anzeigenamen oder die E-Mail-Adresse
 * zurueck.
 */
async function resolveDisplayName(
  userId: string,
  authDisplayName: string | undefined,
  authEmail: string | undefined,
): Promise<string | null> {
  const priorMemberships = await db
    .collectionGroup("memberships")
    .where("userId", "==", userId)
    .limit(1)
    .get();

  if (!priorMemberships.empty) {
    const priorDisplayName = priorMemberships.docs[0].data().displayName;
    if (typeof priorDisplayName === "string" && priorDisplayName.trim().length > 0) {
      return priorDisplayName;
    }
  }

  if (authDisplayName && authDisplayName.trim().length > 0) {
    return authDisplayName;
  }
  if (authEmail && authEmail.trim().length > 0) {
    return authEmail;
  }
  return null;
}

export const joinWg = onCall<JoinWgRequestData, Promise<JoinWgResponse>>(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Fuer den WG-Beitritt ist eine Anmeldung erforderlich.",
      );
    }

    const userId = request.auth.uid;
    const rawInviteCode = request.data?.inviteCode;

    if (typeof rawInviteCode !== "string") {
      throw new HttpsError(
        "invalid-argument",
        "Es wurde kein Einladungscode uebergeben.",
      );
    }

    const inviteCode = rawInviteCode.trim().toUpperCase();

    if (!INVITE_CODE_PATTERN.test(inviteCode)) {
      throw new HttpsError(
        "invalid-argument",
        "Der Einladungscode muss aus 6 Buchstaben oder Zahlen bestehen.",
      );
    }

    const displayName = await resolveDisplayName(
      userId,
      request.auth.token.name as string | undefined,
      request.auth.token.email as string | undefined,
    );

    const inviteCodeRef = db.collection("inviteCodes").doc(inviteCode);
    const userMembershipRef = db.collection("userMemberships").doc(userId);

    try {
      const result = await db.runTransaction(async (transaction) => {
        const userMembershipSnapshot = await transaction.get(userMembershipRef);

        if (userMembershipSnapshot.exists) {
          throw new HttpsError(
            "already-exists",
            "Du bist bereits Mitglied einer WG.",
          );
        }

        const inviteCodeSnapshot = await transaction.get(inviteCodeRef);

        if (!inviteCodeSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "Keine WG mit diesem Einladungscode gefunden.",
          );
        }

        const inviteCodeData = inviteCodeSnapshot.data();
        const wgId = inviteCodeData?.wgId;

        if (typeof wgId !== "string" || wgId.length === 0) {
          throw new HttpsError(
            "internal",
            "Die Daten des Einladungscodes sind unvollstaendig.",
          );
        }

        const wgRef = db.collection("wgs").doc(wgId);
        const wgSnapshot = await transaction.get(wgRef);

        if (!wgSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "Die WG existiert nicht mehr.",
          );
        }

        const wgData = wgSnapshot.data();
        const wgName = wgData?.name;

        if (typeof wgName !== "string" || wgName.length === 0) {
          throw new HttpsError(
            "internal",
            "Die WG-Daten sind unvollstaendig.",
          );
        }

        const membershipRef = wgRef.collection("memberships").doc(userId);

        transaction.set(membershipRef, {
          id: userId,
          userId,
          wgId,
          role: "member",
          joinedAt: Timestamp.now(),
          ...(displayName ? { displayName } : {}),
        });

        transaction.set(userMembershipRef, {
          wgId,
          inviteCode,
          joinedAt: FieldValue.serverTimestamp(),
        });

        return { wgId, wgName };
      });

      return result;
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError(
        "internal",
        "Der WG-Beitritt ist fehlgeschlagen. Bitte versuche es erneut.",
      );
    }
  },
);