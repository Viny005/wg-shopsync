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

## Use-Case-Diagramm

![Use-Case-Diagramm von WG-ShopSync](images/anwendungsfaelle-diagramm.png)

Das Use-Case-Diagramm visualisiert die Akteure und die in diesem Kapitel beschriebenen Anwendungsfälle. Die detaillierten Beschreibungen der Anwendungsfälle UC-01 bis UC-16 befinden sich in den folgenden Abschnitten dieses Dokuments.

---

# F2.2 Benutzer und Authentifizierung

### UC-01 – Registrieren

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-01 |
| Name | Registrieren |
| Ziel | Ein neuer Benutzer erstellt ein Benutzerkonto für WG-ShopSync. |
| Akteur | Nicht registrierter Benutzer |
| Auslöser | Der Benutzer möchte WG-ShopSync erstmals nutzen. |
| Vorbedingung | Es existiert kein Benutzerkonto mit der verwendeten E-Mail-Adresse. |
| Nachbedingung | Das Benutzerkonto wurde erstellt und der Benutzer ist angemeldet. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer öffnet die Registrierungsseite. |
| 2 | Benutzer gibt Name, E-Mail-Adresse und Passwort ein. |
| 3 | Benutzer bestätigt die Eingaben. |
| 4 | System prüft die Eingaben. |
| 5 | System erstellt das Benutzerkonto. |
| 6 | System meldet den Benutzer automatisch an. |
| 7 | Die WG-Übersicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – E-Mail-Adresse bereits vergeben

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer gibt eine bereits registrierte E-Mail-Adresse ein. |
| 2 | System erkennt die vorhandene Registrierung. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Benutzer kann eine andere E-Mail-Adresse eingeben. |

---

## UC-02 – Einloggen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-02 |
| Name | Einloggen |
| Ziel | Ein registrierter Benutzer meldet sich am System an. |
| Akteur | Benutzer |
| Auslöser | Der Benutzer möchte auf sein Konto zugreifen. |
| Vorbedingung | Ein Benutzerkonto existiert. |
| Nachbedingung | Der Benutzer ist erfolgreich angemeldet und erhält Zugriff auf seine WG-Daten. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer öffnet die Login-Seite. |
| 2 | Benutzer gibt E-Mail-Adresse und Passwort ein. |
| 3 | Benutzer startet den Anmeldevorgang. |
| 4 | System prüft die Zugangsdaten. |
| 5 | System meldet den Benutzer an. |
| 6 | Die WG-Übersicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Falsche Zugangsdaten

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer gibt eine ungültige E-Mail-Adresse oder ein falsches Passwort ein. |
| 2 | System erkennt die ungültigen Zugangsdaten. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Benutzer kann die Eingaben korrigieren. |
| 5 | Benutzer versucht erneut, sich anzumelden. |

---

# F2.3 WG-Verwaltung

## UC-03 – WG erstellen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-03 |
| Name | WG erstellen |
| Ziel | Ein angemeldeter Benutzer erstellt eine neue Wohngemeinschaft. |
| Akteur | Benutzer |
| Auslöser | Der Benutzer möchte eine neue WG anlegen. |
| Vorbedingung | Der Benutzer ist angemeldet. |
| Nachbedingung | Die WG wurde erstellt, der Benutzer ist Mitglied der WG und besitzt die Rolle „WG-Ersteller“. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer wählt „WG erstellen“. |
| 2 | Benutzer gibt einen Namen für die Wohngemeinschaft ein. |
| 3 | Benutzer bestätigt die Eingabe. |
| 4 | System erstellt die Wohngemeinschaft. |
| 5 | System erzeugt einen Einladungscode. |
| 6 | System ordnet dem Benutzer die Rolle „WG-Ersteller“ zu. |
| 7 | Die WG-Übersicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Ungültiger WG-Name

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer gibt keinen oder einen ungültigen WG-Namen ein. |
| 2 | System erkennt die fehlerhafte Eingabe. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Benutzer korrigiert die Eingabe. |

