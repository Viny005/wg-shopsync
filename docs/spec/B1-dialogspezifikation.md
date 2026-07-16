# B1 – Dialogspezifikation

## Zielsetzung
Die Dialogspezifikation beschreibt die Benutzeroberfläche von WG-ShopSync sowie die Navigation zwischen den einzelnen Screens. Sie konkretisiert die in F2 beschriebenen Anwendungsfälle und dient als Grundlage für die Entwicklung der Benutzeroberfläche, die Implementierung der Navigation sowie die Durchführung von System- und Abnahmetests.

Jeder Screen realisiert einen oder mehrere Anwendungsfälle aus F2 und greift auf die im Datenmodell D1 definierten Entitäten sowie die in D2 beschriebenen Datentypen und Validierungsregeln zu.

---

# B1.1 Übersicht

| Screen | Zweck | Kernelemente | Navigation | Bezug zu UCs |
|----------|----------|----------|----------|----------|
| 1 – Login | Anmeldung | E-Mail, Passwort, Login-Button | → 5, → 2 | UC-02 |
| 2 – Registrierung | Kontoerstellung | Name, E-Mail, Passwort, Passwort-Wiederholung | → 5, → 1 | UC-01 |
| 3 – WG erstellen | Neue WG anlegen | WG-Name, Erstellen-Button | → 5 | UC-03 |
| 4 – WG beitreten | WG über Invite-Code beitreten | Invite-Code, Beitreten-Button | → 6 | UC-04 |
| 5 – WG-Übersicht | Zentrale Startseite | WG-Liste, Mitgliederliste, Invite-Code | → 6, → 8, → 9, → 3, → 4 | UC-03, UC-04, UC-05 |
| 6 – Einkaufsliste | Gemeinsame Einkaufsliste | Artikelliste, Checkboxen, FAB | → 7 | UC-06 bis UC-12 |
| 7 – Artikel hinzufügen/bearbeiten | Artikel erfassen oder ändern | Name, Menge, Kategorie | → 6 | UC-06, UC-07 |
| 8 – Kostenübersicht | Ausgaben und Salden | Ausgabenliste, Saldenanzeige | → 5 | UC-13 bis UC-15 |
| 9 – Benutzerprofil | Kontoverwaltung | Nutzerdaten, Logout, WG verlassen | → 5 | UC-05 |

---

# B1.2 Screen 1 – Login

## Zweck

Anmeldung eines bereits registrierten Nutzers.

## Bezug zu UC

UC-02 – Benutzer einloggen

## Vorbedingungen

- Ein Benutzerkonto existiert.

## Felder

| Feld | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|
| E-Mail | String | Ja | gültiges E-Mail-Format |
| Passwort | String | Ja | nicht leer |

## Kernelemente

- Eingabefeld E-Mail
- Eingabefeld Passwort
- Button „Einloggen“
- Link „Noch kein Konto? Registrieren“

## Fehlerfälle

- Ungültige Zugangsdaten → Meldung „E-Mail oder Passwort falsch“
- Keine Verbindung, aber gültige lokale Sitzung vorhanden → automatischer Offline-Start

## Navigation

- Erfolgreiche Anmeldung → Screen 5
- Link Registrierung → Screen 2

---

# B1.3 Screen 2 – Registrierung

## Zweck

Anlage eines neuen Benutzerkontos.

## Bezug zu UC

UC-01 – Benutzer registrieren

## Vorbedingungen

- Die verwendete E-Mail-Adresse ist noch nicht registriert.

## Felder

| Feld | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|
| Name | String (2–50) | Ja | 2–50 Zeichen |
| E-Mail | String | Ja | gültiges Format |
| Passwort | String | Ja | mindestens 8 Zeichen |
| Passwort-Bestätigung | String | Ja | muss übereinstimmen |

## Fehlerfälle

- E-Mail bereits vergeben
- Ungültige Eingaben
- Keine Internetverbindung

## Navigation

- Erfolgreiche Registrierung → Screen 5
- Zurück → Screen 1

---

# B1.4 Screen 3 – WG erstellen

