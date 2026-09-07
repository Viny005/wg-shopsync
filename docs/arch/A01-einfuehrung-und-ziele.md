# A01 – Einführung und Ziele

Dieses Kapitel beschreibt die fachliche Aufgabenstellung, die treibenden Qualitätsziele und die wesentlichen Stakeholder der Anwendung WG-ShopSync. Die verbindlichen Anforderungen sind in der [Gesamtspezifikation](../spec/README.md) dokumentiert.

## 1.1 Anforderungsübersicht

WG-ShopSync ist eine browserbasierte Webanwendung für Wohngemeinschaften. Mitglieder können sich registrieren und anmelden, einer WG beitreten oder eine WG erstellen, eine gemeinsame Einkaufsliste verwalten und Artikel als gekauft markieren. Zusätzlich lassen sich gemeinsame Ausgaben erfassen, gleichmäßig auf alle oder ausgewählte Mitglieder verteilen und daraus offene Salden beziehungsweise Schulden ableiten.

Die Anwendung reduziert typische Probleme im WG-Alltag wie Doppelkäufe, vergessene Einkäufe, Zettelwirtschaft und unübersichtliche Kostenaufteilungen. Änderungen an der Einkaufsliste werden für die Mitglieder derselben WG nahezu in Echtzeit sichtbar. Bereits synchronisierte Einkaufslistendaten bleiben offline bearbeitbar und werden nach Wiederherstellung der Verbindung synchronisiert.

WG-ShopSync ist kein Online-Shop und ersetzt keine Zahlung. Die Anwendung dokumentiert organisatorische und finanzielle Informationen, berechnet Kostenanteile und stellt Schuldenübersichten dar. Eine tatsächliche Zahlungsabwicklung findet außerhalb des Systems statt.

Die fachlichen Ziele und der Projektumfang sind in [P1 – Ziele und Rahmenbedingungen](../spec/P1-ziele-rahmenbedingungen.md) beschrieben. Die relevanten Anwendungsfälle und Funktionen befinden sich in [F2 – Anwendungsfälle](../spec/F2-anwendungsfaelle.md) und [F3 – Anwendungsfunktionen](../spec/F3-anwendungsfunktionen.md).

### Fachliche Hauptziele

Das System verfolgt die folgenden funktionalen und technischen Ziele:

| ID | Ziel |
|---|---|
| G-01 | Eine gemeinsame Einkaufsliste für alle Mitglieder einer WG bereitstellen. |
| G-02 | Doppelkäufe vermeiden, indem alle Mitglieder denselben aktuellen Listenstand sehen. |
| G-03 | Transparenz über offene (`open`) und bereits erledigte (`bought`) Einkäufe schaffen. |
| G-04 | Die Organisation gemeinsamer Einkäufe durch Kategorien und Mengenangaben vereinfachen. |
| G-05 | Gemeinsame Ausgaben gleichmäßig auf alle oder ausgewählte Mitglieder aufteilen. |
| G-06 | Offene Forderungen und Verbindlichkeiten zwischen WG-Mitgliedern nachvollziehbar darstellen. |
| G-07 | Änderungen an Einkaufslisten für alle Mitglieder nahezu in Echtzeit bereitstellen. |
| G-08 | Die Anwendung als responsive Webanwendung im Browser nutzbar machen. |
| G-09 | Bereits synchronisierte Einkaufslistendaten offline bearbeiten und nach dem Reconnect automatisch synchronisieren. |

### In Scope

Die erste Version umfasst Benutzerregistrierung und Anmeldung, WG-Erstellung, WG-Beitritt per eindeutigem Einladungscode, die gemeinsame Einkaufsliste, Kategorien und Mengenangaben, die Kennzeichnung gekaufter Artikel, Echtzeit-Synchronisation, Ausgaben, Kostenaufteilung, Schuldenstatus sowie die Nutzung als responsive Webanwendung im Browser.

### Out of Scope

Nicht enthalten sind Zahlungsfunktionen, Bank- oder Finanzdienstleisterintegration, Preisvergleich, Anbindungen an Supermarkt- oder Online-Shop-APIs, automatische Bon-Erkennung, Push-Benachrichtigungen, private Einkaufslisten und mehrere WGs pro Benutzer. Ein komplexes Rollen- und Berechtigungssystem ist nicht Bestandteil der ersten Version; vorgesehen sind die Rollen `admin` und `member`.