#### A3 – Technischer Fehler

| Nr. | Aktivität |
|------|-----------|
| 1 | Das System kann die WG nicht anlegen. |
| 2 | System zeigt eine Fehlermeldung an. |
| 3 | Der Benutzer kann den Vorgang erneut ausführen. |
---

## UC-04 – WG beitreten

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-04 |
| Name | WG beitreten |
| Ziel | Ein angemeldeter Benutzer tritt einer bestehenden Wohngemeinschaft bei. |
| Akteur | Benutzer |
| Auslöser | Der Benutzer besitzt einen Einladungscode einer bestehenden WG. |
| Vorbedingung | Eine WG mit gültigem Einladungscode existiert. |
| Nachbedingung | Der Benutzer ist Mitglied der WG und hat Zugriff auf die gemeinsamen Daten der WG. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer öffnet die Funktion „WG beitreten“. |
| 2 | Benutzer gibt den Einladungscode ein. |
| 3 | System prüft den Einladungscode. |
| 4 | System zeigt die gefundene WG an. |
| 5 | Benutzer bestätigt den Beitritt. |
| 6 | System fügt den Benutzer der WG hinzu. |
| 7 | Die WG-Übersicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Ungültiger Einladungscode

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer gibt einen ungültigen Einladungscode ein. |
| 2 | System erkennt den ungültigen Code. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Benutzer kann einen anderen Code eingeben. |

#### A2 – Einladungscode nicht vorhanden

| Nr. | Aktivität |
|------|-----------|
| 1 | Benutzer gibt einen nicht existierenden Einladungscode ein. |
| 2 | System findet keine passende WG. |
| 3 | System informiert den Benutzer darüber. |
| 4 | Benutzer kann die Eingabe korrigieren oder den Vorgang abbrechen. |

---

## UC-05 – WG verlassen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-05 |
| Name | WG verlassen |
| Ziel | Ein Mitglied verlässt eine bestehende Wohngemeinschaft. |
| Akteur | Benutzer |
| Auslöser | Das Mitglied möchte die Wohngemeinschaft verlassen. |
| Vorbedingung | Der Benutzer ist Mitglied einer Wohngemeinschaft. |
| Nachbedingung | Die Mitgliedschaft wurde entfernt und der Benutzer hat keinen Zugriff mehr auf die WG-Daten. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die WG-Einstellungen. |
| 2 | Mitglied wählt „WG verlassen“. |
| 3 | System zeigt eine Sicherheitsabfrage an. |
| 4 | Mitglied bestätigt die Aktion. |
| 5 | System entfernt die Mitgliedschaft. |
| 6 | Die Startansicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Vorgang abgebrochen

| Nr. | Aktivität |
|------|-----------|
| 1 | System zeigt die Sicherheitsabfrage an. |
| 2 | Mitglied entscheidet sich gegen das Verlassen der WG. |
| 3 | Mitglied bricht den Vorgang ab. |
| 4 | Die Mitgliedschaft bleibt unverändert bestehen. |

---

# F2.4 Einkaufsliste

## UC-06 – Artikel hinzufügen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-06 |
| Name | Artikel hinzufügen |
| Ziel | Ein Mitglied fügt einen neuen Artikel zur gemeinsamen Einkaufsliste hinzu. |
| Akteur | Benutzer |
| Auslöser | Ein Produkt wird benötigt. |
| Vorbedingung | Der Benutzer ist Mitglied einer Wohngemeinschaft. |
| Nachbedingung | Der Artikel wurde gespeichert und erscheint auf der Einkaufsliste. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | Mitglied wählt „Artikel hinzufügen“. |
| 3 | Mitglied gibt Name, Menge und Kategorie des Artikels ein. |
| 4 | Mitglied bestätigt die Eingaben. |
| 5 | System prüft die Eingaben. |
| 6 | System speichert den Artikel. |
| 7 | Der Artikel erscheint auf der Einkaufsliste. |

### Ausnahmeszenarien

