# B1 – Dialogspezifikation

## Zielsetzung
Die Dialogspezifikation beschreibt die Benutzeroberfläche von WG-ShopSync sowie die Navigation zwischen den einzelnen Screens. Sie konkretisiert die in F2 beschriebenen Anwendungsfälle und dient als Grundlage für die Entwicklung der Benutzeroberfläche, die Implementierung der Navigation sowie die Durchführung von System- und Abnahmetests.

Jeder Screen realisiert einen oder mehrere Anwendungsfälle aus F2 und greift auf die im Datenmodell D1 definierten Entitäten sowie die in D2 beschriebenen Datentypen und Validierungsregeln zu.

---

# B1.1 Übersicht

| Screen | Zweck | Kernelemente | Navigation | Bezug zu UCs |
|----------|----------|----------|----------|----------|
| 1 – Login | Anmeldung | E-Mail, Passwort, Login-Button | → WG-Übersicht, → Registrierung | UC-02 |
| 2 – Registrierung | Kontoerstellung | Name, E-Mail, Passwort, Passwort-Wiederholung |→ WG-Übersicht, → Login| UC-01 |
| 3 – WG erstellen | Neue WG anlegen | WG-Name, Erstellen-Button | → WG-Übersicht | UC-03 |
| 4 – WG beitreten | WG über Invite-Code beitreten | Invite-Code, Beitreten-Button | → WG-Übersicht | UC-04 |
| 5 – WG-Übersicht | Zentrale Startseite | WG-Liste, Mitgliederliste, Invite-Code |→ Einkaufsliste, → Kostenübersicht, → Benutzerprofil, → WG erstellen, → WG beitreten | UC-03, UC-04, UC-05 |
| 6 – Einkaufsliste | Gemeinsame Einkaufsliste | Artikelliste, Checkboxen, FAB | → Artikel hinzufügen / bearbeiten, 
→ WG-Übersicht | UC-06 bis UC-12 |
| 7 – Artikel hinzufügen/bearbeiten | Artikel erfassen oder ändern | Name, Menge, Kategorie | → Einkaufsliste | UC-06, UC-07 |
| 8 – Kostenübersicht | Ausgaben und Salden | Ausgabenliste, Saldenanzeige | → WG-Übersicht | UC-13 bis UC-15 |
| 9 – Benutzerprofil | Kontoverwaltung | Nutzerdaten, Logout, WG verlassen | → WG-Übersicht
→ Login | UC-05 |

---

# B1.2 Screen 1 – Login

## Zweck

Anmeldung eines bereits registrierten Nutzers.

## Bezug zu UC