## 1.2 Qualitätsziele

Die folgenden Qualitätsziele sind für die Architektur besonders relevant und werden durch die Anforderungen in der Gesamtspezifikation konkretisiert.

| Priorität | Qualitätsziel | Szenario / Fit Criterion | Verweis |
|:---:|---|---|---|
| 1 | **Zuverlässigkeit** (Integrität und Fehlertoleranz) | Änderungen an der Einkaufsliste werden bei bestehender Verbindung innerhalb von 2 Sekunden auf verbundenen Geräten angezeigt. Offline vorgenommene Änderungen werden nach dem Reconnect automatisch synchronisiert. | N1.1-01, N1.3-03, BR-13 |
| 2 | **Funktionalität** (Sicherheit und Mandantentrennung) | Ein Benutzer kann ausschließlich Einkaufslisten und Ausgaben der eigenen WG lesen oder bearbeiten und sieht in der Schuldensicht nur die eigenen offenen und bezahlten Schulden. | N1.2-01, N1.2-02, N2.2 |
| 3 | **Benutzbarkeit** (Bedienbarkeit und Erlernbarkeit) | Ein neuer Artikel kann mit höchstens drei Benutzeraktionen hinzugefügt werden. Die Kernfunktionen sind ohne vorheriges Studium einer Anleitung verständlich; Fehlermeldungen enthalten eine verständliche Folgeaktion. | N1.4-01, N1.4-02, N1.4-03 |
| 4 | **Wartbarkeit** (Testbarkeit und Änderbarkeit) | Präsentation, Anwendungslogik, Datenzugriff und lokale Synchronisation sind getrennt. Die Kosten-, Saldo- und Statusberechnung kann unabhängig vom Firebase-Zugriff getestet werden. | A04, A08, N2.4 |
| 5 | **Portabilität** (Anpassbarkeit und Installierbarkeit) | Die Kernfunktionen stehen in modernen Desktop- und mobilen Webbrowsern über eine gemeinsame Web-Codebasis zur Verfügung. | [ADR-01](A09-architekturentscheidungen.md), [N1.3-01](../spec/N1-nichtfunktional-anforderungen.md) |

Die Ziele Zuverlässigkeit und Funktionalität sind eng gekoppelt: Die gemeinsame Datenbasis und die Offline-Persistenz müssen einerseits eine schnelle Zusammenarbeit ermöglichen, andererseits dürfen Benutzer niemals auf Daten einer fremden WG zugreifen. Die Architekturentscheidungen und die systemweiten Konzepte konkretisieren diese Ziele in [A08 – Querschnittliche Konzepte](A08-querschnittliche-konzepte.md) und [A09 – Architekturentscheidungen](A09-architekturentscheidungen.md).

## 1.3 Stakeholder

| Stakeholder | Beschreibung und Interessen | Beteiligung / Relevanz für die Abnahme |
|---|---|---|
| **WG-Mitglied** (primärer Anwender) | Einkaufsliste und Ausgaben im Alltag schnell, einfach und fehlerarm verwalten; eigene Salden transparent sehen. | Liefert Usability-Feedback und führt die wichtigsten Abnahmetests durch. |
| **WG-Ersteller** (`admin`) | WG anlegen, den Einladungscode anzeigen und die WG im vorgesehenen Umfang verwalten. | Prüft insbesondere WG-Erstellung, Beitritt und Rollenverhalten. |
| **Entwicklerteam** (sechs Studierende) | Eine erweiterbare, dokumentierte, testbare Webanwendung im Rahmen des Moduls WK_1106 erstellen. | Verantwortlich für Spezifikation, Architektur, Implementierung, Tests und Präsentation. |
| **Betreuer und Prüfer** (Prof. Dr. Carsten Lucke) | Nachvollziehbare Anforderungen, konsistente Architektur- und Spezifikationsdokumente sowie saubere Git-Hygiene. | Bewertet den Projektstand, die Dokumentation und den Code-Walkthrough. |

Ausführliche Stakeholderbeschreibungen und Rahmenbedingungen sind in [P1.3 Stakeholder und Benutzer](../spec/P1-ziele-rahmenbedingungen.md) sowie in [P1.5 Rahmenbedingungen und Einschränkungen](../spec/P1-ziele-rahmenbedingungen.md) festgehalten.