#### A1 – Pflichtfeld fehlt

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied gibt keinen Artikelnamen ein. |
| 2 | System erkennt die unvollständige Eingabe. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Mitglied ergänzt die fehlenden Angaben. |

---

## UC-07 – Artikel bearbeiten

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-07 |
| Name | Artikel bearbeiten |
| Ziel | Ein Mitglied ändert die Informationen eines vorhandenen Artikels. |
| Akteur | Benutzer |
| Auslöser | Die Informationen eines Artikels sollen geändert werden. |
| Vorbedingung | Der Artikel existiert auf der Einkaufsliste. |
| Nachbedingung | Die Änderungen wurden gespeichert und sind für die Mitglieder sichtbar. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | Mitglied wählt einen vorhandenen Artikel aus. |
| 3 | Mitglied bearbeitet die gewünschten Informationen. |
| 4 | Mitglied bestätigt die Änderungen. |
| 5 | System prüft die Eingaben. |
| 6 | System speichert die Änderungen. |
| 7 | Die aktualisierten Informationen werden angezeigt. |

### Ausnahmeszenarien

#### A2 – Artikel wurde zwischenzeitlich geändert

| Nr. | Aktivität |
|------|-----------|
| 1 | Während der Bearbeitung wurde der Artikel von einem anderen Mitglied geändert. |
| 2 | System erkennt den Konflikt. |
| 3 | System aktualisiert die angezeigten Daten oder fordert eine erneute Bearbeitung an. |

---

## UC-08 – Artikel löschen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-08 |
| Name | Artikel löschen |
| Ziel | Ein Mitglied entfernt einen nicht mehr benötigten Artikel aus der gemeinsamen Einkaufsliste. |
| Akteur | Benutzer |
| Auslöser | Der Artikel wird nicht mehr benötigt. |
| Vorbedingung | Der Artikel existiert auf der Einkaufsliste. |
| Nachbedingung | Der Artikel wurde entfernt und erscheint nicht mehr auf der Einkaufsliste. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | Mitglied wählt einen vorhandenen Artikel aus. |
| 3 | Mitglied wählt die Funktion „Löschen“. |
| 4 | System zeigt eine Sicherheitsabfrage an. |
| 5 | Mitglied bestätigt die Löschaktion. |
| 6 | System entfernt den Artikel aus der Einkaufsliste. |
| 7 | Die aktualisierte Einkaufsliste wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Löschvorgang abgebrochen

| Nr. | Aktivität |
|------|-----------|
| 1 | System zeigt die Sicherheitsabfrage an. |
| 2 | Mitglied entscheidet sich gegen das Löschen. |
| 3 | Mitglied bricht den Vorgang ab. |
| 4 | Der Artikel bleibt unverändert bestehen. |

#### A2 – Artikel wurde bereits gelöscht

| Nr. | Aktivität |
|------|-----------|
| 1 | Ein anderes Mitglied hat den Artikel bereits gelöscht. |
| 2 | System erkennt, dass der Artikel nicht mehr existiert. |
| 3 | System informiert das Mitglied über die Änderung. |
| 4 | Die aktuelle Einkaufsliste wird angezeigt. |

---

## UC-09 – Artikel als gekauft markieren

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-09 |
| Name | Artikel als gekauft markieren |
| Ziel | Ein Mitglied kennzeichnet einen Artikel als gekauft, damit alle Mitglieder den aktuellen Einkaufsstand sehen können. |
| Akteur | Benutzer |
| Auslöser | Der Artikel wurde eingekauft. |
| Vorbedingung | Der Artikel existiert und besitzt den Status „Offen“. |
| Nachbedingung | Der Artikel besitzt den Status „Gekauft“. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | Mitglied wählt einen offenen Artikel aus. |
| 3 | Mitglied markiert den Artikel als gekauft. |
| 4 | System aktualisiert den Status des Artikels auf „Gekauft“. |
| 5 | System speichert die Änderung. |
| 6 | Die aktualisierte Einkaufsliste wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Artikel wurde bereits als gekauft markiert

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied versucht einen bereits gekauften Artikel erneut zu markieren. |
| 2 | System erkennt den aktuellen Status. |
| 3 | Es erfolgt keine weitere Änderung. |
| 4 | Der aktuelle Artikelstatus wird angezeigt. |

