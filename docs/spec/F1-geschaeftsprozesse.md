# F1 – Geschäftsprozesse

Geschäftsprozesse beschreiben reale Abläufe innerhalb einer Wohngemeinschaft unabhängig von der technischen Umsetzung.

WG-ShopSync unterstützt die gemeinsame Organisation von Einkäufen sowie die Verwaltung gemeinsamer Ausgaben und Schulden innerhalb einer WG.

---

## F1.1 Geschäftsprozess: Gemeinsamen Einkauf organisieren

### Ziel

WG-Mitglieder organisieren gemeinsam ihre Einkäufe über eine zentrale Einkaufsliste. Fehlende Produkte werden erfasst, Einkäufe koordiniert und die dabei entstehenden Kosten transparent auf die beteiligten Mitglieder verteilt.

---

### F1.1.1 Akteure

| Akteur | Typ | Rolle |
|---------|---------|---------|
| WG-Mitglied | Mensch | Plannung der gemeinsamer Einkäufen und Erfassung der gemeinsamer Ausgaben|
| Weitere WG-Mitglieder | Menschen | Sehen Änderungen an der Einkaufsliste in Echtzeit und beteiligen sich an Einkäufen und Ausgaben. |
| WG-ShopSync | IT-System | Verwaltet Einkaufslisten, Ausgaben, Schulden und Synchronisation. |

---

### F1.1.2 Aktivitäten

| Nr. | Aktivität | Beschreibung |
|------|------------|------------|------------|
| A1 | Bedarf feststellen | Ein WG-Mitglied stellt fest, dass ein Produkt benötigt wird. |
| A2 | Einkauf planen. | Die Produkte werden in die gemeinsame Planung hinzugefügt und ist für alle Mitglieder sichtbar. |
| A3 | Einkauf abstimmen. | Die Mitglieder der Wohngemeinschaft informieren sich über die benötigten Produkte und stimmen ihre Einkäufe miteinander ab. |
| A4 | Einkauf durchführen. | Ein Mitglied kauft den Artikel. |
| A5 | Einkauf dokumentieren | Der Artikel wird als gekauft markiert. |
| A6 | Kosten aufteilen | Die Kosten werden auf die beteiligten Mitglieder der Wohngemeinschaft verteilt. |
| A7 | Kostenübersicht bereitstellen | Die Mitglieder erhalten eine Übersicht über ihre Kostenanteile und offenen Salden. |
| A8 | Schulden ausgleichen | Offene Schulden werden außerhalb des Systems zwischen den Mitgliedern beglichen. |
| A9 | Geschäftsprozess abschließen | Einkauf und Kostenaufteilung sind vollständig dokumentiert und nachvollziehbar. |

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
