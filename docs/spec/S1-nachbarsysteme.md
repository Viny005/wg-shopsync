# S1 – Nachbarsysteme

## Übersicht

| ID | Nachbarsystem | Zweck | Richtung |
|----|---------------|-------|----------|
| NB-01 | Firebase Authentication | Registrierung und Anmeldung von Benutzern | bidirektional |

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

## Nachbarsystem-Diagramm

​```text
Benutzer
    │
    ▼
WG-ShopSync
    │
    ▼
Firebase Authentication
​```
