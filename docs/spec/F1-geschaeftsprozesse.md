# F1 – Geschäftsprozesse

Geschäftsprozesse beschreiben reale Abläufe innerhalb einer Wohngemeinschaft unabhängig von der technischen Umsetzung.

WG-ShopSync unterstützt die gemeinsame Organisation von Einkäufen sowie die Verwaltung gemeinsamer Ausgaben und Schulden innerhalb einer WG.

---

## F1.1 Geschäftsprozess: Gemeinsamen Einkauf organisieren

### Ziel

WG-Mitglieder organisieren gemeinsam ihre Einkäufe über eine zentrale Einkaufsliste. Fehlende Produkte werden erfasst, Einkäufe koordiniert und die dabei entstehenden Kosten transparent auf die beteiligten Mitglieder verteilt.

Der Prozess beginnt damit, dass ein Benutzer eine WG erstellt oder einer bestehenden WG beitritt. Anschließend pflegen die Mitglieder gemeinsam die Einkaufsliste, kaufen benötigte Artikel außerhalb der Anwendung ein und dokumentieren danach die Ausgabe und die Kostenaufteilung.

---

### F1.1.1 Akteure

| Akteur | Typ | Rolle |
|---------|---------|---------|
| WG-Mitglied | Mensch | Einziger Akteur (konsistent mit dem Anwendungsfalldiagramm F2.1). Plant gemeinsame Einkäufe, erfasst gemeinsame Ausgaben und kann eine WG erstellen oder einer bestehenden beitreten. |
| WG-ShopSync | IT-System | Verwaltet Einkaufslisten, Ausgaben, Schulden und Synchronisation. |

---

### F1.1.2 Aktivitäten

| Nr. | Aktivität | Unterstützung | Hinweise |
|------|------------|------------|------------|
| A1 | Ein WG-Mitglied stellt fest, dass ein Produkt benötigt wird. | manuell | Außerhalb des Systems. |
| A2 | Das Mitglied öffnet WG-ShopSync. | Benutzer → App | Einstieg in den Prozess. |
| A3 | Ein Benutzer erstellt eine WG oder tritt ihr über einen Einladungscode bei. | WG-ShopSync | Der Benutzer erhält die Rolle `admin` oder `member`. |
| A4 | Das Mitglied fügt den Artikel zur gemeinsamen Einkaufsliste hinzu. | WG-ShopSync | Artikelname, Menge, Kategorie und optionale Beschreibung werden erfasst. |
| A5 | Alle Mitglieder sehen den neuen Artikel auf der Einkaufsliste. | WG-ShopSync | Synchronisation in nahezu Echtzeit. |
| A6 | Ein Mitglied kauft den Artikel. | manuell | Kauf erfolgt außerhalb des Systems. |
| A7 | Der Artikel wird als „gekauft“ markiert. | WG-ShopSync | Statuswechsel von „Offen“ zu „Gekauft“. |
| A8 | Optional wird eine Ausgabe zum Kauf erfasst. | WG-ShopSync | Kauf kann mit einer Ausgabe verknüpft werden. |
| A9 | Das Mitglied gibt Betrag und beteiligte Personen an. | WG-ShopSync | Alternativ kann eine Ausgabe unabhängig vom Einkauf erfasst werden. |
| A10 | Das System berechnet die Kostenanteile der beteiligten Mitglieder. | WG-ShopSync | Gleichmäßige Verteilung der Kosten. |
| A11 | Mitglieder sehen ihre Kostenanteile und offenen Schulden. | WG-ShopSync | Jeder Benutzer sieht nur die eigenen Schulden. |
| A12 | Schulden können als bezahlt markiert werden. | WG-ShopSync | Keine tatsächliche Zahlungsabwicklung. |
| A13 | Der Geschäftsprozess ist abgeschlossen. | manuell | Einkauf und Kostenaufteilung sind dokumentiert. |

---

### F1.1.3 Dokumente

Während des Geschäftsprozesses entstehen folgende Artefakte:

| Dokument | Beschreibung |
|------------|-------------|
| Einkaufsliste | Gemeinsame Liste aller offenen und gekauften Artikel einer WG |
| Einkaufseintrag | Einzelner Artikel mit Menge, Kategorie und Status |
| Ausgabe | Erfasste Kosten eines Einkaufs oder einer gemeinsamen Ausgabe |
| Kostenaufteilung | Berechnete Anteile der beteiligten Mitglieder |
| Schuldenübersicht | Übersicht offener und beglichener Schulden |

---

### F1.1.4 Datenspeicher

| Datenspeicher | Enthält |
|--------------|----------|
| Benutzerdatenbank | Benutzerkonten und Anmeldedaten |
| WG-Datenbank | Informationen über Wohngemeinschaften und Mitglieder |
| Einkaufslisten-Datenbank | Artikel, Mengen, Kategorien und Status |
| Ausgaben-Datenbank | Ausgaben, Kostenanteile und Zahlungsstatus |

---

### F1.1.5 Prozessgrenzen

Folgende Aktivitäten liegen außerhalb dieses Geschäftsprozesses:

- Der tatsächliche Kauf im Geschäft.
- Die tatsächliche Bezahlung oder Rückzahlung von Geld.
- Banküberweisungen oder Zahlungsdienstleister.
- Preisvergleiche oder Online-Bestellungen.
- Verwaltung mehrerer WGs pro Benutzer.
- Push-Benachrichtigungen.

Diese Funktionen können in zukünftigen Versionen ergänzt werden.

---

### F1.1.6 Zusammenhang mit anderen Bausteinen

| Baustein | Bezug |
|------------|---------|
| P1 | Definiert die Ziele und Rahmenbedingungen des Geschäftsprozesses |
| P2 | Beschreibt die Systemumgebung und beteiligten Systeme |
| F2 | Beschreibt die einzelnen Anwendungsfälle zur Umsetzung des Prozesses |
| F3 | Beschreibt die Anwendungsfunktionen des Systems |
| D1 | Definiert die verwendeten Datenobjekte |
| D2 | Definiert die Datentypen |