#### A2 – Artikel nicht verfügbar

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied wählt einen Artikel aus. |
| 2 | Der Artikel wurde zwischenzeitlich gelöscht oder verändert. |
| 3 | System informiert das Mitglied über die Änderung. |
| 4 | Die aktuelle Einkaufsliste wird neu geladen. |


---

## UC-10 – Einkaufsliste anzeigen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-10 |
| Name | Einkaufsliste anzeigen |
| Ziel | Ein Mitglied zeigt die aktuelle Einkaufsliste seiner Wohngemeinschaft an. |
| Akteur | Benutzer |
| Auslöser | Das Mitglied möchte offene oder bereits gekaufte Artikel einsehen. |
| Vorbedingung | Der Benutzer ist Mitglied einer Wohngemeinschaft. |
| Nachbedingung | Die Einkaufsliste wird angezeigt. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | System lädt die verfügbaren Artikel der WG. |
| 3 | System zeigt die Einkaufsliste an. |
| 4 | Mitglied kann offene und gekaufte Artikel einsehen. |

### Ausnahmeszenarien

#### A1 – Keine Artikel vorhanden

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | System findet keine Artikel. |
| 3 | System zeigt eine leere Einkaufsliste an. |
| 4 | Mitglied kann neue Artikel hinzufügen. |

#### A2 – Daten können nicht geladen werden

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Einkaufsliste. |
| 2 | Während des Ladevorgangs tritt ein Fehler auf. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Mitglied kann den Ladevorgang erneut starten. |

---

# F2.5 Kostenverwaltung

## UC-11 – Ausgabe erfassen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-11 |
| Name | Ausgabe erfassen |
| Ziel | Ein Mitglied erfasst eine gemeinsame Ausgabe der Wohngemeinschaft. |
| Akteur | Benutzer |
| Auslöser | Ein Mitglied hat einen Einkauf oder eine gemeinsame Ausgabe bezahlt. |
| Vorbedingung | Der Benutzer ist Mitglied einer Wohngemeinschaft. |
| Nachbedingung | Die Ausgabe wurde gespeichert und steht für die Kostenaufteilung zur Verfügung. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet den Bereich „Ausgaben“. |
| 2 | Mitglied erstellt eine neue Ausgabe. |
| 3 | Mitglied gibt Betrag und Beschreibung ein. |
| 4 | Mitglied wählt die beteiligten Mitglieder aus. |
| 5 | Mitglied bestätigt die Eingaben. |
| 6 | System prüft die Eingaben. |
| 7 | System speichert die Ausgabe. |
| 8 | Die erfasste Ausgabe wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Keine beteiligten Mitglieder ausgewählt

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied erfasst die Ausgabe ohne beteiligte Mitglieder auszuwählen. |
| 2 | System erkennt die unvollständigen Angaben. |
| 3 | System informiert das Mitglied über den Fehler. |
| 4 | Mitglied ergänzt die fehlenden Angaben. |

---

## UC-12 – Ausgabe bearbeiten

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-12 |
| Name | Ausgabe bearbeiten |
| Ziel | Ein Mitglied ändert die Informationen einer bestehenden Ausgabe. |
| Akteur | Benutzer |
| Auslöser | Fehlerhafte oder unvollständige Angaben einer Ausgabe sollen korrigiert werden. |
| Vorbedingung | Die Ausgabe existiert und kann bearbeitet werden. |
| Nachbedingung | Die Ausgabe wurde aktualisiert und die Änderungen sind gespeichert. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet den Bereich „Ausgaben“. |
| 2 | Mitglied wählt eine bestehende Ausgabe aus. |
| 3 | Mitglied bearbeitet die gewünschten Angaben. |
| 4 | Mitglied bestätigt die Änderungen. |
| 5 | System prüft die Eingaben. |
| 6 | System aktualisiert die Ausgabe. |
| 7 | Die aktualisierte Ausgabe wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Ausgabe wurde zwischenzeitlich geändert

