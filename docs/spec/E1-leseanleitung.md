# E1 – Leseanleitung

Dieses Dokument beschreibt die Anforderungen, Datenstrukturen, Qualitätsanforderungen und Benutzerschnittstellen der Anwendung WG‑ShopSync.

Die Spezifikation ist in mehrere Blöcke gegliedert, die jeweils unterschiedliche Aspekte des Systems beschreiben.

## Aufbau des Dokuments

### Block 1 – Fachliche Anforderungen

Beschreibt die fachlichen Anforderungen an das System.

- F1: Geschäftsprozesse
- F2: Anwendungsfälle
- F3: Anwendungsfunktionen

Die fachlichen Anforderungen definieren, welche Funktionen das System bereitstellt und welche Abläufe durch die Anwendung unterstützt werden.

---

### Block 2 – Daten

Beschreibt die im System verwendeten Datenstrukturen.

- D1: Datenmodell
- D2: Datentypen und Validierungsregeln

Dieser Block legt fest, welche Informationen gespeichert werden und welche Regeln für deren Verarbeitung gelten.

---

### Block 3 – Nichtfunktionale Anforderungen

Beschreibt Qualitätsanforderungen und technische Querschnittskonzepte.

- N1: Nichtfunktionale Anforderungen
- N2: Querschnittskonzepte

Dieser Block definiert unter anderem Anforderungen an Sicherheit, Performance, Verfügbarkeit, Synchronisation und Datenschutz.

---

### Block 4 – Benutzerschnittstelle

Beschreibt die Interaktion zwischen Benutzer und System.

- B1: Dialogspezifikation
- B2: Batch (nicht anwendbar)
- B3: Druckausgaben (nicht anwendbar)

Dieser Block enthält die Beschreibung der einzelnen Screens, ihrer Navigation sowie der Benutzerinteraktionen.

---

### Block 5 – Systemumgebung

Beschreibt die technische Infrastruktur und Inbetriebnahme.

- S1: Technische Infrastruktur
- S2: Datenmigration (nicht anwendbar)
- S3: Inbetriebnahme

---

### Block 6 – Ergänzende Dokumente

Enthält zusätzliche Informationen zum Verständnis der Spezifikation.

- E1: Leseanleitung
- E2: Glossar
- E3: Eingesetzte KI-Werkzeuge

---

## Verwendung der Spezifikation

Die Spezifikation dient als gemeinsame Grundlage für Entwicklung, Test und Abnahme von WG‑ShopSync.

Die funktionalen Anforderungen beschreiben das gewünschte Verhalten des Systems. Die Datenmodelle definieren die verwendeten Informationen. Die nichtfunktionalen Anforderungen legen Qualitätsziele fest. Die Dialogspezifikation beschreibt die Benutzeroberfläche und die Interaktion mit dem System.

Alle Kapitel sind durch Querverweise miteinander verbunden und sollten für ein vollständiges Verständnis gemeinsam betrachtet werden.

## Abgrenzung

Nicht Bestandteil der Spezifikation sind eine tatsächliche Zahlungsabwicklung, Bank- oder Finanzdienstleisterintegrationen, Preisvergleiche, Online-Shop-APIs, automatische Bon-Erkennung, Push-Benachrichtigungen, private Einkaufslisten und die Verwaltung mehrerer WGs pro Benutzer. Diese Punkte sind in P1.4 als Out of Scope abgegrenzt.