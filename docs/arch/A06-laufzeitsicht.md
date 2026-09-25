# A06 – Laufzeitsicht

## 1. Registrierung

```mermaid
sequenceDiagram
    actor U as Benutzer
    participant UI as Web UI
    participant Auth as Firebase Authentication
    participant F as Cloud Firestore
    U->>UI: E-Mail, Passwort und Benutzername eingeben
    UI->>UI: Eingaben validieren
    UI->>Auth: createUserWithEmailAndPassword
    Auth-->>UI: Benutzer-ID (UID)
    UI->>F: Benutzerprofil anlegen (uid, name, email)
    F-->>UI: Schreibbestätigung
    UI-->>U: Weiterleitung zur WG-Auswahl
```

Der `FirebaseAuthRepository` legt nach erfolgreicher Registrierung bei Firebase Authentication ein Benutzerprofil in Firestore an. Ist die E-Mail bereits vergeben oder das Passwort ungültig, gibt Firebase Authentication einen Fehler zurück, der dem Benutzer als verständliche Fehlermeldung angezeigt wird. Ohne Verbindung ist die Registrierung nicht möglich.

## 2. Login

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

## 3. Artikel hinzufügen

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

![Uebersicht der Laufzeitszenarien](images/a06-laufzeit.svg)

## 4. Kosten aufteilen

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
Für jedes beteiligte Mitglied außer dem Zahler erzeugt der `ExpenseService` eine eigene, der Ausgabe zugeordnete `Debt` in Höhe des jeweiligen Kostenanteils. Bei einer Änderung der Ausgabe werden ausschließlich die dieser Ausgabe zugeordneten, noch offenen `Debt`-Dokumente angepasst; bereits bezahlte Schulden bleiben unverändert erhalten. Alle Lesezugriffe innerhalb der Firestore-Transaktion (Mitgliedschaften, bestehende Kostenanteile, betroffene Schulden) erfolgen vor jedem Schreibzugriff.

## 5. Offline-Verhalten

Bereits synchronisierte Einkaufslistendaten können über den Firestore-Cache weiterhin angezeigt werden.

Beim Hinzufügen eines neuen Artikels wartet `ShoppingListService.addItem()` auf Flutter Web nicht synchron auf den Serverabschluss. Der Firestore-Schreibvorgang kann lokal als `hasPendingWrites` sichtbar werden und wird nach Wiederherstellung der Verbindung synchronisiert.

`ShoppingListService.updateItem()` und `markAsBought()` verwenden zur Konfliktprüfung Firestore-Transaktionen. Diese Aktionen benötigen eine aktive Verbindung und liefern bei Offline-Zustand eine verständliche Fehlermeldung, statt eine ungesicherte lokale Änderung auszuführen.

Bei einem online erkannten Konkurrenzkonflikt bleibt der Serverstand maßgeblich. Der Benutzer kann die Serverdaten laden und anschließend erneut bearbeiten.
## 6. WG erstellen und beitreten

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

Beim Verlassen einer WG erlaubt der `WgService` das Entfernen nur für die Rolle `member`. Die Erstellerrolle `admin` kann im MVP nicht verlassen werden, weil keine Rollenübertragung oder Ernennung eines weiteren `admin` vorgesehen ist.

## 7. Ausgabe bearbeiten und Kostenübersicht

1. Das Mitglied öffnet eine bestehende Ausgabe; der `ExpenseService` prüft WG-Zugehörigkeit, Betrag und Beteiligte.
2. Die bestehenden `ExpenseShare`- und `Debt`-Einträge werden anhand der neuen Daten aktualisiert.
3. Der Saldo berücksichtigt offene Schulden und ignoriert Schulden mit Status `paid`.
4. Die Kostenübersicht zeigt dem angemeldeten Mitglied nur die eigenen Kostenanteile, Forderungen und Verbindlichkeiten.

## 8. Schuld bezahlen und WG verlassen

1. Das Mitglied markiert eine eigene offene Schuld als bezahlt.
2. Der Service setzt den Status auf `paid`, speichert das Zahlungsdatum und lässt den ursprünglichen Betrag unverändert.
3. Beim Verlassen erlaubt der `WgService` das Entfernen nur für die Rolle `member`. Die Erstellerrolle `admin` kann im MVP nicht verlassen werden, da keine Rollenübertragung oder Ernennung eines weiteren `admin` vorgesehen ist.