[UC-02 – Einloggen](F2-anwendungsfaelle.md#uc-02--einloggen)

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

## GUI Static

- Seitentitel „Login“
- Eingabefeld für die E-Mail-Adresse
- Eingabefeld für das Passwort
- Button „Einloggen“
- Link „Noch kein Konto? Registrieren“

## GUI Dynamic

- Eingaben werden während der Eingabe validiert.
- Fehlermeldungen werden bei ungültigen Zugangsdaten angezeigt.
- Nach erfolgreicher Anmeldung wird die WG-Übersicht geladen.
- Eine vorhandene lokale Sitzung ermöglicht den Offline-Start.

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

[UC-01 – Registrieren](F2-anwendungsfaelle.md#uc-01--registrieren)

## Vorbedingungen

- Die verwendete E-Mail-Adresse ist noch nicht registriert.

## Felder

| Feld | Beschreibung | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|----------|
| Name | Anzeigename des Benutzers | String (2–50) | Ja | 2–50 Zeichen |
| E-Mail | E-Mail-Adresse des Benutzers | String | Ja | gültiges Format |
| Passwort | Passwort für das Benutzerkonto | String | Ja | mindestens 8 Zeichen |
| Passwort-Bestätigung | Wiederholung des Passworts | String | Ja | muss übereinstimmen |

## GUI Static

- Seitentitel „Registrierung“
- Eingabefeld für den Namen
- Eingabefeld für die E-Mail-Adresse
- Eingabefeld für das Passwort
- Eingabefeld zur Passwort-Bestätigung
- Button „Registrieren“
- Link zum Login

## GUI Dynamic

- Eingaben werden während der Eingabe validiert.
- Die Übereinstimmung der Passwörter wird überprüft.
- Fehlermeldungen werden direkt angezeigt.
- Nach erfolgreicher Registrierung wird die WG-Übersicht geöffnet.

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

[UC-03 – WG erstellen](F2-anwendungsfaelle.md#uc-03--wg-erstellen)

## Vorbedingungen

- Nutzer ist angemeldet.

## Felder

| Feld | Beschreibung | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|----------|
| WG-Name | Name der neuen Wohngemeinschaft | String (2–50) | Ja | nicht leer |

## GUI Static

- Seitentitel „WG erstellen“
- Eingabefeld für den WG-Namen
- Button „WG erstellen“
- Navigationsmöglichkeit zurück zur WG-Übersicht

## GUI Dynamic

- Der WG-Name wird während der Eingabe validiert.
- Fehlermeldungen werden bei ungültigen Eingaben angezeigt.
- Nach erfolgreicher Erstellung wird die neue WG geöffnet.
- Der Einladungscode wird automatisch erzeugt und angezeigt.

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

[UC-04 – WG beitreten](F2-anwendungsfaelle.md#uc-04--wg-beitreten)

## Vorbedingungen

- Nutzer ist angemeldet.
- Invite-Code liegt vor.

## Felder

| Feld | Beschreibung | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|----------|
| Invite-Code | Einladungscode einer bestehenden WG | String (6) | Ja | Format gemäß D2 |

## GUI Static

- Seitentitel „WG beitreten“
- Eingabefeld für den Einladungscode
- Button „WG beitreten“
- Navigationsmöglichkeit zurück zur WG-Übersicht

## GUI Dynamic

- Der Einladungscode wird während der Eingabe geprüft.
- Fehlermeldungen werden bei ungültigen Einladungscodes angezeigt.
- Informationen zur gefundenen WG werden angezeigt.
- Nach erfolgreichem Beitritt wird die Einkaufsliste der WG geöffnet.

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

- [UC-03 – WG erstellen](F2-anwendungsfaelle.md#uc-03--wg-erstellen)
- [UC-04 – WG beitreten](F2-anwendungsfaelle.md#uc-04--wg-beitreten)
- [UC-05 – WG verlassen](F2-anwendungsfaelle.md#uc-05--wg-verlassen)

## Vorbedingungen

- Nutzer ist angemeldet.

## Kernelemente

- Liste aller WGs
- Mitgliederliste
- Anzeige des Invite-Codes
- Teilen-Funktion
- Buttons „WG erstellen“ und „WG beitreten“

## GUI Static

- Seitentitel „WG-Übersicht“
- Liste der verfügbaren Wohngemeinschaften
- Mitgliederliste der ausgewählten WG
- Anzeige des Einladungscodes
- Button „WG erstellen“
- Button „WG beitreten“
- Navigationsmöglichkeiten zur Einkaufsliste, Kostenübersicht und zum Benutzerprofil

## GUI Dynamic

- Die angezeigten WGs werden beim Öffnen geladen.
- Änderungen an der Mitgliederliste werden automatisch aktualisiert.
- Der Einladungscode wird dynamisch aus den WG-Daten angezeigt.
- Nach Auswahl einer WG werden die zugehörigen Informationen geladen.
- Bei fehlender WG-Mitgliedschaft wird ein Leerzustand mit Handlungsmöglichkeiten angezeigt.

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

- [UC-06 – Artikel hinzufügen](F2-anwendungsfaelle.md#uc-06--artikel-hinzufugen)
- [UC-07 – Artikel bearbeiten](F2-anwendungsfaelle.md#uc-07--artikel-bearbeiten)
- [UC-08 – Artikel löschen](F2-anwendungsfaelle.md#uc-08--artikel-loschen)
- [UC-09 – Artikel als gekauft markieren](F2-anwendungsfaelle.md#uc-09--artikel-als-gekauft-markieren)
- [UC-10 – Einkaufsliste anzeigen](F2-anwendungsfaelle.md#uc-10--einkaufsliste-anzeigen)

## Vorbedingungen

- Nutzer ist Mitglied der WG.

## Kernelemente

- Artikelliste
- Gruppierung nach Status
- Gruppierung nach Kategorie
- Checkbox zum Markieren als gekauft
- Swipe-Gesten zum Löschen
- Floating Action Button „+“

## GUI Static

- Seitentitel „Einkaufsliste“
- Liste der Einkaufsartikel
- Anzeige von Kategorien
- Gruppierung nach Status
- Checkboxen zum Markieren gekaufter Artikel
- Floating Action Button „+“
- Navigationsmöglichkeit zurück zur WG-Übersicht

## GUI Dynamic

- Neue Artikel werden automatisch in der Liste angezeigt.
- Der Status eines Artikels kann von „Offen“ zu „Gekauft“ wechseln.
- Änderungen anderer Mitglieder werden nach der Synchronisation angezeigt.
- Artikel können hinzugefügt, bearbeitet oder gelöscht werden.
- Offline erfasste Änderungen werden nach Wiederherstellung der Internetverbindung synchronisiert.

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

- [UC-06 – Artikel hinzufügen](F2-anwendungsfaelle.md#uc-06--artikel-hinzufugen)
- [UC-07 – Artikel bearbeiten](F2-anwendungsfaelle.md#uc-07--artikel-bearbeiten)

## Vorbedingungen

- Nutzer ist Mitglied der WG.

## Felder

| Feld | Beschreibung | Typ | Pflicht | Validierung |
|----------|----------|----------|----------|----------|
| Name | Bezeichnung des Einkaufsartikels | String (1–100) | Ja | nicht leer |
| Menge | Gewünschte Anzahl des Artikels | Integer | Nein | ≥ 1 |
| Kategorie | Zuordnung zu einer Artikelkategorie | Enum | Nein | Kategorie aus D2 |

## GUI Static

- Seitentitel „Artikel hinzufügen“ bzw. „Artikel bearbeiten“
- Eingabefeld für den Artikelnamen
- Eingabefeld für die Menge
- Auswahlfeld für die Kategorie
- Button „Speichern“
- Button „Abbrechen“

## GUI Dynamic

- Eingaben werden während der Bearbeitung validiert.
- Fehlermeldungen werden direkt bei ungültigen Eingaben angezeigt.
- Bereits vorhandene Artikeldaten werden beim Bearbeiten automatisch geladen.
- Nach dem Speichern wird die Einkaufsliste aktualisiert angezeigt.
- Synchronisierungskonflikte werden dem Nutzer angezeigt.

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

- [UC-11 – Ausgabe erfassen](F2-anwendungsfaelle.md#uc-11--ausgabe-erfassen)
- [UC-12 – Ausgabe bearbeiten](F2-anwendungsfaelle.md#uc-12--ausgabe-bearbeiten)
- [UC-13 – Kosten aufteilen](F2-anwendungsfaelle.md#uc-13--kosten-aufteilen)
- [UC-14 – Schulden anzeigen](F2-anwendungsfaelle.md#uc-14--schulden-anzeigen)
- [UC-15 – Schuld als bezahlt markieren](F2-anwendungsfaelle.md#uc-15--schuld-als-bezahlt-markieren)
- [UC-16 – Kostenübersicht anzeigen](F2-anwendungsfaelle.md#uc-16--kostenubersicht-anzeigen)

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

## GUI Static

- Seitentitel „Kostenübersicht“
- Liste der erfassten Ausgaben
- Anzeige der aktuellen Salden
- Anzeige offener und bezahlter Schulden
- Button „Ausgabe hinzufügen“
- Navigationsmöglichkeit zurück zur WG-Übersicht

## GUI Dynamic

- Neue Ausgaben werden automatisch in der Übersicht angezeigt.
- Salden werden nach Änderungen an Ausgaben neu berechnet.
- Kostenaufteilungen werden unmittelbar aktualisiert.
- Bezahlte Schulden werden entsprechend gekennzeichnet.
- Änderungen anderer Mitglieder werden nach der Synchronisation angezeigt.
- Die Übersicht wird nach dem Hinzufügen oder Bearbeiten von Ausgaben aktualisiert.

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

[UC-05 – WG verlassen](F2-anwendungsfaelle.md#uc-05--wg-verlassen)

## Vorbedingungen

- Nutzer ist angemeldet.

## Kernelemente

- Anzeige des Namens
- Anzeige der E-Mail-Adresse
- Liste der eigenen WGs
- Logout
- WG verlassen

## GUI Static

- Seitentitel „Benutzerprofil“
- Anzeige des Namens
- Anzeige der E-Mail-Adresse
- Liste der eigenen Wohngemeinschaften
- Button „Logout“
- Button „WG verlassen“
- Navigationsmöglichkeit zurück zur WG-Übersicht

## GUI Dynamic

- Benutzerdaten werden beim Öffnen des Profils geladen.
- Änderungen an den Benutzerdaten werden automatisch angezeigt.
- Nach dem Logout wird der Benutzer zum Login-Screen weitergeleitet.
- Vor dem Verlassen einer WG wird ein Bestätigungsdialog angezeigt.
- Nach dem Verlassen einer WG wird die WG-Übersicht aktualisiert.

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

<p align="center">
  <img src="./images/navigationsdiagramm.png" alt="Navigationsdiagramm" width="800">
</p>
Abbildung B1-1: Navigationsdiagramm der Benutzerschnittstelle von WG-ShopSync

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
