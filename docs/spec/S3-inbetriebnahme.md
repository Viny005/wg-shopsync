# S3 – Inbetriebnahme

## Ziel

Dieses Kapitel beschreibt die erstmalige Bereitstellung und Inbetriebnahme von WG‑ShopSync.

Die Anwendung wird als Flutter-Anwendung für Android, iOS und Webbrowser bereitgestellt und verwendet Firebase Authentication sowie Cloud Firestore zur Speicherung und Synchronisation der Daten.

---

## Infrastruktur

Für den Betrieb von WG-ShopSync werden folgende Infrastrukturbestandteile benötigt. Die Beschreibung bleibt bewusst einfach gehalten, da eine detaillierte technische Architektur nicht Bestandteil dieses Kapitels ist.

### Server-Komponenten

- **Firebase Authentication**: Verwaltet Registrierung, Anmeldung und Benutzersitzungen.
- **Cloud Firestore**: Speichert WG-Daten und stellt Echtzeit-Synchronisation sowie Offline-Persistenz bereit.

### Datenbank-Infrastruktur

- **Cloud-Datenbank**: Cloud Firestore speichert alle Anwendungsdaten (Benutzer, WGs, Einkaufslisten, Ausgaben und Schulden) zentral und ermöglicht die Synchronisation zwischen den Geräten der Mitglieder.

### Hardware-Anforderungen

- Es wird keine eigene physische Server-Hardware benötigt.
- Firebase Authentication und Cloud Firestore werden über einen Cloud-Anbieter bereitgestellt.
- Auf Nutzerseite wird lediglich ein internetfähiges Smartphone, Tablet oder ein Computer mit Webbrowser benötigt.

---

## Deployment-Schritte

1. Die Cloud-Datenbank wird eingerichtet und konfiguriert.
2. Firebase Authentication wird konfiguriert.
3. Die erforderlichen Umgebungsvariablen werden gesetzt.
4. Die Flutter-Anwendung wird erstellt und für Android, iOS und Web bereitgestellt.
5. Die Anwendung wird mit der produktiven Datenbank verbunden.
6. Abschließende Funktionstests werden durchgeführt.

---

## Voraussetzungen

- Flutter SDK installiert
- Android Studio oder Xcode installiert
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