| Nr. | Aktivität |
|------|-----------|
| 1 | Während der Bearbeitung wurde die Ausgabe von einem anderen Mitglied geändert. |
| 2 | System erkennt die Änderung. |
| 3 | System informiert das Mitglied über den Konflikt. |
| 4 | Mitglied kann die Bearbeitung erneut durchführen. |

---

## UC-13 – Kosten aufteilen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-13 |
| Name | Kosten aufteilen |
| Ziel | Eine gemeinsame Ausgabe wird auf alle oder ausgewählte Mitglieder der Wohngemeinschaft verteilt. |
| Akteur | Benutzer |
| Auslöser | Eine Ausgabe wurde erfasst und soll auf die beteiligten Mitglieder aufgeteilt werden. |
| Vorbedingung | Eine Ausgabe existiert. |
| Nachbedingung | Die Kostenanteile wurden berechnet und gespeichert. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet eine vorhandene Ausgabe. |
| 2 | Mitglied wählt die beteiligten Mitglieder aus. |
| 3 | Mitglied bestätigt die Kostenaufteilung. |
| 4 | System berechnet die Kostenanteile. |
| 5 | System speichert die Aufteilung. |
| 6 | System aktualisiert die Salden der beteiligten Mitglieder. |
| 7 | Die aktualisierte Kostenübersicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Keine beteiligten Mitglieder ausgewählt

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied startet die Kostenaufteilung ohne Mitglieder auszuwählen. |
| 2 | System erkennt die unvollständigen Angaben. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Mitglied ergänzt die fehlenden Angaben. |

#### A2 – Ungültige Kostenaufteilung

| Nr. | Aktivität |
|------|-----------|
| 1 | Die eingegebenen Daten lassen keine gültige Kostenaufteilung zu. |
| 2 | System erkennt die fehlerhaften Angaben. |
| 3 | System informiert das Mitglied über den Fehler. |
| 4 | Mitglied korrigiert die Eingaben. |

---

## UC-14 – Schulden anzeigen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-14 |
| Name | Schulden anzeigen |
| Ziel | Ein Mitglied zeigt seine offenen und bereits beglichenen Schulden innerhalb der Wohngemeinschaft an. |
| Akteur | Benutzer |
| Auslöser | Das Mitglied möchte seine Verbindlichkeiten und Forderungen prüfen. |
| Vorbedingung | Mindestens eine Kostenaufteilung existiert. |
| Nachbedingung | Die Schuldenübersicht wird angezeigt. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Schuldenübersicht. |
| 2 | System lädt die vorhandenen Schuldeninformationen. |
| 3 | System zeigt offene und bezahlte Schulden an. |
| 4 | System zeigt Betrag, Gläubiger, Schuldner und Status an. |
| 5 | Mitglied prüft die angezeigten Informationen. |

### Ausnahmeszenarien

#### A1 – Keine Schulden vorhanden

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Schuldenübersicht. |
| 2 | System findet keine offenen oder bezahlten Schulden. |
| 3 | System informiert das Mitglied darüber. |
| 4 | Eine leere Schuldenübersicht wird angezeigt. |

#### A2 – Daten können nicht geladen werden

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Schuldenübersicht. |
| 2 | Während des Ladevorgangs tritt ein Fehler auf. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Mitglied kann den Ladevorgang erneut starten. |

---

## UC-15 – Schuld als bezahlt markieren

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-15 |
| Name | Schuld als bezahlt markieren |
| Ziel | Ein Mitglied markiert eine offene Schuld als beglichen. |
| Akteur | Benutzer |
| Auslöser | Die offene Schuld wurde außerhalb des Systems beglichen. |
| Vorbedingung | Eine offene Schuld existiert. |
| Nachbedingung | Die Schuld besitzt den Status „Bezahlt“ und wird entsprechend angezeigt. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Schuldenübersicht. |
| 2 | Mitglied wählt eine offene Schuld aus. |
| 3 | Mitglied wählt die Funktion „Als bezahlt markieren“. |
| 4 | System zeigt eine Bestätigung an. |
| 5 | Mitglied bestätigt die Aktion. |
| 6 | System setzt den Status der Schuld auf „Bezahlt“. |
| 7 | System speichert das Zahlungsdatum. |
| 8 | Die aktualisierte Schuldenübersicht wird angezeigt. |

