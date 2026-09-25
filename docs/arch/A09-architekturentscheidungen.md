# A09 – Architekturentscheidungen

Die folgenden ADRs dokumentieren die verbindlichen Architekturentscheidungen für den aktuellen Web-MVP. Alle Entscheidungen haben den Status `accepted` und gelten für die erste Version von WG-ShopSync.

## ADR-Index

| ID | Entscheidung | Status | Datum |
|---|---|---|---|
| ADR-01 | Responsive Webanwendung mit Flutter Web | accepted | 2026-09-07 |
| ADR-02 | Firebase Authentication | accepted | 2026-09-07 |
| ADR-03 | Cloud Firestore | accepted | 2026-09-07 |
| ADR-04 | Kein eigener App-Server | accepted | 2026-09-07 |
| ADR-05 | Server gewinnt bei Konflikten | accepted | 2026-09-07 |
| ADR-06 | Einfache Rollenstruktur | accepted | 2026-09-07 |
| ADR-07 | Expense-bezogene Debt-Dokumente | accepted | 2026-09-20 |

Die Entscheidungen beziehen sich auf die fachlichen Anforderungen in `docs/spec/` und die Baustein-, Laufzeit- und Verteilungssichten in A05 bis A08. Es gibt aktuell keine separate Implementierung oder Ticket-ID, auf die verlinkt werden könnte; die Spezifikation und Architektur sind die verbindlichen Projektartefakte.

## ADR-01: Responsive Webanwendung mit Flutter Web

**Status:** accepted
**Datum:** 2026-09-07
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

WG-ShopSync soll als gemeinsames System von WG-Mitgliedern über einen Webbrowser genutzt werden. Der Projektumfang ist auf eine responsive Webanwendung begrenzt; native Anwendungen gehören nicht zum Zielsystem.

### Alternativen

- Flutter Web
- React oder Angular
- Native Anwendungen für einzelne Plattformen

### Entscheidung

WG-ShopSync wird als responsive Webanwendung mit Flutter Web umgesetzt.

### Begründung

Flutter Web ermöglicht eine einheitliche Benutzeroberfläche und gemeinsame Fachlogik innerhalb einer Codebasis. Die Anwendung ist direkt über moderne Browser erreichbar, ohne separate native Clients zu entwickeln.

### Konsequenzen

- Die Anwendung wird als Web-Build bereitgestellt.
- Die Oberfläche muss für Desktop- und mobile Browser responsiv gestaltet werden.
- Die Anwendung setzt einen modernen, JavaScript-fähigen Browser voraus.

**Bekannte Einschränkungen und Review-Kriterien:** Flutter Web kann größere initiale Bundles, zusätzliche Ladezeit und Unterschiede bei Browser-Zugänglichkeit oder Safari-Kompatibilität verursachen. Die Entscheidung wird überprüft, wenn der initiale Ladevorgang im Zielbrowser dauerhaft mehr als 3 Sekunden benötigt, zentrale WCAG-relevante Bedienungen nicht umsetzbar sind oder ein unterstützter Browser eine Kernfunktion nicht zuverlässig ausführt.

## ADR-02: Firebase Authentication

**Status:** accepted
**Datum:** 2026-09-07
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

Registrierung, Login und Sitzungsverwaltung müssen sicher umgesetzt werden. Die Anwendung soll keine eigene Verwaltung von Passwörtern und Sitzungen implementieren.

### Alternativen

- Eigene Authentifizierung
- Keycloak
- Auth0
- Firebase Authentication

### Entscheidung

Benutzerkonten und Sitzungen werden über Firebase Authentication verwaltet.

### Begründung

Firebase Authentication stellt Registrierung, Login und Sitzungsverwaltung als verwalteten Dienst bereit. Dadurch wird sicherheitskritische Infrastruktur nicht selbst entwickelt und der Implementierungsaufwand bleibt für das Hochschulprojekt begrenzt.

### Konsequenzen

- Die Webanwendung ist für Authentifizierung und Sitzungsstatus von Firebase abhängig.
- Nur authentifizierte Benutzer erhalten Zugriff auf WG-Daten.
- Die Benutzer-ID aus Firebase wird für die Membership- und Autorisierungsprüfung verwendet.

## ADR-03: Cloud Firestore

**Status:** accepted
**Datum:** 2026-09-07
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

