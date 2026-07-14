# S3 – Inbetriebnahme

## Ziel

Dieses Kapitel beschreibt die erstmalige Bereitstellung und Inbetriebnahme von WG‑ShopSync.

Die Anwendung wird als mobile Flutter-Anwendung für Android- und iOS-Geräte bereitgestellt und verwendet eine Cloud-Datenbank zur Speicherung und Synchronisation der Daten.

---

## Deployment-Schritte

1. Die Cloud-Datenbank wird eingerichtet und konfiguriert.
2. Der Authentifizierungsdienst wird konfiguriert.
3. Die erforderlichen Umgebungsvariablen werden gesetzt.
4. Die Flutter-Anwendung wird erstellt und für die Zielplattformen bereitgestellt.
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