## Zweck

Erstellung einer neuen Wohngemeinschaft.

## Bezug zu UC

UC-03 – WG erstellen

## Vorbedingungen

- Nutzer ist angemeldet.

## Felder

| Feld | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|
| WG-Name | String (2–50) | Ja | nicht leer |

## Fehlerfälle

- WG-Name leer
- Technischer Fehler bei Erstellung

## Navigation

- Erfolgreich → Screen 5

---

# B1.5 Screen 4 – WG beitreten

## Zweck

Beitritt zu einer bestehenden Wohngemeinschaft.

## Bezug zu UC

UC-04 – WG beitreten

## Vorbedingungen

- Nutzer ist angemeldet.
- Invite-Code liegt vor.

## Felder

| Feld | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|
| Invite-Code | String (6) | Ja | Format gemäß D2 |

## Fehlerfälle

- Ungültiger Invite-Code
- Nutzer ist bereits WG-Mitglied

## Navigation

- Erfolgreich → Screen 6

---

# B1.6 Screen 5 – WG-Übersicht

## Zweck

Zentrale Startseite des Nutzers.

## Bezug zu UC

UC-03, UC-04, UC-05

## Vorbedingungen

- Nutzer ist angemeldet.

## Kernelemente

- Liste aller WGs
- Mitgliederliste
- Anzeige des Invite-Codes
- Teilen-Funktion
- Buttons „WG erstellen“ und „WG beitreten“

## Fehlerfälle

- Nutzer gehört keiner WG an → Leerzustand mit Direktzugriff auf Screen 3 und Screen 4

## Navigation

- → Screen 6
- → Screen 8
- → Screen 9
- → Screen 3
- → Screen 4

---

# B1.7 Screen 6 – Einkaufsliste

## Zweck

Verwaltung gemeinsamer Einkaufsartikel innerhalb einer WG.

## Bezug zu UC

UC-06 bis UC-12

## Vorbedingungen

- Nutzer ist Mitglied der WG.

## Kernelemente

- Artikelliste
- Gruppierung nach Status
- Gruppierung nach Kategorie
- Checkbox zum Markieren als gekauft
- Swipe-Gesten zum Löschen
- Floating Action Button „+“

## Fehlerfälle

- Keine Artikel vorhanden
- Offline angelegte Artikel warten auf Synchronisation
- Synchronisierungskonflikte

## Navigation

- Neuer Artikel → Screen 7
- Artikel bearbeiten → Screen 7
- Zurück → Screen 5

---

# B1.8 Screen 7 – Artikel hinzufügen / bearbeiten

## Zweck

Anlegen oder Bearbeiten von Einkaufsartikeln.

## Bezug zu UC

UC-06 und UC-07

## Vorbedingungen

- Nutzer ist Mitglied der WG.

## Felder

| Feld | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|
| Name | String (1–100) | Ja | nicht leer |
| Menge | Integer | Nein | ≥ 1 |
| Kategorie | Enum | Nein | Kategorie aus D2 |

## Fehlerfälle

- Artikelname leer
- Synchronisierungskonflikte

## Navigation

- Speichern → Screen 6
- Abbrechen → Screen 6

---

# B1.9 Screen 8 – Kostenübersicht

## Zweck

Verwaltung gemeinsamer Ausgaben und Anzeige offener Salden.

## Bezug zu UC

UC-13, UC-14, UC-15

## Vorbedingungen

- Nutzer ist Mitglied einer WG.

## Felder

| Feld | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|
| Betrag | Decimal(10,2) | Ja | > 0 |
| Beschreibung | String | Ja | nicht leer |
| Käufer | Auswahl Mitglied | Ja | gültiges Mitglied |
| Beteiligte Mitglieder | Mehrfachauswahl | Ja | mindestens ein Mitglied |

## Kernelemente

- Ausgabenliste
- Saldenanzeige
- Button „Ausgabe hinzufügen“

## Fehlerfälle

- Betrag kleiner oder gleich 0
- Keine Ausgaben vorhanden

## Navigation

- Zurück → Screen 5

