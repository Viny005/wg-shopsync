# P1 – Ziele und Rahmenbedingungen

## P1.1 Mission

WG-ShopSync ist eine plattformübergreifende Anwendung zur Organisation gemeinsamer Einkäufe in Wohngemeinschaften.

Die Anwendung ermöglicht es Mitgliedern einer Wohngemeinschaft, eine gemeinsame Einkaufsliste zu verwalten, Einkäufe zu koordinieren und gemeinsame Ausgaben transparent aufzuteilen.

Ziel ist es, typische Probleme im WG-Alltag wie Doppelkäufe, vergessene Einkäufe und unübersichtliche Kostenaufteilungen zu vermeiden. Darüber hinaus soll die Zusammenarbeit innerhalb der WG vereinfacht und die Transparenz über gemeinsame Ausgaben erhöht werden.

## P1.2 Projektziele

| ID | Ziel |
|----|------|
| G-01 | Eine gemeinsame Einkaufsliste für alle Mitglieder einer WG bereitstellen. |
| G-02 | Doppelkäufe vermeiden, indem alle Mitglieder denselben aktuellen Listenstand sehen. |
| G-03 | Transparenz über offene und bereits erledigte Einkäufe schaffen. |
| G-04 | Die Organisation gemeinsamer Einkäufe vereinfachen. |
| G-05 | Gemeinsame Ausgaben nachvollziehbar und automatisch auf beteiligte Mitglieder aufteilen. |
| G-06 | Schulden zwischen WG-Mitgliedern nachvollziehbar darstellen. |
| G-07 | Änderungen an Einkaufslisten für alle Mitglieder nahezu in Echtzeit bereitstellen. |
| G-08 | Die Anwendung auf Smartphones, Tablets und im Web nutzbar machen. |
| G-09 | Wichtige Funktionen auch bei temporär fehlender Internetverbindung nutzbar machen. |

## P1.3 Stakeholder und Benutzer

| Rolle | Beschreibung | Interaktion mit WG-ShopSync |
|---------|-------------|-----------------------------|
| WG-Mitglied | Primärer Benutzer der Anwendung. | Verwalten von Einkaufslisten, Erfassen von Ausgaben und Verfolgen eigener Kostenanteile. |
| WG-Ersteller | Erstellt und verwaltet eine Wohngemeinschaft. | Erstellt die WG, verwaltet den Einladungscode und nutzt alle regulären Funktionen der Anwendung. |
| Wohngemeinschaft | Hauptzielgruppe der Anwendung. | Gemeinsame Organisation von Einkäufen und Ausgaben. |
| Entwicklerteam | Verantwortlich für Entwicklung und Wartung des Systems. | Entwicklung, Test und Weiterentwicklung der Anwendung. |
| Betreuer (Prof. Dr. Carsten Lucke) | Fachlicher Begleiter des Projekts. | Bewertung und Feedback im Rahmen des Moduls WK_1106. |

## P1.4 Projektumfang

### In Scope

Die erste Version von WG-ShopSync umfasst folgende Funktionen:

- Benutzerregistrierung und Anmeldung mittels E-Mail und Passwort
- Erstellung einer Wohngemeinschaft (WG)
- Beitritt zu einer WG über einen Einladungscode
- Verwaltung einer gemeinsamen Einkaufsliste pro WG
- Hinzufügen, Bearbeiten und Löschen von Artikeln
- Angabe von Artikelmenge
- Optionale Beschreibung eines Artikels
- Einteilung von Artikeln in Kategorien
- Kennzeichnung von Artikeln als „gekauft“
- Echtzeit-Synchronisation der Einkaufsliste
- Erfassung gemeinsamer Ausgaben
- Automatische Kostenaufteilung auf alle oder ausgewählte Mitglieder
- Darstellung von Schulden zwischen Mitgliedern
- Nutzung auf Smartphones, Tablets und im Webbrowser
- Offline-Nutzung wichtiger Kernfunktionen mit späterer Synchronisation

### Out of Scope

| ID | Nicht-Ziel | Begründung |
|------|------------|------------|
| NG-01 | Zahlungsfunktionen | Die Anwendung berechnet lediglich Kostenanteile und Schulden. |
| NG-02 | Bank- oder Finanzdienstleisterintegration | Nicht erforderlich für den Projektzweck. |
| NG-03 | Preisvergleich | Nicht Bestandteil der Einkaufsorganisation. |
| NG-04 | Anbindung an Supermarkt- oder Online-Shop-APIs | Außerhalb des Projektumfangs. |
| NG-05 | Automatische Bon-Erkennung | Nicht Bestandteil des MVP. |
| NG-06 | Komplexes Rollen- und Berechtigungssystem | WG-Ersteller und WG-Mitglied reichen aus. |
| NG-07 | Push-Benachrichtigungen | Geplante Erweiterung für spätere Versionen. |
| NG-08 | Mehrere WGs pro Benutzer | In der ersten Version ist nur eine WG pro Benutzer vorgesehen. |
| NG-09 | Private Einkaufslisten | Geplante Erweiterung für spätere Versionen. |

