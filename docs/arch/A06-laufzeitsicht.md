# A06 – Laufzeitsicht

## 1. Login

```mermaid
sequenceDiagram
    actor U as Benutzer
    participant UI as Web UI
    participant Auth as Firebase Authentication
    U->>UI: E-Mail und Passwort eingeben
    UI->>Auth: signInWithEmailAndPassword
    Auth-->>UI: Authentifizierungsstatus und UID
    UI->>UI: WG-Kontext laden
    UI-->>U: WG-Übersicht anzeigen
```

## 2. Artikel hinzufügen

```mermaid
sequenceDiagram
    actor U as Benutzer
    participant UI as Web UI
    participant S as ShoppingListService
    participant F as Cloud Firestore
    U->>UI: Artikel speichern
    UI->>S: Eingaben validieren
    S->>F: ShoppingItem mit status=open speichern
    F-->>S: Schreibbestätigung
    F-->>UI: Realtime-Update
    UI-->>U: Aktualisierte Liste anzeigen
```

## 3. Kosten aufteilen

### Aktivitätsdiagramm – Kosten aufteilen

```mermaid
flowchart TD
    A([Start]) --> B[Ausgabe öffnen]
    B --> C[Beteiligte Mitglieder auswählen]
    C --> D[Kostenaufteilung bestätigen]
    D --> E{Eingaben gültig?}
    E -- Nein --> F[Fehlermeldung anzeigen]
    F --> C
    E -- Ja --> G[Kostenanteile gleichmäßig berechnen]
    G --> H[ExpenseShares speichern]
    H --> I[Debts aktualisieren]
    I --> J[Kostenübersicht über Firestore aktualisieren]
    J --> K([Ende])
```

Der `ExpenseService` prüft vor der Berechnung die WG-Zugehörigkeit, den Betrag und mindestens ein beteiligtes Mitglied. Cent-Rundungen werden ausgeglichen, sodass die Summe der `ExpenseShares` exakt dem Ausgabebetrag entspricht.

## 4. Offline-Änderung

Firestore stellt den letzten lokalen Stand bereit. Eine Änderung an einer zuvor synchronisierten Einkaufsliste wird lokal vorgemerkt und nach Wiederherstellung der Verbindung an Firestore übertragen. Bei einem Konflikt bleibt der Serverstand gültig und die lokale Änderung wird als Konflikthinweis angezeigt.

## 5. WG erstellen und beitreten

### Aktivitätsdiagramm – WG erstellen oder beitreten

```mermaid
flowchart TD
    A([Start]) --> B[WG-Aktion auswählen]
    B --> C{Erstellen oder beitreten?}
    C -- Erstellen --> D[WG-Namen eingeben]
    D --> E{WG-Name gültig?}
    E -- Nein --> F[Fehlermeldung anzeigen]
    F --> D
    E -- Ja --> G[WG und eindeutigen Einladungscode erstellen]
    G --> H[Membership mit Rolle admin anlegen]
    C -- Beitreten --> I[Einladungscode eingeben]
    I --> J{Code gültig und Benutzer noch ohne WG?}
    J -- Nein --> K[Fehlermeldung anzeigen]
    K --> I
    J -- Ja --> L[Membership mit Rolle member anlegen]
    H --> M[WG-Kontext laden]
    L --> M
    M --> N[WG-Übersicht anzeigen]
    N --> O([Ende])
```

Beim Verlassen einer WG prüft der `WGService`, ob das Mitglied der letzte `admin` ist. In diesem Fall wird das Verlassen abgelehnt; andernfalls wird die Membership entfernt.

## 6. Ausgabe bearbeiten und Kostenübersicht

1. Das Mitglied öffnet eine bestehende Ausgabe; der `ExpenseService` prüft WG-Zugehörigkeit, Betrag und Beteiligte.
2. Die bestehenden `ExpenseShare`- und `Debt`-Einträge werden anhand der neuen Daten aktualisiert.
3. Der Saldo berücksichtigt offene Schulden und ignoriert Schulden mit Status `paid`.
4. Die Kostenübersicht zeigt dem angemeldeten Mitglied nur die eigenen Kostenanteile, Forderungen und Verbindlichkeiten.

## 7. Schuld bezahlen und WG verlassen

1. Das Mitglied markiert eine eigene offene Schuld als bezahlt.
2. Der Service setzt den Status auf `paid`, speichert das Zahlungsdatum und lässt den ursprünglichen Betrag unverändert.
3. Beim Verlassen prüft der `WGService`, ob das Mitglied der letzte `admin` ist. In diesem Fall wird das Verlassen abgelehnt; andernfalls wird die Membership entfernt.
