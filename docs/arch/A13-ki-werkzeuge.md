# A13 – Eingesetzte KI-Werkzeuge in Architektur und Entwicklung

Dieses Kapitel ergänzt [E3 – Eingesetzte KI-Werkzeuge](../spec/E3-eingesetzte-ki-werkzeuge.md) um die Nutzung KI-gestützter Werkzeuge speziell für Architektur und Implementierung.

## Verwendete Werkzeuge

- GitHub Copilot
- ChatGPT

## Einsatzbereiche

- Unterstützung bei der Formulierung und Strukturierung der Architekturdokumentation.
- Unterstützung bei der Erstellung und Überarbeitung von Code, Tests und Security Rules.
- Vorschläge zur Konsistenzprüfung zwischen Architektur- und Spezifikationsdokumenten.

## Verifikation der Ergebnisse

Alle KI-generierten Vorschläge werden vor der Übernahme verifiziert:

- Manuelle Prüfung durch die Entwickler.
- Kontrolle über `git diff` vor jedem Commit.
- Statische Analyse über `flutter analyze`.
- Ausführung der automatisierten Tests (`flutter test`).

Die fachliche und technische Verantwortung für alle Inhalte verbleibt bei den Autoren des Projekts.
