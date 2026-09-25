# WG-ShopSync

WG-ShopSync ist eine browserbasierte Webanwendung für Wohngemeinschaften zur gemeinsamen Organisation von Einkaufslisten, Ausgaben, Kostenanteilen und Schulden.

Das Projekt wurde im Rahmen des Moduls **WK_1106 – Projekt I** entwickelt.

## Live-Anwendung

Die produktive Webanwendung ist über Firebase Hosting erreichbar:

**https://wg-shopsync.web.app**

## Projektstatus

Die Anwendung liegt als funktionsfähiger MVP vor.

Die wesentlichen Anwendungsfälle UC-01 bis UC-16 sind implementiert. Dazu gehören Authentifizierung, WG-Verwaltung, gemeinsame Einkaufslisten, Ausgabenverwaltung, Kostenaufteilung, Schuldenverwaltung sowie Echtzeit-Synchronisation.

Der aktuelle technische Stand wurde unter anderem mit folgenden Prüfungen verifiziert:

* `flutter analyze`: keine Fehler
* `flutter test`: 230 Tests erfolgreich
* `flutter build web`: erfolgreich
* Firestore Security Rules: 27 Tests erfolgreich
* manueller End-to-End-Test mit Firebase Authentication, Cloud Firestore und Firebase Hosting

## Funktionsumfang

### Authentifizierung

* Registrierung mit E-Mail und Passwort
* Anmeldung und Abmeldung
* persistente Firebase-Authentifizierungssitzung

### WG-Verwaltung

* WG erstellen
* eindeutigen Einladungscode erzeugen
* WG über Einladungscode beitreten
* eigene WG-Zugehörigkeit verwalten
* WG verlassen
* Rollen `admin` und `member`
* maximal eine aktive WG-Mitgliedschaft pro Benutzer

Der WG-Beitritt wird als atomare Firestore-Transaktion ausgeführt. Firestore Security Rules prüfen dabei unter anderem die Benutzeridentität, den Einladungscode und die zugehörige WG-Mitgliedschaft.

### Einkaufsliste

* Einkaufsartikel hinzufügen
* Artikel bearbeiten
* Artikel löschen
* Artikel als gekauft markieren
* Kategorien und Mengen verwalten
* Änderungen zwischen mehreren Clients nahezu in Echtzeit synchronisieren
* bereits synchronisierte Daten über Firestore Offline-Persistenz lokal verfügbar halten

### Ausgaben und Kostenaufteilung

* gemeinsame Ausgaben erfassen
* bestehende Ausgaben bearbeiten
* Beteiligte auswählen
* Kosten cent-genau aufteilen
* `ExpenseShare`-Einträge erzeugen und aktualisieren
* aus Kostenanteilen Schulden ableiten

### Schulden und Salden

* offene und bezahlte Schulden anzeigen
* persönliche Forderungen und Verbindlichkeiten berechnen
* eigene offene Schuld als bezahlt markieren
* bezahlte Schulden vor nachträglicher Veränderung schützen
* Änderungen am Schuldenstatus in Echtzeit zwischen Clients synchronisieren

Eine tatsächliche Zahlung oder Banküberweisung findet nicht statt. WG-ShopSync dokumentiert ausschließlich die Kostenaufteilung und den Zahlungsstatus.

## Technologien

* **Frontend / Anwendung:** Flutter Web
* **Programmiersprache:** Dart
* **Authentifizierung:** Firebase Authentication
* **Datenbank:** Cloud Firestore
* **Hosting:** Firebase Hosting
* **Security:** Firestore Security Rules
* **Rules-Tests:** Firebase Emulator Suite, Mocha und `@firebase/rules-unit-testing`
* **Versionsverwaltung:** Git und GitHub

## Projektstruktur

```text
wg-shopsync/
├── app/                      Flutter-Webanwendung
├── docs/
│   ├── spec/                 Fachliche Gesamtspezifikation
│   └── arch/                 Architekturdokumentation nach arc42
├── firestore-rules-tests/    Automatisierte Tests der Firestore Rules
├── firestore.rules           Firestore Security Rules
├── firebase.json             Firebase- und Hosting-Konfiguration
├── .firebaserc               Firebase-Projektzuordnung
├── TEAMINFO.md               Team- und Projektinformationen
└── README.md
```

## Lokale Inbetriebnahme

Vorausgesetzt werden ein installiertes Flutter SDK sowie ein moderner Webbrowser.

```bash
cd app
flutter pub get
flutter run -d chrome
```

Die Anwendung verwendet das konfigurierte Firebase-Projekt `wg-shopsync`.

## Qualitätssicherung

### Flutter

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build web
```

### Firestore Security Rules

Die Rules-Tests werden gegen den lokalen Firestore Emulator ausgeführt:

```bash
npm --prefix firestore-rules-tests ci
firebase emulators:exec --only firestore "npm --prefix firestore-rules-tests test"
```

Der aktuelle Teststand umfasst **27 erfolgreich ausgeführte Firestore-Rules-Tests**.

## Deployment

Der Flutter-Web-Build wird mit folgendem Befehl erstellt:

```bash
cd app
flutter build web
cd ..
```

Deployment über Firebase Hosting:

```bash
firebase deploy --only hosting --project wg-shopsync
```

Deployment der Firestore Security Rules:

```bash
firebase deploy --only firestore:rules --project wg-shopsync
```

Die Hosting-Konfiguration verwendet `app/build/web` und einen SPA-Rewrite auf `/index.html`.

## Dokumentation

Die vollständige fachliche Spezifikation befindet sich unter:

[docs/spec/README.md](docs/spec/README.md)

Die Architekturdokumentation ist nach arc42 strukturiert:

* [A01 – Einführung und Ziele](docs/arch/A01-einfuehrung-und-ziele.md)
* [A02 – Randbedingungen](docs/arch/A02-randbedingungen.md)
* [A03 – Kontextabgrenzung](docs/arch/A03-kontextabgrenzung.md)
* [A04 – Lösungsstrategie](docs/arch/A04-loesungsstrategie.md)
* [A05 – Bausteinsicht](docs/arch/A05-bausteinsicht.md)
* [A06 – Laufzeitsicht](docs/arch/A06-laufzeitsicht.md)
* [A07 – Verteilungssicht](docs/arch/A07-verteilungssicht.md)
* [A08 – Querschnittliche Konzepte](docs/arch/A08-querschnittliche-konzepte.md)
* [A09 – Architekturentscheidungen](docs/arch/A09-architekturentscheidungen.md)
* [A12 – Glossar](docs/arch/A12-glossar.md)
* [A13 – Eingesetzte KI-Werkzeuge](docs/arch/A13-ki-werkzeuge.md)

## KI-Unterstützung

Im Projekt wurden GitHub Copilot, Claude und ChatGPT unterstützend eingesetzt. GitHub Copilot wurde für Code-Vervollständigung und Implementierung genutzt, Claude insbesondere für die Präzisierung von Anforderungen und Markdown-Dokumentation und ChatGPT für Dokumentation, Refactoring, Tests sowie Konsistenzprüfungen.

Die fachliche und technische Verantwortung für die übernommenen Ergebnisse verbleibt beim Projektteam. Details sind in [E3 – Eingesetzte KI-Werkzeuge](docs/spec/E3-eingesetzte-ki-werkzeuge.md) und [A13 – Eingesetzte KI-Werkzeuge in Architektur und Entwicklung](docs/arch/A13-ki-werkzeuge.md) dokumentiert.

## Team

Die Teammitglieder und Rollen sind in [TEAMINFO.md](TEAMINFO.md) dokumentiert.
