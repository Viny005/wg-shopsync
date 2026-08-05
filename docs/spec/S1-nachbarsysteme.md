# S1 – Nachbarsysteme

## Übersicht

| ID | Nachbarsystem | Zweck | Richtung |
|----|---------------|-------|----------|
| NB-01 | Cloud-Datenbank | Persistenz und Synchronisation | bidirektional |
| NB-02 | Push-Notification-Dienst (z. B. Firebase Cloud Messaging) | Benachrichtigungen über Änderungen | ausgehend |
| NB-03 | Externes Notizbuch (Notion) | Export von Einkaufslisteneinträgen in ein persönliches Notizbuch | ausgehend |

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

### Datenfluss

| Aspekt | Beschreibung |
|--------|--------------|
| Richtung | Bidirektional (WG-ShopSync ↔ Cloud-Datenbank) |
| Übertragene Daten | Benutzerkonten, WG- und Membership-Daten, Einkaufslisten-Einträge, Ausgaben, Kostenanteile, Schulden |
| Auslöser | Jede Erstellung, Änderung oder Löschung einer Entität (z. B. neuer Artikel, neue Ausgabe, Statusänderung) |
| Häufigkeit | Bei jeder Datenänderung sowie bei erneuter Synchronisation nach Offline-Phasen |

---

## NB-02 – Push-Notification-Dienst

### Zweck

Versand von Benachrichtigungen bei relevanten Änderungen.

### Verwendet von

- UC-06 bis UC-11 Einkaufsliste
- UC-13 bis UC-15 Kostenverwaltung

### Schnittstelle

- Firebase Cloud Messaging (FCM)

### Datenfluss

| Aspekt | Beschreibung |
|--------|--------------|
| Richtung | Ausgehend (WG-ShopSync → Push-Notification-Dienst → Endgerät der Mitglieder) |
| Übertragene Daten | Kurzbenachrichtigung (Titel, Nachrichtentext), keine sensiblen Nutzdaten wie Beträge im Klartext |
| Auslöser | Neuer Artikel, Statusänderung eines Artikels, neue Ausgabe, aktualisierte Schuld |
| Häufigkeit | Ereignisbasiert, unmittelbar nach der jeweiligen Änderung |

---

## NB-03 – Externes Notizbuch (Notion)

### Zweck

Ermöglicht Mitgliedern den Export von Einträgen der gemeinsamen Einkaufsliste in ein persönliches, externes Notizbuch (Notion), um Einkäufe zusätzlich außerhalb der Anwendung nachvollziehen zu können.

### Verwendet von

- UC-10 Einkaufsliste anzeigen (optionaler Export)

### Schnittstelle

- Notion API (REST, OAuth-basierte Authentifizierung)

### Datenfluss

| Aspekt | Beschreibung |
|--------|--------------|
| Richtung | Ausgehend (WG-ShopSync → Notion) |
| Übertragene Daten | Artikelname, Menge, Kategorie, Status des jeweiligen Einkaufslisteneintrags |
| Auslöser | Manueller Export durch das Mitglied |
| Häufigkeit | On-Demand, ausschließlich auf Anforderung des Benutzers |

### Einschränkungen

- Der Export ist einseitig (kein Rückkanal von Notion in WG-ShopSync).
- Die Anbindung erfordert eine gültige Notion-Verbindung (OAuth-Autorisierung) des jeweiligen Benutzers.
- Der Export bezieht sich ausschließlich auf die Einkaufsliste, nicht auf Ausgaben oder Schulden.
