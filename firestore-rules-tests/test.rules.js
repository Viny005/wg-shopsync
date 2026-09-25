const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');
const { setLogLevel } = require('firebase/firestore');
const { serverTimestamp } = require('firebase/firestore');

let testEnv;

before(async function () {
  this.timeout(20000);
  setLogLevel('error');
  testEnv = await initializeTestEnvironment({
    projectId: 'wg-shopsync-rules-test',
    firestore: {
      rules: fs.readFileSync(
        path.resolve(__dirname, '..', 'firestore.rules'),
        'utf8'
      ),
      host: '127.0.0.1',
      port: 8181,
    },
  });
});

after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

const WG_ID = 'wg-1';
const USER_A = 'user-a';
const USER_B = 'user-b';
const USER_C = 'user-c';
const EXPENSE_ID = 'expense-1';

async function seedBaseState() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.collection('wgs').doc(WG_ID).set({
      name: 'Test WG',
      inviteCode: 'ABC123',
      createdBy: USER_A,
      createdAt: new Date(),
    });
    for (const uid of [USER_A, USER_B, USER_C]) {
      await db
        .collection('wgs')
        .doc(WG_ID)
        .collection('memberships')
        .doc(uid)
        .set({
          userId: uid,
          wgId: WG_ID,
          role: uid === USER_A ? 'admin' : 'member',
          joinedAt: new Date(),
        });
    }
    await db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID)
      .set({
        wgId: WG_ID,
        amount: 20,
        description: 'Testausgabe',
        paidBy: USER_A,
        shoppingItemId: null,
        receiptUrl: null,
        createdAt: new Date(),
        updatedAt: serverTimestamp(),
      });
    await db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID)
      .collection('expenseShares')
      .doc(USER_B)
      .set({
        expenseId: EXPENSE_ID,
        userId: USER_B,
        shareAmount: 10,
      });
    await db
      .collection('wgs')
      .doc(WG_ID)
      .collection('debts')
      .doc(`${EXPENSE_ID}_${USER_B}`)
      .set({
        wgId: WG_ID,
        expenseId: EXPENSE_ID,
        creditorId: USER_A,
        debtorId: USER_B,
        amount: 10,
        status: 'open',
        paidAt: null,
        createdAt: new Date(),
      });
  });
}

function ctxAs(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}


describe('UC-13 Firestore Rules - Debt read security', () => {
  beforeEach(seedBaseState);

  it('Glaeubiger kann eigene Debt lesen', async () => {
    const db = ctxAs(USER_A);
    await assertSucceeds(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .get()
    );
  });

  it('Schuldner kann eigene Debt lesen', async () => {
    const db = ctxAs(USER_B);
    await assertSucceeds(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .get()
    );
  });

  it('unbeteiligtes WG-Mitglied kann Debt NICHT lesen', async () => {
    const db = ctxAs(USER_C);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .get()
    );
  });

  it('nicht angemeldeter Nutzer kann Debt NICHT lesen', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .get()
    );
  });
});

