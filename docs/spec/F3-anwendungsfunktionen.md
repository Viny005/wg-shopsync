# F3 – Anwendungsfunktionen

Anwendungsfunktionen beschreiben wiederverwendbare fachliche Funktionen, die von mehreren Anwendungsfällen genutzt werden.

Im Gegensatz zu den Anwendungsfällen (F2) beschreiben Anwendungsfunktionen keine Benutzeraktionen, sondern die fachliche Logik des Systems.

---

## F3.1 Funktionsverzeichnis

| ID | Funktion | Zweck |
|----|----------|--------|
| AF-01 | Kostenaufteilung berechnen | Berechnet Kostenanteile für beteiligte Mitglieder |
| AF-02 | Einladungscode erzeugen | Erzeugt einen eindeutigen Einladungscode für eine WG |
| AF-03 | Einladungscode prüfen | Überprüft die Gültigkeit eines Einladungscodes |
| AF-04 | Einkaufsliste sortieren | Ordnet Artikel übersichtlich in der Einkaufsliste an |
| AF-05 | Schuldenstatus aktualisieren | Aktualisiert den Status einer Schuld |
| AF-06 | Saldo berechnen | Berechnet offene Forderungen und Verbindlichkeiten zwischen Mitgliedern |

---

## F3.2 Funktionsbeschreibungen

### AF-01 – Kostenaufteilung berechnen

| Rubrik | Inhalt |
|---------|---------|
| Zweck | Berechnet die Kostenanteile der beteiligten Mitglieder einer Ausgabe. |
| Eingaben | Gesamtbetrag einer Ausgabe, beteiligte Mitglieder |
| Ausgaben | Kostenanteile pro Mitglied |
| Regeln | - Der Gesamtbetrag wird gleichmäßig verteilt.<br>- Die Aufteilung kann auf alle Mitglieder oder nur auf ausgewählte Mitglieder erfolgen.<br>- Die Summe aller Anteile entspricht dem Gesamtbetrag.<br>- Rundungsdifferenzen werden automatisch ausgeglichen. |
| Verwendet von | UC-11 Ausgabe erfassen, UC-12 Ausgabe bearbeiten, UC-14 Kosten aufteilen |

---

### AF-02 – Einladungscode erzeugen

| Rubrik | Inhalt |
|---------|---------|
| Zweck | Erzeugt einen eindeutigen Einladungscode für eine Wohngemeinschaft. |
| Eingaben | WG-Daten |
| Ausgaben | Einladungscode |
| Regeln | - Jeder Einladungscode ist eindeutig.<br>- Der Code wird automatisch erzeugt.<br>- Der Code bleibt dauerhaft gültig. |
| Verwendet von | UC-03 WG erstellen |

---

### AF-03 – Einladungscode prüfen

| Rubrik | Inhalt |
|---------|---------|
| Zweck | Prüft, ob ein Einladungscode gültig ist. |
| Eingaben | Einladungscode |
| Ausgaben | Gültig / Ungültig |
| Regeln | - Der Code muss existieren.<br>- Nur gültige Codes erlauben den Beitritt zur Wohngemeinschaft. |
| Verwendet von | UC-04 WG beitreten |

---

### AF-04 – Einkaufsliste sortieren

| Rubrik | Inhalt |
|---------|---------|
| Zweck | Ordnet die Einkaufsliste übersichtlich an. |
| Eingaben | Einkaufsliste |
| Ausgaben | Sortierte Einkaufsliste |
| Regeln | - Offene Artikel werden vor gekauften Artikeln angezeigt.<br>- Innerhalb der Gruppen erfolgt die Sortierung alphabetisch. |
| Verwendet von | UC-10 Einkaufsliste anzeigen |

---

### AF-05 – Schuldenstatus aktualisieren

| Rubrik | Inhalt |
|---------|---------|
| Zweck | Aktualisiert den Status einer bestehenden Schuld. |
| Eingaben | Schuld, Benutzeraktion „Als bezahlt markieren“ |
| Ausgaben | Aktualisierte Schuld |
| Regeln | - Nur bestehende Schulden können aktualisiert werden.<br>- Der Status wechselt von „Offen“ zu „Bezahlt“.<br>- Das Zahlungsdatum wird gespeichert.<br>- Der ursprüngliche Betrag bleibt unverändert. |
| Verwendet von | UC-15 Schulden anzeigen, UC-16 Schuld als bezahlt markieren |

---

### AF-06 – Saldo berechnen

| Rubrik | Inhalt |
|---------|---------|
| Zweck | Berechnet Forderungen und Verbindlichkeiten zwischen Mitgliedern einer Wohngemeinschaft. |
| Eingaben | Ausgaben, Kostenanteile, Zahlungsstatus |
| Ausgaben | Aktuelle Salden der Mitglieder |
| Regeln | - Für jede Ausgabe werden Kostenanteile berücksichtigt.<br>- Bereits bezahlte Schulden werden nicht mehr als offen berücksichtigt.<br>- Der Saldo zeigt, wer Geld erhält und wer Geld schuldet. |
| Verwendet von | UC-14 Kosten aufteilen, UC-15 Schulden anzeigen, UC-17 Kostenübersicht anzeigen |

---

## F3.3 Nicht Bestandteil von F3

Folgende Aspekte werden nicht in F3 beschrieben:

- Benutzeroberflächen und Dialoge
- Authentifizierung
- Echtzeit-Synchronisation
- Offline-Synchronisation
- Datenbankoperationen
- API-Aufrufe
- Speicherung von Daten

Diese Aspekte werden in anderen Bausteinen der Spezifikation beschrieben.

---

## F3.4 Zusammenhang mit anderen Bausteinen

| Baustein | Bezug |
|------------|---------|
| F1 | Die Geschäftsprozesse nutzen die beschriebenen Anwendungsfunktionen |
| F2 | Die Anwendungsfälle rufen die Anwendungsfunktionen auf |
| D1 | Die Funktionen arbeiten auf den Datenobjekten des Datenmodells |
| D2 | Die Funktionen verwenden die definierten Datentypen |
| N2 | Querschnittskonzepte ergänzen die Funktionen um technische Konzepte |