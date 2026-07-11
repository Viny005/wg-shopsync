# F2 – Anwendungsfälle

F2 beschreibt die Anwendungsfälle von WG-ShopSync. Anwendungsfälle sind konkrete Interaktionsszenarien zwischen einem Benutzer und dem System, die jeweils ein benutzerrelevantes Ziel verfolgen und in einem stabilen Zustand enden.

Systeminterne Schritte ohne direkten Entscheidungspunkt des Benutzers, wie beispielsweise die Erzeugung eines Einladungscodes, die Berechnung von Kostenanteilen oder die Synchronisation von Daten, werden nicht als eigenständige Anwendungsfälle modelliert, sondern als Bestandteile bestehender Anwendungsfälle oder als Anwendungsfunktionen in F3 beschrieben.

---

## F2.1 Übersicht

| ID | Anwendungsfall | Gruppe | Priorität |
|----|---------------|----------|----------|
| UC-01 | Registrieren | Authentifizierung | Hoch (MVP) |
| UC-02 | Einloggen | Authentifizierung | Hoch (MVP) |
| UC-03 | WG erstellen | WG-Verwaltung | Hoch (MVP) |
| UC-04 | WG beitreten | WG-Verwaltung | Hoch (MVP) |
| UC-05 | WG verlassen | WG-Verwaltung | Mittel |
| UC-06 | Artikel hinzufügen | Einkaufsliste | Hoch (MVP) |
| UC-07 | Artikel bearbeiten | Einkaufsliste | Mittel |
| UC-08 | Artikel löschen | Einkaufsliste | Mittel |
| UC-09 | Artikel als gekauft markieren | Einkaufsliste | Hoch (MVP) |
| UC-10 | Einkaufsliste anzeigen | Einkaufsliste | Hoch (MVP) |
| UC-11 | Ausgabe erfassen | Kostenverwaltung | Hoch (Bonus) |
| UC-12 | Ausgabe bearbeiten | Kostenverwaltung | Mittel |
| UC-13 | Kosten aufteilen | Kostenverwaltung | Hoch (Bonus) |
| UC-14 | Schulden anzeigen | Kostenverwaltung | Hoch (Bonus) |
| UC-15 | Schuld als bezahlt markieren | Kostenverwaltung | Hoch (Bonus) |
| UC-16 | Kostenübersicht anzeigen | Kostenverwaltung | Hoch (Bonus) |

---

# F2.2 Benutzer und Authentifizierung

## UC-01 – Registrieren

### Beschreibung
Ein neuer Benutzer legt ein persönliches Benutzerkonto an.

### Auslöser
Der Benutzer möchte WG-ShopSync zum ersten Mal nutzen.

### Akteure
Nicht registrierter Benutzer.

### Vorbedingung
Es existiert kein Benutzerkonto mit der verwendeten E-Mail-Adresse.

### Nachbedingung
Ein Benutzerkonto wurde erstellt und der Benutzer ist angemeldet.

### Hauptszenario

1. Benutzer öffnet die Registrierung.
2. Benutzer gibt Name, E-Mail-Adresse und Passwort ein.
3. Benutzer bestätigt die Eingaben.
4. System prüft die Eingaben.
5. System erstellt das Benutzerkonto.
6. Benutzer wird angemeldet.

### Ausnahmeszenarien

- E-Mail-Adresse wird bereits verwendet.
- Passwort erfüllt die Anforderungen nicht.
- Keine Internetverbindung.

---

## UC-02 – Einloggen

### Beschreibung
Ein registrierter Benutzer meldet sich am System an.

### Auslöser
Der Benutzer möchte auf sein Konto zugreifen.

### Akteure
Registrierter Benutzer.

### Vorbedingung
Ein Benutzerkonto existiert.

### Nachbedingung
Der Benutzer ist angemeldet.

### Hauptszenario

1. Benutzer öffnet die Login-Seite.
2. Benutzer gibt E-Mail-Adresse und Passwort ein.
3. Benutzer tippt auf „Einloggen“.
4. System prüft die Zugangsdaten.
5. System meldet den Benutzer an.

### Ausnahmeszenarien

- Falsche Zugangsdaten.
- Keine Internetverbindung.

---

# F2.3 WG-Verwaltung

## UC-03 – WG erstellen

### Beschreibung
Ein Benutzer erstellt eine neue Wohngemeinschaft.

### Auslöser
Der Benutzer möchte eine neue WG anlegen.

