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

  it('gueltiges Markieren als bezahlt (UC-15-Fall, ohne Expense-Aenderung) wird erlaubt', async () => {
    const db = ctxAs(USER_A);
    await assertSucceeds(
      db
        .collection('wgs')
        .doc(WG_ID)
        .collection('debts')
        .doc(`${EXPENSE_ID}_${USER_B}`)
        .update({ status: 'paid', paidAt: serverTimestamp() })
    );
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

  batch.update(expenseRef, {
  amount: 20,
  description: 'Testausgabe',
  paidBy: USER_A,
  updatedAt: serverTimestamp(),
});
    batch.delete(debtRef);

    await assertSucceeds(batch.commit());
  });
});
