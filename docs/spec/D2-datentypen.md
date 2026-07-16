# D2 – Datentypen

Dieses Kapitel beschreibt die Attribute der in D1 definierten Entitäten sowie die verwendeten Enumerationen und Datentypen.

Triviale Datentypen wie Text, Integer, Boolean, Email, Timestamp und URL werden direkt verwendet und nicht separat definiert.

---

# D2.1 User

Ein registrierter Benutzer der Anwendung.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige technische ID des Benutzers |
| name | Text | 1 | Anzeigename des Benutzers |
| email | Email | 1 | Eindeutige E-Mail-Adresse |
| passwordHash | OpaqueSecret | 1 | Gehashtes Passwort |
| createdAt | Timestamp | 1 | Zeitpunkt der Registrierung |

---

# D2.2 WG

Eine Wohngemeinschaft.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige technische ID der WG |
| name | Text | 1 | Name der WG |
| inviteCode | Text | 1 | Einladungscode zum Beitritt |
| createdBy | Identifier | 1 | Ersteller der WG |
| createdAt | Timestamp | 1 | Erstellungszeitpunkt |

---

# D2.3 Membership

Mitgliedschaft eines Benutzers in einer WG.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige ID der Mitgliedschaft |
| userId | Identifier | 1 | Zugehöriger Benutzer |
| wgId | Identifier | 1 | Zugehörige WG |
| role | MembershipRole | 1 | Rolle innerhalb der WG |
| joinedAt | Timestamp | 1 | Beitrittszeitpunkt |

---

# D2.4 ShoppingItem

Ein Artikel der gemeinsamen Einkaufsliste.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige Artikel-ID |
| wgId | Identifier | 1 | Zugehörige WG |
| name | Text | 1 | Name des Artikels |
| quantity | Integer | 0..1 | Gewünschte Menge |
| category | Text | 0..1 | Optionale Kategorie |
| status | ItemStatus | 1 | Status des Artikels |
| createdBy | Identifier | 1 | Benutzer, der den Artikel erstellt hat |
| createdAt | Timestamp | 1 | Erstellungszeitpunkt |
| updatedAt | Timestamp | 1 | Zeitpunkt der letzten Änderung |

---

# D2.5 Expense

Eine Ausgabe innerhalb einer Wohngemeinschaft.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige ID der Ausgabe |
| wgId | Identifier | 1 | Zugehörige WG |
| amount | Decimal | 1 | Gesamtbetrag der Ausgabe |
| description | Text | 1 | Beschreibung der Ausgabe |
| paidBy | Identifier | 1 | Mitglied, das bezahlt hat |
| receiptUrl | URL | 0..1 | Optionaler Beleg |
| createdAt | Timestamp | 1 | Zeitpunkt der Erfassung |

---

# D2.6 ExpenseShare

Der Anteil eines Benutzers an einer Ausgabe.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige ID |
| expenseId | Identifier | 1 | Zugehörige Ausgabe |
| userId | Identifier | 1 | Zugehöriger Benutzer |
| shareAmount | Decimal | 1 | Anteil am Gesamtbetrag |

---

# D2.7 Debt

Eine Schuld zwischen zwei Mitgliedern.

| Attribut | Typ | Kard. | Beschreibung |
|-----------|------|--------|--------------|
| id | Identifier | 1 | Eindeutige ID der Schuld |
| creditorId | Identifier | 1 | Gläubiger |
| debtorId | Identifier | 1 | Schuldner |
| amount | Decimal | 1 | Offener Betrag |
| status | DebtStatus | 1 | Status der Schuld |
| paidAt | Timestamp | 0..1 | Zeitpunkt der Bezahlung |
| createdAt | Timestamp | 1 | Zeitpunkt der Erstellung |

---

# D2.8 Datentypenverzeichnis

| Typ | Art | Referenziert von |
|------|------|----------------|
| Identifier | Basistyp | Alle IDs und Referenzen |
| OpaqueSecret | Basistyp | User.passwordHash |
| Decimal | Basistyp | Expense.amount, ExpenseShare.shareAmount, Debt.amount |
| MembershipRole | Enumeration | Membership.role |
| ItemStatus | Enumeration | ShoppingItem.status |
| DebtStatus | Enumeration | Debt.status |

---

# D2.9 Enumerationen

## MembershipRole

Beschreibt die Rolle eines Mitglieds innerhalb einer WG.

| Wert | Bedeutung |
|---------|-----------|
| admin | Darf die WG verwalten |
| member | Normales Mitglied |

---

## ItemStatus

Beschreibt den Status eines Artikels.

| Wert | Bedeutung |
|---------|-----------|
| open | Artikel wurde noch nicht gekauft |
| bought | Artikel wurde gekauft |

---

## DebtStatus

Beschreibt den Status einer Schuld.

| Wert | Bedeutung |
|---------|-----------|
| open | Schuld ist offen |
| paid | Schuld wurde bezahlt |

---

# D2.10 Weitere Datentypen

## Identifier

Eindeutiger Identifikator einer Entität.

### Eigenschaften

- eindeutig
- unveränderlich
- nicht wiederverwendbar
- wird bei der Erstellung vergeben
- dient als Primärschlüssel

### Verwendung

- User.id
- WG.id
- Membership.id
- ShoppingItem.id
- Expense.id
- ExpenseShare.id
- Debt.id

sowie alle Referenzattribute.

---

## OpaqueSecret

Opaker Geheimniswert für Authentifizierungsdaten.

### Eigenschaften

- niemals Klartext
- nicht lesbar
- nicht exportierbar
- nur zur Verifikation verwendbar

### Verwendung

- User.passwordHash

### Regeln

- Passwörter werden niemals im Klartext gespeichert.
- Passwörter werden niemals angezeigt.
- Passwörter werden niemals in Logs ausgegeben.

---

## Decimal

Exakter Dezimalwert für Geldbeträge.

### Eigenschaften

- zwei Nachkommastellen
- exakte Berechnung
- keine Rundungsfehler durch Gleitkommazahlen

### Verwendung

- Expense.amount
- ExpenseShare.shareAmount
- Debt.amount

### Regeln

- Expense.amount > 0
- Debt.amount > 0
- ExpenseShare.shareAmount ≥ 0
- Die Summe aller ExpenseShare.shareAmount einer Expense entspricht exakt dem Expense.amount.