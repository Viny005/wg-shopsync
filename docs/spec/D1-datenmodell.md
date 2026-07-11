# D1 – Datenmodell

Dieses Kapitel beschreibt die zentralen fachlichen Entitäten von WG-ShopSync sowie deren Beziehungen.

Das Datenmodell wurde aus den in F2 beschriebenen Anwendungsfällen und den fachlichen Anforderungen aus F1 abgeleitet.

Die Entitäten bilden die Grundlage für die Speicherung und Verarbeitung von Benutzern, Wohngemeinschaften, Einkaufslisten, Ausgaben und Schulden.

---

## D1.1 Datenmodellübersicht

Die folgenden Entitäten bilden das Kernmodell von WG-ShopSync:

- User
- WG
- Membership
- ShoppingItem
- Expense
- ExpenseShare
- Debt

Kurzbeschreibung:

**User**  
Ein registrierter Benutzer der Anwendung.

**WG**  
Eine Wohngemeinschaft mit gemeinsamer Einkaufsliste und gemeinsamer Kostenverwaltung.

**Membership**  
Verbindet einen Benutzer mit einer Wohngemeinschaft und speichert dessen Rolle.

**ShoppingItem**  
Ein Artikel auf der gemeinsamen Einkaufsliste.

**Expense**  
Eine Ausgabe, die von einem Mitglied für die WG getätigt wurde.

**ExpenseShare**  
Der Anteil eines Mitglieds an einer Ausgabe.

**Debt**  
Eine offene oder bereits beglichene Forderung zwischen zwei Mitgliedern.

---

## D1.2 User

Repräsentiert einen registrierten Benutzer der Anwendung.

### Beziehungen

- Ein User kann Mitglied mehrerer WGs sein.
- Ein User kann mehrere ShoppingItems erstellen.
- Ein User kann mehrere Ausgaben bezahlen.
- Ein User kann Gläubiger oder Schuldner einer Debt sein.

### Attribute

- id
- name
- email
- passwordHash
- createdAt

---

## D1.3 WG

Repräsentiert eine Wohngemeinschaft.

### Beziehungen

- Eine WG besitzt mehrere Memberships.
- Eine WG besitzt mehrere ShoppingItems.
- Eine WG besitzt mehrere Expenses.
- Eine WG besitzt mehrere Debts.

### Attribute

- id
- name
- inviteCode
- createdBy
- createdAt

---

## D1.4 Membership

Stellt die Mitgliedschaft eines Benutzers in einer WG dar.

### Beziehungen

- Gehört genau zu einem User.
- Gehört genau zu einer WG.

### Attribute

- id
- userId
- wgId
- role
- joinedAt

---

## D1.5 ShoppingItem

Repräsentiert einen Eintrag auf der gemeinsamen Einkaufsliste.

### Beziehungen

- Gehört genau zu einer WG.
- Wurde von genau einem User erstellt.

### Attribute

- id
- wgId
- name
- quantity
- category
- status
- createdBy
- createdAt
- updatedAt

---

## D1.6 Expense

Repräsentiert eine Ausgabe innerhalb einer Wohngemeinschaft.

### Beziehungen

- Gehört genau zu einer WG.
- Wurde von genau einem User bezahlt.
- Besitzt einen oder mehrere ExpenseShares.

### Attribute

- id
- wgId
- amount
- description
- paidBy
- receiptUrl
- createdAt

---

## D1.7 ExpenseShare

Repräsentiert den Anteil eines Mitglieds an einer Ausgabe.

### Beziehungen

- Gehört genau zu einer Expense.
- Gehört genau zu einem User.

### Attribute

- id
- expenseId
- userId
- shareAmount

---

## D1.8 Debt

Repräsentiert eine Forderung zwischen zwei Mitgliedern.

### Beziehungen

- Verweist auf einen Gläubiger.
- Verweist auf einen Schuldner.

### Attribute

- id
- creditorId
- debtorId
- amount
- status
- paidAt
- createdAt

---

## D1.9 Beziehungen zwischen den Entitäten

Die wichtigsten Beziehungen des Datenmodells sind:

```text
User
 │
 └── Membership
       │
       └── WG
             │
             ├── ShoppingItem
             │
             ├── Expense
             │      │
             │      └── ExpenseShare
             │
             └── Debt
```

Kardinalitäten:

```text
User      1 --- n Membership

WG        1 --- n Membership

WG        1 --- n ShoppingItem

WG        1 --- n Expense

Expense   1 --- n ExpenseShare

User      1 --- n ExpenseShare

User      1 --- n Debt (als Schuldner)

User      1 --- n Debt (als Gläubiger)
```

---

## D1.10 Fachliche Regeln

### Benutzer

- Die E-Mail-Adresse eines Users ist eindeutig.
- Ein Benutzerkonto darf nur einmal existieren.

### WG

- Jede WG besitzt genau einen Einladungscode.
- Einladungscodes sind eindeutig.

### ShoppingItem

- Jeder Artikel gehört genau einer WG.
- Ein Artikel besitzt immer einen Status.

### Expense

- Eine Ausgabe besitzt einen Betrag größer als 0.
- Eine Ausgabe muss genau einem Zahler zugeordnet sein.

### ExpenseShare

- Jeder Anteil gehört genau einer Ausgabe.
- Die Summe aller Anteile entspricht dem Gesamtbetrag der Ausgabe.

### Debt

- Eine Schuld besitzt genau einen Schuldner.
- Eine Schuld besitzt genau einen Gläubiger.
- Eine Schuld kann den Status „offen“ oder „bezahlt“ besitzen.
- Beim Status „bezahlt“ wird das Zahlungsdatum gespeichert.