---

# B1.10 Screen 9 – Benutzerprofil

## Zweck

Verwaltung des Benutzerkontos.

## Bezug zu UC

UC-05 – WG verlassen

## Vorbedingungen

- Nutzer ist angemeldet.

## Kernelemente

- Anzeige des Namens
- Anzeige der E-Mail-Adresse
- Liste der eigenen WGs
- Logout
- WG verlassen

## Fehlerfälle

- WG verlassen ohne Bestätigung nicht möglich

## Navigation

- Zurück → Screen 5
- Logout → Screen 1

---

# B1.11 Gemeinsame Dialogmuster

## Formularvalidierung

Eingaben werden clientseitig und serverseitig validiert. Fehler werden direkt am betroffenen Feld angezeigt.

## Bestätigungsdialoge

Kritische Aktionen benötigen eine ausdrückliche Bestätigung.

Beispiele:

- WG verlassen
- Artikel löschen

## Leerzustände

Falls keine Daten vorhanden sind, werden erklärende Hinweise angezeigt.

Beispiele:

- Keine WG vorhanden
- Keine Artikel vorhanden
- Keine Ausgaben vorhanden

## Offline-Modus

Die zuletzt synchronisierten Daten bleiben lokal verfügbar. Änderungen werden bei bestehender Internetverbindung automatisch synchronisiert.

## Fehlermeldungen

Fehlermeldungen werden verständlich dargestellt und enthalten Hinweise zur Problemlösung.

Beispiele:

- E-Mail oder Passwort falsch
- Ungültiger Invite-Code
- Keine Internetverbindung
- Synchronisationsfehler

---

# B1.12 Navigationsdiagramm

./images/navigationsdiagramm.png

*Abbildung B1-1: Navigationsdiagramm der Benutzerschnittstelle von WG-ShopSync*

Das Navigationsdiagramm zeigt die möglichen Übergänge zwischen den einzelnen Screens der Anwendung WG-ShopSync.

Screen 5 (WG-Übersicht) fungiert als zentraler Navigations-Hub der Anwendung. Von dort aus können die wichtigsten Funktionen wie Einkaufsliste, Kostenübersicht und Benutzerprofil erreicht werden. Darüber hinaus können neue Wohngemeinschaften erstellt oder bestehenden Wohngemeinschaften beigetreten werden.

Screen 1 (Login) und Screen 2 (Registrierung) bilden den Einstiegspunkt in die Anwendung. Nach erfolgreicher Authentifizierung wird der Nutzer zur WG-Übersicht weitergeleitet.

Die Verwaltung von Wohngemeinschaften erfolgt über Screen 3 (WG erstellen) und Screen 4 (WG beitreten). Nach dem Beitritt zu einer WG wird die entsprechende Einkaufsliste geöffnet.

Screen 6 (Einkaufsliste) stellt die zentrale Funktion der Anwendung dar. Von dort aus können neue Artikel angelegt oder bestehende Artikel bearbeitet werden. Hierzu wird Screen 7 als Detaildialog verwendet.

Screen 8 dient der Verwaltung gemeinsamer Ausgaben und der Anzeige von Salden innerhalb einer Wohngemeinschaft.

Screen 9 ermöglicht die Verwaltung des Benutzerkontos, den Logout sowie das Verlassen einer Wohngemeinschaft.

Das Diagramm beschreibt ausschließlich die Navigation auf Ebene der Benutzerschnittstelle. Die fachlichen Abläufe werden separat in F1 (Geschäftsprozesse) und F2 (Anwendungsfälle) beschrieben.
---

# B1.13 Querverweise

| Block | Relevanz |
|----------|----------|
| F2 | Realisierte Anwendungsfälle |
| D1 | Verwendete Entitäten |
| D2 | Datentypen und Validierungsregeln |
| N1 | Qualitätsanforderungen |
| N2 | Authentifizierung, Synchronisation und Offline-Modus |

Die Dialogspezifikation bildet die Grundlage für die Implementierung der Benutzeroberfläche sowie für die Durchführung von System- und Abnahmetests.