### Akteure
Angemeldeter Benutzer.

### Vorbedingung
Benutzer ist angemeldet.

### Nachbedingung
Die WG wurde erstellt und der Benutzer ist Mitglied der WG.

### Hauptszenario

1. Benutzer wählt „WG erstellen“.
2. Benutzer gibt einen WG-Namen ein.
3. Benutzer bestätigt die Eingabe.
4. System erstellt die WG.
5. System erzeugt einen Einladungscode.
6. Benutzer gelangt zur WG-Ansicht.

---

## UC-04 – WG beitreten

### Beschreibung
Ein Benutzer tritt einer bestehenden WG bei.

### Auslöser
Der Benutzer besitzt einen Einladungscode.

### Akteure
Angemeldeter Benutzer.

### Vorbedingung
Eine WG mit gültigem Einladungscode existiert.

### Nachbedingung
Der Benutzer ist Mitglied der WG.

### Hauptszenario

1. Benutzer öffnet „WG beitreten“.
2. Benutzer gibt den Einladungscode ein.
3. System prüft den Code.
4. Benutzer bestätigt den Beitritt.
5. System fügt den Benutzer der WG hinzu.

### Ausnahmeszenarien

- Einladungscode ungültig.
- Einladungscode nicht vorhanden.

---

## UC-05 – WG verlassen

### Beschreibung
Ein Mitglied verlässt eine Wohngemeinschaft.

### Auslöser
Das Mitglied möchte die WG verlassen.

### Akteure
WG-Mitglied.

### Vorbedingung
Benutzer ist Mitglied einer WG.

### Nachbedingung
Die Mitgliedschaft wurde entfernt.

### Hauptszenario

1. Mitglied öffnet die WG-Einstellungen.
2. Mitglied wählt „WG verlassen“.
3. System zeigt eine Bestätigung.
4. Mitglied bestätigt.
5. System entfernt die Mitgliedschaft.

---

# F2.4 Einkaufsliste

## UC-06 – Artikel hinzufügen

### Beschreibung
Ein Mitglied fügt einen Artikel zur gemeinsamen Einkaufsliste hinzu.

### Auslöser
Ein Produkt wird benötigt.

### Akteure
WG-Mitglied.

### Vorbedingung
Benutzer ist Mitglied einer WG.

### Nachbedingung
Der Artikel erscheint auf der Einkaufsliste.

### Hauptszenario

1. Mitglied öffnet die Einkaufsliste.
2. Mitglied wählt „Artikel hinzufügen“.
3. Mitglied gibt Name, Menge und Kategorie ein.
4. Mitglied bestätigt die Eingabe.
5. System speichert den Artikel.

---

## UC-07 – Artikel bearbeiten

### Beschreibung
Ein Mitglied bearbeitet einen vorhandenen Artikel.

### Auslöser
Die Informationen eines Artikels sollen geändert werden.

### Akteure
WG-Mitglied.

### Vorbedingung
Artikel existiert.

### Nachbedingung
Die Änderungen wurden gespeichert.

### Hauptszenario

1. Mitglied wählt einen Artikel aus.
2. Mitglied bearbeitet die Daten.
3. Mitglied speichert die Änderungen.
4. System aktualisiert den Artikel.

---

## UC-08 – Artikel löschen

### Beschreibung
Ein Mitglied löscht einen Artikel aus der Einkaufsliste.

### Auslöser
Der Artikel wird nicht mehr benötigt.

### Akteure
WG-Mitglied.

### Vorbedingung
Artikel existiert.

### Nachbedingung
Der Artikel wurde gelöscht.

### Hauptszenario

1. Mitglied wählt einen Artikel aus.
2. Mitglied wählt „Löschen“.
3. System zeigt eine Bestätigung.
4. Mitglied bestätigt.
5. System löscht den Artikel.

---

## UC-09 – Artikel als gekauft markieren

### Beschreibung
Ein Mitglied markiert einen Artikel als gekauft.

### Auslöser
Der Artikel wurde eingekauft.

### Akteure
WG-Mitglied.

### Vorbedingung
Artikel besitzt den Status „Offen“.

### Nachbedingung
Der Artikel besitzt den Status „Gekauft“.

### Hauptszenario

1. Mitglied öffnet die Einkaufsliste.
2. Mitglied markiert einen Artikel.
3. System setzt den Status auf „Gekauft“.
4. System aktualisiert die Liste.

---

## UC-10 – Einkaufsliste anzeigen

