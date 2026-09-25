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

# N2.2 Autorisierung

Die Autorisierung regelt den Zugriff auf Funktionen und Daten innerhalb einer WG.

Die Rechte eines Benutzers ergeben sich aus seiner Membership innerhalb der jeweiligen WG.

## Rollen

### admin

Die Rolle `admin` kennzeichnet im MVP den Ersteller der WG.

Darf:

- den Einladungscode der eigenen WG sehen
- Artikel und Ausgaben der eigenen WG verwalten
- eigene Forderungen und Verbindlichkeiten einsehen
- eigene offene Verbindlichkeiten als bezahlt markieren

Da die erste Version keine Rollenübertragung und keine Ernennung eines weiteren `admin` vorsieht, kann der `admin` die WG nicht verlassen.

### member

Darf:

- den Einladungscode der eigenen WG sehen
- Artikel verwalten
- Ausgaben verwalten
- eigene Forderungen und Verbindlichkeiten einsehen
- eigene offene Verbindlichkeiten als bezahlt markieren
- die WG verlassen

## Regeln

- Jeder Benutzer besitzt pro WG genau eine Rolle.
- Die Rolle wird in `Membership.role` gespeichert.
- Datenzugriffe bleiben auf die eigene WG beschränkt.
- Der Zahlungsstatus einer Schuld darf nur vom jeweiligen Schuldner von `open` auf `paid` geändert werden.
# N2.3 Offline-Modus

WG-ShopSync bleibt bei fehlender Internetverbindung eingeschränkt nutzbar.

Bereits geladene Einkaufslistendaten werden durch die Firestore-Offline-Persistenz lokal zwischengespeichert.

## Regeln

- Die zuletzt synchronisierte Einkaufsliste bleibt lesbar.
- Neue Artikel können offline als ausstehende Firestore-Schreibvorgänge vorgemerkt werden.
- Ausstehende Firestore-Schreibvorgänge werden nach Wiederherstellung der Verbindung synchronisiert.
- Die Oberfläche kennzeichnet Cache-Daten und ausstehende Schreibvorgänge.
- Artikel bearbeiten (UC-07) und als gekauft markieren (UC-09) benötigen eine aktive Verbindung, da diese Aktionen Firestore-Transaktionen verwenden.
- Registrierung, Login ohne vorhandene Sitzung, WG-Erstellung, WG-Beitritt sowie Änderungen an Ausgaben und Schulden benötigen eine aktive Verbindung.
# N2.4 Synchronisationsanforderungen

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

Der serverseitige Datenstand besitzt Vorrang. Bei einem erkannten Konflikt wird der Benutzer informiert. Er kann den aktuellen Serverstand laden und die gewünschte Änderung anschließend als neue Bearbeitung erneut durchführen.

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
- Erkannte Fehler und Konflikte dürfen nicht stillschweigend als erfolgreicher Abschluss dargestellt werden.
- Der Benutzer erhält einen Hinweis zur Fehlerursache.

---

# N2.6 Datenvalidierung

Eingaben werden vor der Speicherung überprüft.

Nur gültige Daten dürfen dauerhaft gespeichert werden.

## Regeln

### Benutzer

- Name darf nicht leer sein.
- Der Name ist 2 bis 50 Zeichen lang.
- E-Mail-Adresse muss gültig sein.
- Passwort muss den Sicherheitsanforderungen entsprechen.

### WG

- Der Name darf nicht leer sein.
- Der Einladungscode muss eindeutig sein.

### Einkaufsliste

- Der Artikelname darf nicht leer sein.
- Der Artikelname ist 1 bis 100 Zeichen lang.
- Eine Beschreibung ist optional und höchstens 500 Zeichen lang.
- Mengenangaben müssen positive Ganzzahlen sein.

### Ausgaben

- Betrag muss größer als 0 sein.
- Beschreibung darf nicht leer sein.
- Mindestens ein Kostenbeteiligter muss ausgewählt sein.

### Schulden

- Betrag muss größer als 0 sein.

---

# N2.7 Datenschutz und Passwortschutz

WG-ShopSync verarbeitet personenbezogene Daten der Benutzer.

Diese Daten müssen vor unberechtigtem Zugriff geschützt werden.

## Passwortschutz

- Passwörter werden vollständig durch Firebase Authentication verwaltet.
- WG-ShopSync speichert weder Klartextpasswörter noch Passwort-Hashes in Cloud Firestore.
- Passwörter werden niemals angezeigt.

## Datenschutz

- Benutzer dürfen nur Daten ihrer eigenen WG sehen.
- Fremde WG-Daten dürfen nicht angezeigt werden.
- Persönliche Daten werden ausschließlich für die Nutzung der Anwendung verwendet.

# N2.8 Sitzungsverwaltung

Nach erfolgreicher Anmeldung erhält der Benutzer eine aktive Sitzung.

Während einer aktiven Sitzung muss sich der Benutzer nicht erneut anmelden.

## Regeln

- Geschützte Funktionen erfordern eine aktive Sitzung.
- Nach dem Abmelden wird die Sitzung beendet.
- Ungültige Sitzungen werden automatisch verworfen.

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