describe('UC-13 Firestore Rules - Fake Debt writes blocked', () => {
  beforeEach(seedBaseState);

  it('Debt ohne Expense-Verknuepfung wird abgelehnt', async () => {
    const db = ctxAs(USER_A);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc('nonexistent-expense_' + USER_C)
        .set({
          wgId: WG_ID,
          expenseId: 'nonexistent-expense',
          creditorId: USER_A,
          debtorId: USER_C,
          amount: 999,
          status: 'open',
          paidAt: null,
          createdAt: new Date(),
        })
    );
  });

  it('falscher amount (nicht gleich ExpenseShare) wird abgelehnt', async () => {
    const db = ctxAs(USER_A);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_C}`)
        .set({
          wgId: WG_ID,
          expenseId: EXPENSE_ID,
          creditorId: USER_A,
          debtorId: USER_C,
          amount: 999999,
          status: 'open',
          paidAt: null,
          createdAt: new Date(),
        })
    );
  });

  it('falscher creditor (nicht gleich Expense.paidBy) wird abgelehnt', async () => {
    const db = ctxAs(USER_B);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_C}`)
        .set({
          wgId: WG_ID,
          expenseId: EXPENSE_ID,
          creditorId: USER_B,
          debtorId: USER_C,
          amount: 10,
          status: 'open',
          paidAt: null,
          createdAt: new Date(),
        })
    );
  });

  it('status paid bei Create wird abgelehnt', async () => {
    const db = ctxAs(USER_A);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_C}`)
        .set({
          wgId: WG_ID,
          expenseId: EXPENSE_ID,
          creditorId: USER_A,
          debtorId: USER_C,
          amount: 10,
          status: 'paid',
          paidAt: new Date(),
          createdAt: new Date(),
        })
    );
  });
});

describe('UC-13 Firestore Rules - Paid protection', () => {
  beforeEach(async () => {
    await seedBaseState();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({ status: 'paid', paidAt: serverTimestamp() })
    });
  });

  it('bezahlte Debt kann NICHT geloescht werden', async () => {
    const db = ctxAs(USER_A);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .delete()
    );
  });

  it('bezahlte Debt kann NICHT wieder open gesetzt werden', async () => {
    const db = ctxAs(USER_A);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({ status: 'open', paidAt: null })
    );
  });

  it('bezahlte Debt kann NICHT im Betrag veraendert werden', async () => {
    const db = ctxAs(USER_A);
    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({ amount: 999 })
    );
  });
});

describe('UC-13 Firestore Rules - Valid create and update', () => {
  beforeEach(seedBaseState);

  it('gueltiger Debt-Create im selben Batch wie das Expense-Update wird erlaubt', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();
    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);
    const debtRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('debts')
      .doc(`${EXPENSE_ID}_${USER_C}`);

    batch.update(expenseRef, {
      amount: 20,
      description: 'Testausgabe',
      paidBy: USER_A,
      updatedAt: serverTimestamp(),
    });
    batch.set(debtRef, {
      wgId: WG_ID,
      expenseId: EXPENSE_ID,
      creditorId: USER_A,
      debtorId: USER_C,
      amount: 5,
      status: 'open',
      paidAt: null,
      createdAt: serverTimestamp(),
    });
    const shareRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID)
      .collection('expenseShares')
      .doc(USER_C);

    batch.set(shareRef, {
      expenseId: EXPENSE_ID,
      userId: USER_C,
      shareAmount: 5,
    });

    await assertSucceeds(batch.commit());
  });

  it('gueltiges Update einer offenen Debt im selben Batch wie das Expense-Update wird erlaubt', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();
    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);
    const debtRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('debts')
      .doc(`${EXPENSE_ID}_${USER_B}`);

    batch.update(expenseRef, {
      amount: 20,
      description: 'Testausgabe',
      paidBy: USER_A,
      updatedAt: serverTimestamp(),
    });
    batch.update(debtRef, {
      creditorId: USER_A,
      amount: 10,
      status: 'open',
    });

    await assertSucceeds(batch.commit());
  });

  it('Schuldner darf eigene offene Debt als bezahlt markieren', async () => {
    const db = ctxAs(USER_B);

    await assertSucceeds(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({
          status: 'paid',
          paidAt: serverTimestamp(),
        })
    );
  });

  it('Glaeubiger darf Debt des Schuldners NICHT als bezahlt markieren', async () => {
    const db = ctxAs(USER_A);

    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({
          status: 'paid',
          paidAt: serverTimestamp(),
        })
    );
  });

  it('unbeteiligtes WG-Mitglied darf Debt NICHT als bezahlt markieren', async () => {
    const db = ctxAs(USER_C);

    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({
          status: 'paid',
          paidAt: serverTimestamp(),
        })
    );
  });

  it('Schuldner darf beim Bezahlen den Betrag NICHT veraendern', async () => {
    const db = ctxAs(USER_B);

    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({
          status: 'paid',
          paidAt: serverTimestamp(),
          amount: 999,
        })
    );
  });

  it('Schuldner darf beim Bezahlen kein zusaetzliches Feld einschleusen', async () => {
    const db = ctxAs(USER_B);

    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({
          status: 'paid',
          paidAt: serverTimestamp(),
          manipulated: true,
        })
    );
  });

  it('Nutzer aus fremder WG darf Debt NICHT als bezahlt markieren', async () => {
      const db = testEnv.authenticatedContext('user-outsider').firestore();

      await assertFails(
        db
          .collection('wgs')
          .doc(WG_ID)
          .collection('debts')
          .doc(`${EXPENSE_ID}_${USER_B}`)
          .update({
            status: 'paid',
            paidAt: serverTimestamp(),
          })
      );
    });

  it('offene Debt darf NICHT geloescht werden solange der ExpenseShare bestehen bleibt', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();

    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);

    const debtRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('debts')
      .doc(`${EXPENSE_ID}_${USER_B}`);

    batch.update(expenseRef, {
      updatedAt: serverTimestamp(),
    });

    batch.delete(debtRef);

    await assertFails(batch.commit());
  });

  it('offene Debt darf geloescht werden wenn der Schuldner neuer Zahler wird', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();

    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);

    const debtRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('debts')
      .doc(`${EXPENSE_ID}_${USER_B}`);

    batch.update(expenseRef, {
      paidBy: USER_B,
      updatedAt: serverTimestamp(),
    });

    batch.delete(debtRef);

    await assertSucceeds(batch.commit());
  });

  it('gueltiges Loeschen einer offenen Debt im selben Batch wie das Expense-Update wird erlaubt', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();
    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);
    const debtRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('debts')
      .doc(`${EXPENSE_ID}_${USER_B}`);

    const shareRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID)
      .collection('expenseShares')
      .doc(USER_B);

    batch.update(expenseRef, {
      amount: 20,
      description: 'Testausgabe',
      paidBy: USER_A,
      updatedAt: serverTimestamp(),
    });
    batch.delete(shareRef);
    batch.delete(debtRef);

    await assertSucceeds(batch.commit());
  });

  it('ExpenseShare darf NICHT isoliert zu einer bestehenden Expense angelegt werden', async () => {
    const db = ctxAs(USER_A);

    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('expenses')
        .doc(EXPENSE_ID)
        .collection('expenseShares')
        .doc(USER_C)
        .set({
          expenseId: EXPENSE_ID,
          userId: USER_C,
          shareAmount: 5,
        })
    );
  });

  it('ExpenseShare-Dokument-ID muss der userId entsprechen', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();

    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);

    const forgedShareRef = expenseRef
      .collection('expenseShares')
      .doc('forged-share-id');

    batch.update(expenseRef, {
      updatedAt: serverTimestamp(),
    });

    batch.set(forgedShareRef, {
      expenseId: EXPENSE_ID,
      userId: USER_C,
      shareAmount: 5,
    });

    await assertFails(batch.commit());
  });

    it('ExpenseShare-Update darf kein zusaetzliches Feld einschleusen', async () => {
    const db = ctxAs(USER_A);
    const batch = db.batch();

    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);

    const shareRef = expenseRef
      .collection('expenseShares')
      .doc(USER_B);

    batch.update(expenseRef, {
      updatedAt: serverTimestamp(),
    });

    batch.update(shareRef, {
      shareAmount: 10,
      manipulated: true,
    });

    await assertFails(batch.commit());
  });

  it('ExpenseShare mit falscher Dokument-ID darf NICHT aktualisiert werden', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .collection('wgs')
        .doc(WG_ID)
        .collection('expenses')
        .doc(EXPENSE_ID)
        .collection('expenseShares')
        .doc('forged-share-id')
        .set({
          expenseId: EXPENSE_ID,
          userId: USER_C,
          shareAmount: 5,
        });
    });

    const db = ctxAs(USER_A);
    const batch = db.batch();

    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);

    const forgedShareRef = expenseRef
      .collection('expenseShares')
      .doc('forged-share-id');

    batch.update(expenseRef, {
      updatedAt: serverTimestamp(),
    });

    batch.update(forgedShareRef, {
      shareAmount: 7,
    });

    await assertFails(batch.commit());
  });

  it('ExpenseShare mit falscher Dokument-ID darf NICHT geloescht werden', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .collection('wgs')
        .doc(WG_ID)
        .collection('expenses')
        .doc(EXPENSE_ID)
        .collection('expenseShares')
        .doc('forged-share-id')
        .set({
          expenseId: EXPENSE_ID,
          userId: USER_C,
          shareAmount: 5,
        });
    });

    const db = ctxAs(USER_A);
    const batch = db.batch();

    const expenseRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('expenses')
      .doc(EXPENSE_ID);

    const forgedShareRef = expenseRef
      .collection('expenseShares')
      .doc('forged-share-id');

    batch.update(expenseRef, {
      updatedAt: serverTimestamp(),
    });

    batch.delete(forgedShareRef);

    await assertFails(batch.commit());
  });
});


describe('UC-04 Firestore Rules - Secure WG join via Cloud Function only', () => {
  beforeEach(seedBaseState);

  const OUTSIDER = 'user-outsider-join';

  it('Client kann KEINE member-Membership direkt in fremder WG anlegen', async () => {
    const db = testEnv.authenticatedContext(OUTSIDER).firestore();

    await assertFails(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('memberships')
        .doc(OUTSIDER)
        .set({
          id: OUTSIDER,
          userId: OUTSIDER,
          wgId: WG_ID,
          role: 'member',
          joinedAt: new Date(),
        })
    );
  });

  it('Client kann KEINE member-Membership anlegen, selbst mit passendem userMemberships-Batch', async () => {
    const db = testEnv.authenticatedContext(OUTSIDER).firestore();
    const batch = db.batch();

    const membershipRef = db
      .collection('wgs')
      .doc(WG_ID)
      .collection('memberships')
      .doc(OUTSIDER);
    const userMembershipRef = db.collection('userMemberships').doc(OUTSIDER);

    batch.set(membershipRef, {
      id: OUTSIDER,
      userId: OUTSIDER,
      wgId: WG_ID,
      role: 'member',
      joinedAt: new Date(),
    });
    batch.set(userMembershipRef, {
      wgId: WG_ID,
      inviteCode: 'ABC123',
    });

    await assertFails(batch.commit());
  });

  it('admin-Membership kann weiterhin direkt clientseitig angelegt werden (WG erstellen bleibt unveraendert)', async () => {
    const newWgId = 'wg-new-admin-test';
    const db = testEnv.authenticatedContext(OUTSIDER).firestore();
    const batch = db.batch();

    const wgRef = db.collection('wgs').doc(newWgId);
    const membershipRef = wgRef.collection('memberships').doc(OUTSIDER);
    const inviteCodeRef = db.collection('inviteCodes').doc('ZZZ999');
    const userMembershipRef = db.collection('userMemberships').doc(OUTSIDER);

    batch.set(wgRef, {
      name: 'Neue WG',
      inviteCode: 'ZZZ999',
      createdBy: OUTSIDER,
      createdAt: new Date(),
    });
    batch.set(inviteCodeRef, { wgId: newWgId, wgName: 'Neue WG' });
    batch.set(membershipRef, {
      id: OUTSIDER,
      userId: OUTSIDER,
      wgId: newWgId,
      role: 'admin',
      joinedAt: new Date(),
    });
    batch.set(userMembershipRef, {
      wgId: newWgId,
      inviteCode: 'ZZZ999',
    });

    await assertSucceeds(batch.commit());
  });
});