### Beschreibung
Ein Mitglied betrachtet die aktuelle Einkaufsliste.

### Auslöser
Das Mitglied möchte Einkäufe prüfen.

### Akteure
WG-Mitglied.

### Vorbedingung
Mitgliedschaft in einer WG.

### Nachbedingung
Die Einkaufsliste wird angezeigt.

### Hauptszenario

1. Mitglied öffnet die Einkaufsliste.
2. System lädt die vorhandenen Artikel.
3. System zeigt die Liste an.

---

# F2.5 Kostenverwaltung

## UC-11 – Ausgabe erfassen

### Beschreibung
Ein Mitglied erfasst eine gemeinsame Ausgabe.

### Auslöser
Ein Mitglied hat einen Einkauf bezahlt.

### Akteure
WG-Mitglied.

### Vorbedingung
Mitgliedschaft in einer WG.

### Nachbedingung
Die Ausgabe wurde gespeichert.

### Hauptszenario

1. Mitglied öffnet den Bereich „Ausgaben“.
2. Mitglied erstellt eine neue Ausgabe.
3. Mitglied gibt Betrag und Beschreibung ein.
4. Mitglied wählt die beteiligten Mitglieder.
5. System speichert die Ausgabe.

---

## UC-12 – Ausgabe bearbeiten

### Beschreibung
Eine bestehende Ausgabe wird geändert.

### Auslöser
Fehlerhafte Angaben müssen korrigiert werden.

### Akteure
WG-Mitglied.

### Vorbedingung
Ausgabe existiert.

### Nachbedingung
Die Ausgabe wurde aktualisiert.

### Hauptszenario

1. Mitglied öffnet eine Ausgabe.
2. Mitglied bearbeitet die Daten.
3. Mitglied speichert die Änderungen.
4. System aktualisiert die Ausgabe.

---

## UC-13 – Kosten aufteilen

### Beschreibung
Eine Ausgabe wird auf alle oder ausgewählte Mitglieder verteilt.

### Auslöser
Eine Ausgabe wurde erfasst.

### Akteure
WG-Mitglied.

### Vorbedingung
Ausgabe existiert.

### Nachbedingung
Kostenanteile wurden berechnet.

### Hauptszenario

1. Mitglied öffnet eine Ausgabe.
2. Mitglied wählt die beteiligten Mitglieder aus.
3. System berechnet die Anteile.
4. System speichert die Aufteilung.
5. System aktualisiert die Salden.

---

## UC-14 – Schulden anzeigen

### Beschreibung
Ein Mitglied zeigt offene und bereits bezahlte Schulden an.

### Auslöser
Das Mitglied möchte seine Verbindlichkeiten prüfen.

### Akteure
WG-Mitglied.

### Vorbedingung
Mindestens eine Kostenaufteilung existiert.

### Nachbedingung
Die Schuldenübersicht wird angezeigt.

### Hauptszenario

1. Mitglied öffnet die Schuldenübersicht.
2. System lädt die Schulden.
3. System zeigt Betrag, Gläubiger und Status an.

---

## UC-15 – Schuld als bezahlt markieren

### Beschreibung
Ein Mitglied markiert eine offene Schuld als bezahlt.

### Auslöser
Die Schuld wurde beglichen.

### Akteure
WG-Mitglied.

### Vorbedingung
Eine offene Schuld existiert.

### Nachbedingung
Die Schuld besitzt den Status „Bezahlt“.

### Hauptszenario

1. Mitglied öffnet die Schuldenübersicht.
2. Mitglied wählt eine Schuld aus.
3. Mitglied tippt auf „Als bezahlt markieren“.
4. System setzt den Status auf „Bezahlt“.
5. System speichert das Zahlungsdatum.

---

## UC-16 – Kostenübersicht anzeigen

### Beschreibung
Ein Mitglied betrachtet alle Ausgaben, Kostenanteile und Salden der WG.

### Auslöser
Das Mitglied möchte die finanzielle Situation der WG prüfen.

### Akteure
WG-Mitglied.

### Vorbedingung
Mindestens eine Ausgabe existiert.

### Nachbedingung
Keine Zustandsänderung.

### Hauptszenario

1. Mitglied öffnet die Kostenübersicht.
2. System zeigt alle Ausgaben an.
3. System zeigt die aktuellen Salden an.
4. System zeigt offene und bezahlte Schulden an.
5. Mitglied kann Detailinformationen aufrufen.