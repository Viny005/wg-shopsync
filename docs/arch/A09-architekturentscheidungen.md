# A09 – Architekturentscheidungen

## ADR-01: Responsive Webanwendung mit Flutter Web

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

## ADR-02: Firebase Authentication

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

## ADR-05: Server gewinnt bei Konflikten

### Kontext

Mehrere WG-Mitglieder können dieselbe Einkaufsliste bearbeiten. Bei gleichzeitigem Offline- oder Online-Zugriff können unterschiedliche lokale und serverseitige Datenstände entstehen.

### Alternativen

- Automatische Zusammenführung konkurrierender Änderungen
- Der zuletzt eintreffende Clientstand gewinnt
- Der serverseitige Datenstand gewinnt

### Entscheidung

Bei konkurrierenden Änderungen gilt der serverseitige Datenstand.

### Begründung

Alle Mitglieder einer WG sollen einen eindeutigen gemeinsamen Datenstand sehen. Eine automatische Zusammenführung könnte fachlich widersprüchliche Artikel- oder Statusänderungen erzeugen und wäre für den MVP unnötig komplex.

### Konsequenzen

- Der Konflikt wird dem Benutzer als Konflikthinweis angezeigt.
- Eine verworfene lokale Änderung wird nicht stillschweigend als erfolgreich behandelt.
- Der Benutzer kann die lokale Änderung nach Prüfung erneut anwenden.

## ADR-06: Einfache Rollenstruktur

### Kontext

WG-ShopSync muss zwischen dem Ersteller einer WG und den übrigen Mitgliedern unterscheiden. Für den definierten Funktionsumfang ist kein komplexes Rollen- und Berechtigungsmodell erforderlich.

### Alternativen

- Keine Rollen, alle Mitglieder mit identischen Rechten
- Komplexes rollenbasiertes Berechtigungssystem
- Die Rollen `admin` und `member`

### Entscheidung

Es gibt die beiden Rollen `admin` und `member`. Der WG-Ersteller erhält `admin`; beitretende Benutzer erhalten `member`.

### Begründung

Die beiden Rollen reichen für Einladungscode, WG-Verwaltung und die normalen Funktionen der gemeinsamen Einkaufsliste und Kostenverwaltung aus. Die Rollen sind in D2 als fachlicher Datentyp definiert.

### Konsequenzen

- Die Rolle wird in `Membership.role` gespeichert.
- Berechtigungen werden anhand der Membership und der WG-Zugehörigkeit geprüft.
- Der letzte `admin` darf die WG nicht verlassen, solange kein anderer `admin` vorhanden ist.