## P1.5 Rahmenbedingungen und Einschränkungen

Detaillierte Projektbeschränkungen werden im Dokument
`P1-constraints.md` beschrieben.

| ID | Rahmenbedingung |
|----|-----------------|
| CON-01 | Projekt im Rahmen des Moduls WK_1106 |
| CON-02 | Entwicklung durch ein Team aus sechs Studierenden |
| CON-03 | Plattformübergreifende Entwicklung mit Unterstützung von Smartphones, Tablets und Webbrowsern |
| CON-04 | Gemeinsame Nutzung innerhalb von Wohngemeinschaften |
| CON-05 | Eine Benutzerin bzw. ein Benutzer kann gleichzeitig nur einer WG angehören |
| CON-06 | Kostenaufteilung ohne integrierte Zahlungsabwicklung |
| CON-07 | Zentrale Cloud-Datenhaltung für die Synchronisation erforderlich |
| CON-08 | Offline-Nutzung wichtiger Kernfunktionen soll unterstützt werden |
| CON-09 | Spezifikation und Architekturdokumentation werden als Markdown-Dateien im Repository geführt |

## P1.6 Erfolgskriterien

| ID | Kriterium |
|----|-----------|
| SC-01 | Mehrere Mitglieder einer WG können dieselbe Einkaufsliste gemeinsam nutzen. |
| SC-02 | Neue Artikel werden nach dem Hinzufügen für alle Mitglieder sichtbar. |
| SC-03 | Artikel können als „gekauft“ markiert werden. |
| SC-04 | Gemeinsame Ausgaben können erfasst und automatisch auf alle oder ausgewählte Mitglieder verteilt werden. |
| SC-05 | Das System berechnet Schulden zwischen WG-Mitgliedern korrekt. |
| SC-06 | Mitglieder sehen ihre eigenen Kostenanteile und offenen Schulden. |
| SC-07 | Änderungen werden für alle Mitglieder nahezu in Echtzeit synchronisiert. |
| SC-08 | Die Anwendung funktioniert auf Smartphones, Tablets und im Webbrowser. |

## P1.7 Annahmen

| ID | Annahme |
|----|----------|
| AS-01 | Benutzer verfügen über ein internetfähiges Endgerät (Smartphone, Tablet oder Computer). |
| AS-02 | Für Registrierung, Anmeldung und Erstellung einer WG ist eine Internetverbindung erforderlich. |
| AS-03 | Mitglieder einer WG verwenden dieselbe gemeinsame Einkaufsliste innerhalb der App. |
| AS-04 | Die Kostenaufteilung dient ausschließlich der Übersicht und ersetzt keine tatsächliche Zahlungsabwicklung. |
| AS-05 | Benutzer sind bereit, gemeinsame Ausgaben korrekt und vollständig in der Anwendung zu erfassen. |
| AS-06 | Die zentrale Datensynchronisation ist verfügbar, sobald eine Internetverbindung besteht. |

## P1.8 Risiken

| ID | Risiko | Gegenmaßnahme |
|----|---------|---------------|
| R-01 | Gleichzeitige Änderungen durch mehrere Benutzer können zu Synchronisationskonflikten führen. | Last-Write-Wins-Strategie im MVP. |
| R-02 | Eine fehlende Internetverbindung verhindert den sofortigen Datenaustausch. | Lokale Speicherung und spätere Synchronisation. |
| R-03 | Fehler bei der Synchronisation können zu unterschiedlichen Listenständen führen. | Regelmäßige Synchronisation und zentrale Datenhaltung. |
| R-04 | Der Ersteller einer WG verlässt die WG. | Automatische Übergabe der Erstellerrolle an ein anderes Mitglied. |
| R-05 | Benutzer erfassen Ausgaben oder Artikel unvollständig oder fehlerhaft. | Einfache Benutzeroberfläche und Eingabevalidierung. |
| R-06 | Eine geringe Nutzerakzeptanz kann den Nutzen der Anwendung einschränken. | Fokus auf einfache und intuitive Bedienbarkeit. |