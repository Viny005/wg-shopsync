# WG-ShopSync – Spezifikation

Dieses Verzeichnis enthält die vollständige Spezifikation des Projekts WG-ShopSync.

Die Spezifikation beschreibt die fachlichen Anforderungen, Datenstrukturen, Qualitätsanforderungen, Querschnittskonzepte und Benutzerschnittstellen der Anwendung.

Sie dient als gemeinsame Grundlage für Entwicklung, Test und Abnahme.

---

# Leseanleitung

Die Spezifikation ist in mehrere Bereiche gegliedert. Jeder Bereich beschreibt einen bestimmten Aspekt des Systems.

---

## Fachliche Anforderungen

Beschreibt die fachliche Sicht auf das System sowie die unterstützten Geschäftsabläufe.

- F1 – Geschäftsprozesse
- F2 – Anwendungsfälle
- F3 – Anwendungsfunktionen

Empfohlene Lesereihenfolge:

```text
F1 → F2 → F3
```

---

## Daten

Beschreibt die fachlichen Datenstrukturen und deren Regeln.

- D1 – Datenmodell
- D2 – Datentypen und Validierungsregeln

Empfohlene Lesereihenfolge:

```text
D1 → D2
```

---

## Nichtfunktionale Anforderungen

Beschreibt Qualitätsziele und systemweite Konzepte.

- N1 – Nichtfunktionale Anforderungen
- N2 – Querschnittskonzepte

Diese Kapitel definieren unter anderem Anforderungen an:

- Sicherheit
- Datenschutz
- Performance
- Verfügbarkeit
- Offline-Nutzung

---

## Benutzerschnittstelle

Beschreibt die Interaktion zwischen Benutzer und System.

- B1 – Dialogspezifikation

Dieses Kapitel enthält:

- Screens
- Navigation
- Benutzerinteraktionen
- GUI-Beschreibungen

---

## Architektur und Rahmenbedingungen

Beschreibt technische und organisatorische Rahmenbedingungen des Projekts.

- P1 – Ziele und Rahmenbedingungen
- P1 – Constraints
- P2 – Architekturüberblick

---

## Systemumfeld

Beschreibt externe Systeme und die Betriebsumgebung.

- S1 – Nachbarsysteme
- S3 – Inbetriebnahme

---

## Ergänzende Dokumentation

Zusätzliche Informationen zum Verständnis der Spezifikation.

- E2 – Glossar
- E3 – Eingesetzte KI-Werkzeuge

---

# Enthaltene Diagramme und Modelle

Die Spezifikation verwendet verschiedene Diagramme und Modelle zur Visualisierung des Systems.

## Use-Case-Diagramm

Datei:

```text
images/anwendungsfaelle-diagramm.png
```

Visualisiert die Akteure und Anwendungsfälle von WG-ShopSync.

---

## Datenmodell

Datei:

```text
images/Information-Model.png
```

Visualisiert die fachlichen Entitäten und deren Beziehungen.

---

## Navigationsdiagramm

Datei:

```text
images/navigationsdiagramm.png
```

Beschreibt die Navigation zwischen den einzelnen Screens der Anwendung.

---

## Architekturdiagramm

Datei:

```text
images/wg-shopsync-Architektur.png
```

Beschreibt die grundlegende Systemarchitektur von WG-ShopSync.

---

# Verwendung der Spezifikation

Die Dokumente dieser Spezifikation sind durch fachliche und technische Querverweise miteinander verbunden.

Für ein vollständiges Verständnis des Systems wird folgende Lesereihenfolge empfohlen:

```text
README
 ↓
F1
 ↓
F2
 ↓
F3
 ↓
D1
 ↓
D2
 ↓
N1
 ↓
N2
 ↓
B1
 ↓
P1
 ↓
P2
 ↓
S1
 ↓
S3
 ↓
E2
 ↓
E3
```

---

## Hinweis zur Dokumentstruktur

Die Nummerierung der Spezifikation orientiert sich an der verwendeten Vorlage.

Einzelne Kapitelnummern können aus strukturellen Gründen nicht belegt sein. Daher existiert kein Kapitel S2.

Für WG-ShopSync sind die Inhalte von S2 nicht relevant und werden nicht benötigt.

---

# Ziel der Spezifikation

Die Spezifikation dient als zentrale Referenz für:

- Entwicklung
- Test
- Qualitätssicherung
- Projektabnahme
- Dokumentation

Sie beschreibt die fachlichen, technischen und qualitativen Anforderungen von WG-ShopSync und bildet die verbindliche Grundlage für die Umsetzung des Systems.
