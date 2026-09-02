# S1 – Nachbarsysteme

## Übersicht

| ID | Nachbarsystem | Zweck | Richtung |
|----|---------------|-------|----------|
| NB-01 | Firebase Authentication | Registrierung und Anmeldung von Benutzern | bidirektional |
| NB-02 | Cloud Firestore | Speicherung und Echtzeit-Synchronisation der WG-Daten | bidirektional |

---

## NB-01 – Firebase Authentication

### Zweck

Firebase Authentication ist ein externes Nachbarsystem von WG-ShopSync.

Es stellt Funktionen zur Registrierung, Anmeldung und Verwaltung von Benutzerkonten bereit.

### Verwendet von

- UC-01 Registrieren
- UC-02 Einloggen

### Ausgetauschte Informationen

- E-Mail-Adresse
- Passwort bzw. Authentifizierungsdaten
- Benutzer-ID
- Authentifizierungsstatus

### Schnittstelle

- Firebase Authentication SDK

---

## NB-02 – Cloud Firestore

### Zweck

Cloud Firestore ist das externe Nachbarsystem für die zentrale Speicherung und Synchronisation der Anwendungsdaten.

### Verwendet von

- UC-03 bis UC-16
- AF-01 bis AF-06
- N2.3 Offline-Modus
- N2.4 Synchronisation

### Ausgetauschte Informationen

- WG- und Mitgliedschaftsdaten
- Einkaufslistenartikel
- Ausgaben und Kostenanteile
- Schulden und Zahlungsstatus

### Schnittstelle

- Firebase Cloud Firestore SDK
- Firestore Security Rules zur Zugriffskontrolle

---

## Nachbarsystem-Diagramm

```mermaid
flowchart LR
    U[WG-Mitglied] --> A[WG-ShopSync Flutter-App]
    A <--> AUTH[Firebase Authentication]
    A <--> DB[Cloud Firestore]
```