### Ausnahmeszenarien

#### A1 – Vorgang abgebrochen

| Nr. | Aktivität |
|------|-----------|
| 1 | System zeigt die Bestätigung an. |
| 2 | Mitglied entscheidet sich gegen die Änderung. |
| 3 | Mitglied bricht den Vorgang ab. |
| 4 | Die Schuld bleibt weiterhin offen. |

#### A2 – Schuld wurde bereits beglichen

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied wählt eine bereits als bezahlt markierte Schuld aus. |
| 2 | System erkennt den aktuellen Status. |
| 3 | Es erfolgt keine weitere Änderung. |
| 4 | Die aktuelle Schuldenübersicht wird angezeigt. |

---

## UC-16 – Kostenübersicht anzeigen

| Attribut | Beschreibung |
|-----------|-------------|
| ID | UC-16 |
| Name | Kostenübersicht anzeigen |
| Ziel | Ein Mitglied betrachtet die finanzielle Situation der Wohngemeinschaft. |
| Akteur | Benutzer |
| Auslöser | Das Mitglied möchte Ausgaben, Kostenanteile und Salden prüfen. |
| Vorbedingung | Mindestens eine Ausgabe existiert. |
| Nachbedingung | Die Kostenübersicht wird angezeigt. |

### Hauptszenario

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Kostenübersicht. |
| 2 | System lädt die vorhandenen Ausgaben. |
| 3 | System zeigt die erfassten Ausgaben an. |
| 4 | System zeigt die berechneten Kostenanteile an. |
| 5 | System zeigt die aktuellen Salden der Mitglieder an. |
| 6 | System zeigt offene und bezahlte Schulden an. |
| 7 | Mitglied kann Detailinformationen zu einzelnen Einträgen aufrufen. |

### Ausnahmeszenarien

#### A1 – Keine Ausgaben vorhanden

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Kostenübersicht. |
| 2 | System findet keine erfassten Ausgaben. |
| 3 | System informiert das Mitglied darüber. |
| 4 | Eine leere Kostenübersicht wird angezeigt. |

#### A2 – Daten können nicht geladen werden

| Nr. | Aktivität |
|------|-----------|
| 1 | Mitglied öffnet die Kostenübersicht. |
| 2 | Während des Ladevorgangs tritt ein Fehler auf. |
| 3 | System zeigt eine Fehlermeldung an. |
| 4 | Mitglied kann die Ansicht erneut laden. |

---

## F2.6 Allgemeine Ausnahmeszenarien

Die folgenden Ausnahmeszenarien gelten grundsätzlich für alle Anwendungsfälle, sofern nicht anders angegeben.

### A-G01 – Keine Internetverbindung

1. Der Benutzer startet einen Anwendungsfall.
2. Das System erkennt die fehlende Internetverbindung.
3. Das System informiert den Benutzer über die fehlende Verbindung.
4. Änderungen werden lokal gespeichert oder nach Wiederherstellung der Verbindung synchronisiert.

### A-G02 – Technischer Fehler

1. Während der Ausführung eines Anwendungsfalls tritt ein technischer Fehler auf.
2. Das System zeigt eine Fehlermeldung an.
3. Der Benutzer kann den Vorgang zu einem späteren Zeitpunkt erneut durchführen.

### A-G03 – Ungültige Eingaben

1. Der Benutzer gibt ungültige oder unvollständige Daten ein.
2. Das System erkennt die fehlerhaften Eingaben.
3. Das System informiert den Benutzer über die Fehler.
4. Der Benutzer korrigiert die Eingaben.
