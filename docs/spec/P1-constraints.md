# P1 – Projektbeschränkungen

Dieser Anhang beschreibt die wesentlichen Rahmenbedingungen und Beschränkungen des Projekts WG-ShopSync.

Projektbeschränkungen definieren den Lösungsraum des Systems und grenzen ihn von möglichen zukünftigen Erweiterungen ab.

---

# 3a. Lösungsbeschränkungen

## CON-3a-01: Eine WG pro Benutzer

Ein Benutzer kann gleichzeitig nur Mitglied einer Wohngemeinschaft sein.

Die Unterstützung mehrerer WGs pro Benutzer ist nicht Bestandteil der ersten Version.

**Begründung:**

Dies reduziert die Komplexität der Anwendung und vereinfacht Datenmodell, Benutzerführung und Synchronisation.

---

## CON-3a-02: Gemeinsame Einkaufsliste

Jede Wohngemeinschaft besitzt genau eine gemeinsame Einkaufsliste.

Alle Mitglieder sehen und bearbeiten dieselbe Liste.

Private Einkaufslisten sind nicht Bestandteil der ersten Version.

**Begründung:**

Die gemeinsame Organisation von Einkäufen ist die Kernfunktion des Systems.

---

## CON-3a-03: Kostenaufteilung ohne Zahlungsabwicklung

WG-ShopSync unterstützt ausschließlich die Berechnung und Darstellung von Schulden und Kostenanteilen.

Zahlungsfunktionen, Bankanbindungen oder Geldtransfers sind nicht Bestandteil des Systems.

**Begründung:**

Die Anwendung dient der Organisation und Transparenz gemeinsamer Ausgaben.

---

## CON-3a-04: Einfache Rollenstruktur

Das System unterscheidet lediglich zwischen:

- WG-Ersteller
- WG-Mitglied

Weitere Rollen oder komplexe Berechtigungskonzepte sind nicht vorgesehen.

**Begründung:**

Die vorgesehene Zielgruppe benötigt keine komplexe Rechteverwaltung.

---

# 3b. Technische Rahmenbedingungen

## CON-3b-01: Plattformübergreifende Nutzung

Die Anwendung soll auf folgenden Plattformen nutzbar sein:

- Smartphone
- Tablet
- Webbrowser

Die konkrete technische Umsetzung wird im Architekturteil festgelegt.

**Begründung:**

Mitglieder einer WG nutzen unterschiedliche Geräte.

---

## CON-3b-02: Offline-Unterstützung

Wichtige Kernfunktionen sollen auch ohne aktive Internetverbindung nutzbar sein.

Datenänderungen können lokal gespeichert und später synchronisiert werden.

**Begründung:**

Eine stabile Internetverbindung kann nicht jederzeit vorausgesetzt werden.

---

## CON-3b-03: Echtzeit-Synchronisation

Änderungen an Einkaufslisten und Ausgaben sollen für alle Mitglieder möglichst zeitnah sichtbar sein.

**Begründung:**

Die Vermeidung von Doppelkäufen setzt aktuelle Daten voraus.

---

# 3c. Partner- und Nachbarsysteme

## CON-3c-01: Zentrale Datensynchronisation

Das System benötigt eine zentrale Cloud-Datenhaltung für die Synchronisation zwischen den Mitgliedern einer WG.

Die konkrete Technologie wird im Rahmen der Architekturentscheidung festgelegt.

**Begründung:**

Eine gemeinsame Einkaufsliste erfordert einen konsistenten Datenbestand.

---

# 3e. Nutzungskontext

## CON-3e-01: Nutzung innerhalb von Wohngemeinschaften

Die Anwendung ist primär für Wohngemeinschaften konzipiert.

Andere Anwendungsbereiche werden innerhalb des Projekts nicht betrachtet.

**Begründung:**

Die funktionalen Anforderungen orientieren sich am WG-Alltag.

---

# 3f. Terminliche Rahmenbedingungen

## CON-3f-01: Hochschulprojekt

Die Entwicklung erfolgt im Rahmen des Moduls WK_1106.

Die Umsetzung orientiert sich an den vorgegebenen Meilensteinen des Moduls.

**Begründung:**

Die Projektplanung wird durch die Lehrveranstaltung bestimmt.

---

# 3g. Ressourcenbeschränkungen

## CON-3g-01: Entwicklung durch ein studentisches Team

Das Projekt wird von sechs Studierenden innerhalb eines Semesters umgesetzt.

**Begründung:**

Der Funktionsumfang muss realistisch umsetzbar bleiben.

---

## CON-3g-02: Fokus auf MVP

Die erste Version konzentriert sich auf folgende Kernfunktionen:

- Benutzerverwaltung
- WG-Verwaltung
- Einkaufsliste
- Kostenaufteilung
- Synchronisation

Weitere Funktionen werden als zukünftige Erweiterungen betrachtet.

**Begründung:**

Die Fertigstellung einer stabilen und nutzbaren Grundversion besitzt höchste Priorität.