# S1 – Nachbarsysteme

## Übersicht

| ID | Nachbarsystem | Zweck | Richtung |
|----|---------------|-------|----------|
| NB-01 | Cloud-Datenbank | Persistenz und Synchronisation | bidirektional |
| NB-02 | Push-Notification-Dienst (z. B. Firebase Cloud Messaging) | Benachrichtigungen über Änderungen | ausgehend |

---

## NB-01 – Cloud-Datenbank

### Zweck

Speicherung und Synchronisation aller Anwendungsdaten.

### Verwendet von

- UC-01 Registrieren
- UC-02 Einloggen
- UC-03 bis UC-15

### Schnittstelle

- REST API oder Firebase SDK

---

## NB-02 – Push-Notification-Dienst

### Zweck

Versand von Benachrichtigungen bei relevanten Änderungen.

### Verwendet von

- UC-06 bis UC-11 Einkaufsliste
- UC-13 bis UC-15 Kostenverwaltung

### Schnittstelle

- Firebase Cloud Messaging (FCM)
