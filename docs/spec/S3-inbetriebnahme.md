# S3 – Inbetriebnahme

## Ziel

Dieses Kapitel beschreibt die Bereitstellung und Inbetriebnahme von WG-ShopSync.

Die Anwendung wird als responsive Flutter-Webanwendung für moderne Desktop- und mobile Webbrowser bereitgestellt. Firebase Authentication übernimmt die Authentifizierung, Cloud Firestore die zentrale Datenhaltung und Synchronisation und Firebase Hosting die Auslieferung der Webanwendung.

---

## Infrastruktur

### Firebase-Projekt

Für Entwicklung und Betrieb wird das Firebase-Projekt mit der Project ID `wg-shopsync` verwendet.

### Verwaltete Cloud-Dienste

- **Firebase Authentication:** Registrierung, Anmeldung und Benutzersitzungen mit E-Mail und Passwort.
- **Cloud Firestore:** Zentrale Speicherung der Benutzer-, WG-, Einkaufs-, Ausgaben- und Schuldendaten sowie Echtzeit-Synchronisation.
- **Firebase Hosting:** Bereitstellung des Flutter-Web-Builds über HTTPS.

### Datenbank-Infrastruktur

Cloud Firestore wird in der Standard Edition in der Region `europe-west3` (Frankfurt) betrieben.

Collections und Dokumente werden durch die Anwendung erzeugt. Eine manuelle Vorinitialisierung der fachlichen Collections ist nicht erforderlich.

Scheduled Backups sind für die Abgabeversion nicht aktiviert.

### Authentifizierung

Die Abgabeversion verwendet Firebase Authentication mit E-Mail und Passwort.

Passwordless Email Link und Social-Login-Provider gehören nicht zum definierten Funktionsumfang.

### Firestore Security Rules

Die versionierte Quelle der produktiven Firestore Security Rules ist [firestore.rules](../../firestore.rules).

Die Rules begrenzen den Zugriff auf authentifizierte Benutzer und WG-Mitglieder und prüfen die für die jeweiligen Schreiboperationen erforderlichen fachlichen Beziehungen.

Die Rules werden automatisiert gegen den lokalen Firestore Emulator getestet. Der verifizierte Abgabestand umfasst 27 erfolgreich ausgeführte Rules-Tests.

### WG-Beitritt per Einladungscode

Der WG-Beitritt ist in `WgService.joinWg()` implementiert und wird als Firestore-Transaktion ausgeführt.

Vor dem Beitritt wird geprüft, ob der Benutzer bereits einer WG angehört und ob der angegebene Einladungscode existiert. Die Membership der WG und der zugehörige `userMemberships`-Eintrag werden anschließend innerhalb derselben Transaktion geschrieben.

Die Firestore Security Rules erlauben einem Benutzer nur das Anlegen seiner eigenen Membership und prüfen dabei die Beziehung zwischen Benutzer, WG, Einladungscode und `userMemberships`-Eintrag.

Die ausgelieferte Hauptversion benötigt für den WG-Beitritt keine Firebase Cloud Function. Eine zusätzliche serverseitige Umsetzung über Cloud Functions wurde als mögliche Härtungsoption betrachtet, ist jedoch nicht Bestandteil der Abgabeversion.

### Hardware-Anforderungen

- Es wird keine eigene Server-Hardware benötigt.
- Firebase stellt die verwendeten Cloud-Dienste bereit.
- Für Entwicklung und Deployment wird ein Entwicklungsrechner benötigt.
- Für die Nutzung genügt ein modernes Desktop- oder Mobilgerät mit Webbrowser und Internetzugang.

---

## Voraussetzungen für Entwicklung und Deployment

- Flutter SDK
- Firebase CLI
- Node.js und npm für die Firestore-Rules-Tests
- Zugriff auf das Firebase-Projekt `wg-shopsync`
- moderner Webbrowser
- Internetverbindung

Die Firebase-Konfiguration der Flutter-Anwendung befindet sich in `app/lib/firebase_options.dart`. Zusätzliche `.env`-Dateien oder projektspezifische Umgebungsvariablen sind für die Abgabeversion nicht erforderlich.

---

## Build und Qualitätssicherung

Aus dem Verzeichnis `app`:

    flutter pub get
    flutter analyze
    flutter test
    flutter build web

Der verifizierte Abgabestand:

- `flutter analyze`: keine Befunde
- `flutter test`: 230 Tests erfolgreich
- `flutter build web`: erfolgreich

Die Firestore Security Rules werden aus dem Repository-Stammverzeichnis mit dem Emulator geprüft:

    npm --prefix firestore-rules-tests ci
    firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"

Ergebnis des finalen Rules-Testlaufs:

- 27 Tests erfolgreich

---

## Deployment

Der Web-Build wird aus `app/build/web` über Firebase Hosting bereitgestellt.

Aus dem Repository-Stammverzeichnis:

    firebase deploy --only hosting --project wg-shopsync

Die produktive Anwendung ist erreichbar unter:

**https://wg-shopsync.web.app**

Die Firestore Security Rules werden separat veröffentlicht:

    firebase deploy --only firestore:rules --project wg-shopsync

Die Hosting-Konfiguration in `firebase.json` verwendet `app/build/web` als öffentliches Verzeichnis und leitet SPA-Routen auf `/index.html` um.

---

## Abschließende Funktionsprüfung

Für die Abnahme werden insbesondere folgende Abläufe geprüft:

- Registrierung und Anmeldung
- Erstellung einer WG
- Beitritt zu einer WG über Einladungscode
- Verlassen einer WG
- Erstellen, Bearbeiten und Statuswechsel von Einkaufsartikeln
- Synchronisation zwischen mehreren Clients
- Erfassen und Bearbeiten von Ausgaben
- Kostenaufteilung auf WG-Mitglieder
- Anzeige von Forderungen, Verbindlichkeiten und Schulden
- Markieren einer eigenen offenen Schuld als bezahlt
- Echtzeit-Aktualisierung der Kosten- und Schuldensicht
- Schutz vor Zugriff auf Daten einer fremden WG
- erneutes Laden der produktiven Hosting-Anwendung

---

## Erfolgsbedingungen

Die Inbetriebnahme gilt als erfolgreich, wenn:

- Benutzerkonten erstellt und verwendet werden können.
- Authentifizierung und Benutzersitzung funktionieren.
- WGs erstellt werden können.
- Benutzer einer WG über einen gültigen Einladungscode beitreten können.
- Einkaufslisten zwischen berechtigten Mitgliedern synchronisiert werden.
- Ausgaben und Kostenanteile korrekt gespeichert werden.
- Schulden und Salden korrekt angezeigt werden.
- eine eigene offene Schuld als bezahlt markiert werden kann.
- relevante Änderungen zwischen Clients ohne manuellen Seiten-Reload sichtbar werden.
- ein unberechtigter Zugriff auf Daten einer fremden WG verhindert wird.
- die Anwendung über Firebase Hosting erreichbar ist.
