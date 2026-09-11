# S3 – Inbetriebnahme

## Ziel

Dieses Kapitel beschreibt die erstmalige Bereitstellung und Inbetriebnahme von WG‑ShopSync.

Die Anwendung wird als responsive Webanwendung für moderne Desktop- und mobile Webbrowser bereitgestellt und verwendet Firebase Authentication sowie Cloud Firestore zur Speicherung und Synchronisation der Daten.

---

## Infrastruktur

Für den Betrieb von WG-ShopSync werden folgende Infrastrukturbestandteile benötigt. Die Beschreibung bleibt bewusst einfach gehalten, da eine detaillierte technische Architektur nicht Bestandteil dieses Kapitels ist.

### Firebase-Projekt

Für das gesamte Projektteam wird das gemeinsame zentrale Firebase-Projekt `wg-shopSync` mit der Project ID `wg-shopsync` verwendet. Die Projektmitglieder sind für dieses Firebase-Projekt berechtigt.

### Verwaltete Cloud-Dienste

- **Firebase Authentication**: Verwaltet Registrierung, Anmeldung und Benutzersitzungen.
- **Cloud Firestore**: Speichert WG-Daten und stellt Echtzeit-Synchronisation sowie Offline-Persistenz bereit.
- **Firebase Hosting**: Liefert den Flutter-Web-Build als statische Webanwendung über HTTPS aus.

### Datenbank-Infrastruktur

- **Cloud-Datenbank**: Cloud Firestore speichert alle Anwendungsdaten (Benutzer, WGs, Einkaufslisten, Ausgaben und Schulden) zentral und ermöglicht die Synchronisation zwischen den Browsern der Mitglieder.
- **Konfiguration**: Cloud Firestore wird in der Standard Edition in der Region `europe-west3` (Frankfurt) betrieben und wurde im Production Mode angelegt.
- **Initialisierung**: Collections und Dokumente werden nicht manuell in der Firebase Console angelegt, sondern durch die Anwendung während des laufenden Betriebs erzeugt.
- **Sicherungen**: Scheduled Backups sind aktuell nicht aktiviert.

### Authentifizierung

Firebase Authentication verwendet für den MVP die Anmeldung mit E-Mail und Passwort. Passwordless Email Link ist deaktiviert; weitere Social-Login-Provider gehören aktuell nicht zum MVP.

### Firestore Security Rules

Die versionierte Quelle der Firestore Security Rules ist [firestore.rules](../../firestore.rules) im Repository. Die Rules werden vor dem Deployment geprüft und anschließend in Firebase veröffentlicht.

Der Zugriff auf WG-spezifische Daten wird über Memberships eingeschränkt. Benutzer dürfen nur auf die vorgesehenen eigenen Daten sowie auf WG-bezogene Daten zugreifen, für die eine Membership besteht.

### WG-Beitritt per Einladungscode

Die aktuellen Security Rules verhindern bewusst, dass der Flutter-Client eine Membership in einer bestehenden WG direkt erstellt. Vor dem Erstellen einer Membership muss der Einladungscode durch einen vertrauenswürdigen Backend-Prozess validiert werden.

Für diesen Prozess kann später beispielsweise eine Firebase Cloud Function eingesetzt werden. Eine solche serverlose Funktion ist kein klassischer eigener App-Server und bleibt mit der vorgesehenen Firebase-Architektur vereinbar. Der sichere WG-Beitritt über Einladungscode ist aktuell noch nicht vollständig implementiert.

### Hardware-Anforderungen

- Es wird keine eigene physische Server-Hardware benötigt.
- Firebase Authentication und Cloud Firestore werden über einen Cloud-Anbieter bereitgestellt.
- Auf Nutzerseite wird lediglich ein Computer oder mobiles Endgerät mit einem modernen Webbrowser benötigt.

---

## Deployment-Schritte

1. Die Cloud-Datenbank wird eingerichtet und konfiguriert.
2. Firebase Authentication wird konfiguriert.
3. Die erforderlichen Umgebungsvariablen werden gesetzt.
4. Die Webanwendung wird als Flutter-Web-Build erstellt und über Firebase Hosting bereitgestellt.
5. Die Anwendung wird mit der produktiven Datenbank verbunden.
6. Abschließende Betriebs- und Funktionstests werden durchgeführt:
	- Registrierung eines Benutzers
	- Anmeldung mit E-Mail und Passwort
	- Erstellung einer WG
	- Prüfung der Firestore-Autorisierung
	- Synchronisation der Firestore-Daten zwischen Clients
	- Später: Test des WG-Beitritts über Einladungscode nach Umsetzung des vertrauenswürdigen Backend-Prozesses

---

## Voraussetzungen

- Flutter SDK installiert
- Ein moderner Webbrowser für die Nutzung und ein Entwicklungsrechner für den Web-Build
- Zugriff auf die Cloud-Datenbank
- Internetverbindung
- Konfigurierte Umgebungsvariablen

---

## Rollout-Strategie

- Zunächst erfolgt ein interner Test durch das Projektteam.
- Anschließend wird eine Beta-Version für ausgewählte Testnutzer bereitgestellt.
- Nach erfolgreicher Testphase erfolgt die Freigabe der produktiven Version.

---

## Erfolgsbedingungen

Die Inbetriebnahme gilt als erfolgreich, wenn:

- Benutzerkonten erstellt werden können.
- Die Anmeldung erfolgreich funktioniert.
- Wohngemeinschaften erstellt und verwaltet werden können.
- Einkaufslisten erstellt und synchronisiert werden können.
- Ausgaben gespeichert und angezeigt werden können.
- Die Synchronisation zwischen mehreren Geräten funktioniert.
- Kostenaufteilung, Schuldenanzeige und das Markieren einer Schuld als bezahlt funktionieren.
- Ein Zugriff auf Daten einer fremden WG wird verhindert.