Die gemeinsame Einkaufsliste, Ausgaben und Schulden müssen zentral gespeichert und für berechtigte Mitglieder synchronisiert werden. Bereits synchronisierte Einkaufslistendaten sollen außerdem offline verfügbar bleiben.

### Alternativen

- Relationale Cloud-Datenbank
- Cloud Realtime Database
- Lokale Speicherung ohne zentrale Datenbank
- Cloud Firestore

### Entscheidung

Cloud Firestore ist die zentrale Datenhaltung von WG-ShopSync.

### Begründung

Firestore unterstützt dokumentenbasierte Daten, Realtime-Listener und Offline-Persistenz. Diese Eigenschaften passen zur gemeinsamen Einkaufsliste und zur Synchronisation zwischen mehreren Browsern.

### Konsequenzen

- Das Datenmodell und die Abfragen werden an Firestore-Dokumente und -Sammlungen angepasst.
- Zugriffe werden über Firestore Security Rules abgesichert.
- Das Synchronisations- und Konfliktverhalten von Firestore muss in der Anwendung berücksichtigt werden.

## ADR-04: Kein eigener App-Server

**Status:** accepted
**Datum:** 2026-09-07
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

WG-ShopSync benötigt für den definierten MVP keinen eigenen zentralen Server. Authentifizierung, Datenhaltung und Synchronisation werden durch Firebase-Dienste bereitgestellt.

### Alternativen

- Eigener Backend-Server mit REST-API
- Separater Node.js- oder PHP-Server
- Firebase-Dienste ohne eigenen App-Server

### Entscheidung

In der ersten Version gibt es keinen separaten App-Server.

### Begründung

Die Anforderungen können mit der Webanwendung und den Firebase-SDKs umgesetzt werden. Ein eigener Server würde Bereitstellung, Betrieb und Wartung vergrößern, ohne für den MVP einen notwendigen Mehrwert zu liefern.

### Konsequenzen

- Fachliche Regeln werden in der Webanwendung, in Firestore-Transaktionen und in Security Rules umgesetzt.
- Es gibt keine eigene REST-API für externe Clients.
- Komplexe serverseitige Funktionen sind im MVP nicht vorgesehen.

**Zukünftige Alternative:** Falls später privilegierte serverseitige Logik, geplante Aufgaben oder komplexe Transaktionen erforderlich werden, kann der Datenzugriff um Firebase Cloud Functions beziehungsweise eine vergleichbare serverlose Funktionsebene erweitert werden. Das würde eine neue ADR und eine Prüfung der Security Rules erfordern.

## ADR-05: Server gewinnt bei Konflikten

**Status:** accepted
**Datum:** 2026-09-07
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

Mehrere WG-Mitglieder können denselben Einkaufsartikel oder dieselbe Ausgabe nahezu gleichzeitig bearbeiten. Für UC-07, UC-09 und UC-12 muss verhindert werden, dass ein veralteter Clientstand eine zwischenzeitliche Serveränderung unbemerkt überschreibt.

Die konfliktgeschützten Änderungen werden deshalb als Firestore-Transaktionen ausgeführt und benötigen eine aktive Verbindung.

### Alternativen

- Automatische Zusammenführung konkurrierender Änderungen
- Der zuletzt eintreffende Clientstand gewinnt
- Der serverseitige Datenstand gewinnt und der Benutzer lädt den aktuellen Stand

### Entscheidung

Bei einem erkannten Konkurrenzkonflikt gilt der serverseitige Datenstand.

### Begründung

Alle Mitglieder einer WG sollen einen eindeutigen gemeinsamen Datenstand sehen. Eine automatische Zusammenführung könnte fachlich widersprüchliche Artikel-, Status- oder Ausgabendaten erzeugen. Der serverseitige Stand als Ausgangspunkt verhindert stilles Überschreiben.

### Konsequenzen

- Ein veralteter Clientstand wird nicht still überschrieben.
- Die Oberfläche informiert den Benutzer über den Konflikt.
- Der aktuelle Serverstand kann geladen werden.
- Eine gewünschte Änderung kann danach als neue Bearbeitung erneut durchgeführt werden.
- Konfliktgeschützte Transaktionen benötigen eine aktive Verbindung.
## ADR-06: Einfache Rollenstruktur

