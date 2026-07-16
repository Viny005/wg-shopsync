# N2 – Querschnittskonzepte

Dieses Kapitel beschreibt technische und fachliche Konzepte, die mehrere Teile des Systems betreffen.

Während F1 bis F3 die Funktionen des Systems beschreiben und D1 sowie D2 die Daten definieren, legt N2 fest, wie bestimmte Anforderungen systemweit umgesetzt werden.

Die beschriebenen Konzepte gelten für alle relevanten Anwendungsfälle von WG-ShopSync.

---

# N2.1 Authentifizierung

Die Authentifizierung stellt sicher, dass nur registrierte Benutzer auf die Anwendung zugreifen können.

Die Benutzeridentifikation erfolgt über E-Mail-Adresse und Passwort.

Die Authentifizierung wird von den Anwendungsfällen UC-01 (Registrieren) und UC-02 (Einloggen) verwendet.

## Regeln

- Jeder Benutzer besitzt eine eindeutige E-Mail-Adresse.
- Für den Login sind E-Mail-Adresse und Passwort erforderlich.
- Erfolgreiche Anmeldungen erzeugen eine Benutzersitzung.
- Nicht authentifizierte Benutzer können keine WG-Daten abrufen.

## Verwendet von

- UC-01 Registrieren
- UC-02 Einloggen

---

# N2.2 Autorisierung

Die Autorisierung regelt den Zugriff auf Funktionen und Daten innerhalb einer WG.

Die Rechte eines Benutzers ergeben sich aus seiner Membership innerhalb der jeweiligen WG.

## Rollen

### admin

Darf:

- Mitglieder verwalten
- die WG verwalten
- Einladungscodes erzeugen
- die WG auflösen

### member

Darf:

- Artikel verwalten
- Ausgaben verwalten
- Schulden einsehen
- Schulden als bezahlt markieren

## Regeln

- Jeder Benutzer besitzt pro WG genau eine Rolle.
- Die Rolle wird in Membership.role gespeichert.
- Ein Benutzer darf nur Funktionen ausführen, für die er berechtigt ist.

## Verwendet von

- UC-03 WG erstellen
- UC-04 WG beitreten
- UC-05 WG verlassen

---

# N2.3 Offline-Modus

WG-ShopSync soll auch bei fehlender Internetverbindung eingeschränkt nutzbar bleiben.

Bereits geladene Daten werden lokal zwischengespeichert.

## Regeln

- Die zuletzt synchronisierte Einkaufsliste bleibt verfügbar.
- Offline erfasste Änderungen werden lokal gespeichert.
- Nach Wiederherstellung der Verbindung erfolgt eine Synchronisation.
- Der Benutzer wird über den Offline-Modus informiert.

## Verwendet von

- UC-10 Einkaufsliste anzeigen
- UC-11 Daten synchronisieren

---

# N2.4 Synchronisation

Die Synchronisation gleicht lokale und serverseitige Datenstände ab.

Sie stellt sicher, dass alle Mitglieder derselben WG dieselben Informationen sehen.

## Regeln

- Änderungen werden nach Wiederherstellung einer Internetverbindung synchronisiert.
- Neue Einträge werden an alle Mitglieder verteilt.
- Statusänderungen werden synchronisiert.
- Ausgaben und Schulden werden synchronisiert.

## Konfliktbehandlung

Bei konkurrierenden Änderungen gilt:

```text
Server gewinnt
```

Der serverseitige Datenstand besitzt Vorrang.

## Verwendet von

- UC-06 Artikel hinzufügen
- UC-07 Artikel bearbeiten
- UC-08 Artikel löschen
- UC-09 Artikel als gekauft markieren
- UC-11 Daten synchronisieren

---

# N2.5 Fehlerbehandlung

Fehler sollen dem Benutzer verständlich dargestellt werden.

Technische Details werden nicht angezeigt.

## Arten von Fehlern

### Validierungsfehler

Beispiele:

- Pflichtfeld leer
- Ungültige E-Mail-Adresse
- Ungültiger Betrag

### Authentifizierungsfehler

Beispiele:

- Falsches Passwort
- Ungültige Zugangsdaten

### Netzwerkfehler

Beispiele:

- Keine Internetverbindung
- Server nicht erreichbar

### Synchronisationsfehler

Beispiele:

- Konflikt zwischen lokalem und serverseitigem Datenstand

## Regeln

- Fehlermeldungen müssen verständlich sein.
- Daten dürfen durch Fehler nicht verloren gehen.
- Der Benutzer erhält einen Hinweis zur Fehlerursache.

---

# N2.6 Datenvalidierung

Eingaben werden vor der Speicherung überprüft.

Nur gültige Daten dürfen dauerhaft gespeichert werden.

## Regeln

### Benutzer

- Name darf nicht leer sein.
- E-Mail-Adresse muss gültig sein.
- Passwort muss den Sicherheitsanforderungen entsprechen.

### WG

- Der Name darf nicht leer sein.
- Der Einladungscode muss eindeutig sein.

### Einkaufsliste

- Der Artikelname darf nicht leer sein.
- Mengenangaben müssen positiv sein.

### Ausgaben

- Betrag muss größer als 0 sein.
- Beschreibung darf nicht leer sein.

### Schulden

- Betrag muss größer als 0 sein.

---

# N2.7 Datenschutz und Passwortschutz

WG-ShopSync verarbeitet personenbezogene Daten der Benutzer.

Diese Daten müssen vor unberechtigtem Zugriff geschützt werden.

## Passwortschutz

- Passwörter werden niemals im Klartext gespeichert.
- Es wird ausschließlich ein Passwort-Hash gespeichert.
- Passwörter werden niemals angezeigt.

## Datenschutz

- Benutzer dürfen nur Daten ihrer eigenen WG sehen.
- Fremde WG-Daten dürfen nicht angezeigt werden.
- Persönliche Daten werden ausschließlich für die Nutzung der Anwendung verwendet.

## Verwendet von

- UC-01 Registrieren
- UC-02 Einloggen
- Alle WG-bezogenen Anwendungsfälle

---

# N2.8 Sitzungsverwaltung

Nach erfolgreicher Anmeldung erhält der Benutzer eine aktive Sitzung.

Während einer aktiven Sitzung muss sich der Benutzer nicht erneut anmelden.

## Regeln

- Geschützte Funktionen erfordern eine aktive Sitzung.
- Nach dem Abmelden wird die Sitzung beendet.
- Ungültige Sitzungen werden automatisch verworfen.

## Verwendet von

- UC-02 Einloggen
- Alle nachfolgenden Anwendungsfälle

---

# N2.9 Zusammenfassung

Die Querschnittskonzepte definieren:

- Authentifizierung
- Autorisierung
- Offline-Modus
- Synchronisation
- Fehlerbehandlung
- Datenvalidierung
- Datenschutz
- Sitzungsverwaltung

Diese Konzepte gelten systemweit und unterstützen die Umsetzung der funktionalen Anforderungen aus F1 bis F3 sowie die Datenmodelle aus D1 und D2.