**Status:** accepted
**Datum:** 2026-09-07
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

WG-ShopSync muss den Ersteller einer WG von beitretenden Mitgliedern unterscheiden. Für den definierten Funktionsumfang ist kein komplexes Rollen- und Berechtigungssystem erforderlich.

### Alternativen

- Keine Rollen, alle Mitglieder vollständig identisch
- Komplexes rollenbasiertes Berechtigungssystem mit Rollenübertragung
- Die Rollen `admin` und `member` ohne Rollenübertragung im MVP

### Entscheidung

Es gibt die beiden Rollen `admin` und `member`. Der WG-Ersteller erhält `admin`; beitretende Benutzer erhalten `member`.

### Begründung

Für Einkaufsliste, Ausgaben und eigene Schulden benötigen beide Rollen dieselben fachlichen Datenfunktionen. Die Erstellerrolle bleibt dennoch explizit erhalten, damit die Herkunft der WG eindeutig ist und verhindert werden kann, dass die WG im MVP ohne `admin` zurückbleibt.

### Konsequenzen

- Die Rolle wird in `Membership.role` gespeichert.
- `admin` und `member` dürfen den Einladungscode der eigenen WG sehen.
- Datenzugriffe werden zusätzlich über die WG-Membership abgesichert.
- `member` kann die WG verlassen.
- `admin` kann die WG im MVP nicht verlassen.
- Eine Rollenübertragung oder Ernennung eines weiteren `admin` ist nicht Bestandteil der ersten Version.
## ADR-07: Expense-bezogene Debt-Dokumente

**Status:** accepted
**Datum:** 2026-09-20
**Autoren:** Entwicklerteam WG-ShopSync

### Kontext

Die ursprüngliche UC-13-Umsetzung führte pro Mitgliederpaar genau eine aggregierte `Debt` (Gläubiger/Schuldner), die bei jeder Ausgabe um den jeweiligen Kostenanteil erhöht oder verringert wurde. Dieses Modell erfüllte D1.8, machte jedoch UC-14 (offene und bezahlte Schulden anzeigen) und UC-15 (eine einzelne Schuld als bezahlt markieren) fachlich unmöglich: Eine bereits bezahlte Schuld hätte beim nächsten Kostenanteil zwischen denselben Mitgliedern wieder geöffnet werden müssen, wodurch Betrag, Zahlungsdatum und Status der historischen Zahlung verloren gegangen wären.

### Alternativen

- Aggregierte Paar-Schuld pro Mitgliederpaar (bisheriges Modell)
- Eine Schuld pro Ausgabe und beteiligtem Nicht-Zahler-Mitglied
- Serverseitige Ledger-Lösung mit separaten Buchungssätzen

### Entscheidung

Jede Ausgabe erzeugt für jedes beteiligte Mitglied außer dem Zahler eine eigene `Debt`, die über `Debt.expenseId` der auslösenden Ausgabe zugeordnet ist. Die Dokument-ID wird deterministisch aus `expenseId` und `debtorId` gebildet.

### Begründung

Nur eine expense-bezogene Schuld erlaubt es, bezahlte Schulden unverändert als Historie zu erhalten (UC-14), eine einzelne Schuld gezielt als bezahlt zu markieren (UC-15) und Firestore Security Rules so zu gestalten, dass eine Schuld nur zusammen mit ihrer Ausgabe erzeugt oder verändert werden kann. Die serverseitige Ledger-Lösung wurde verworfen, da sie eine zusätzliche Infrastrukturkomponente erfordert hätte, die für den Funktionsumfang des MVP nicht erforderlich ist.

### Konsequenzen

- `Debt` besitzt zusätzlich das Attribut `expenseId` (siehe D1.8).
- Zwischen denselben zwei Mitgliedern können mehrere offene und bezahlte Schulden aus unterschiedlichen Ausgaben nebeneinander bestehen.
- Der Saldo (AF-06) wird zur Laufzeit als Summe aller offenen Schulden zwischen zwei Mitgliedern gebildet, nicht aus einem einzelnen gespeicherten Wert gelesen.
- Eine Bearbeitung einer Ausgabe, deren Schulden bereits bezahlt sind, verändert diese Schulden nicht mehr.
- Firestore Security Rules validieren eine Schuld gegen die zugehörige Ausgabe und deren Kostenanteil.
