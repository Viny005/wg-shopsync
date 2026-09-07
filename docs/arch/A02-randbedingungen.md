# A02 – Randbedingungen

Randbedingungen legen den verbindlichen Lösungsraum für die Architektur von WG-ShopSync fest. Sie ergeben sich aus den Anforderungen und Projektbeschränkungen der [Gesamtspezifikation](../spec/README.md), aus den bereits getroffenen Architekturentscheidungen sowie aus den organisatorischen Vorgaben des Moduls WK_1106.

Die folgende Übersicht dient als Arbeitsregister. Detaillierte Begründungen und fachliche Erläuterungen verbleiben in den jeweils verlinkten Quelldokumenten.

---

## 2.1 Technische Randbedingungen

| ID | Randbedingung | Beschreibung / Quelle |
|---|---|---|
| TECH-01 | Responsive Webanwendung | Die Anwendung wird als browserbasierte Webanwendung für moderne Desktop- und mobile Webbrowser umgesetzt. Siehe [ADR-01](A09-architekturentscheidungen.md) und [CON-3b-01](../spec/P1-constraints.md#con-3b-01-nutzung-als-webanwendung). |
| TECH-02 | Browserbasierte Nutzung | Die Kernfunktionen werden ohne native Android-, iOS- oder Tablet-Anwendung im unterstützten Webbrowser bereitgestellt. Siehe [N1.3-01](../spec/N1-nichtfunktional-anforderungen.md#n131-plattformunterstützung). |
| TECH-03 | Firebase Authentication | Registrierung, Anmeldung und Sitzungsverwaltung werden über Firebase Authentication realisiert. Siehe [ADR-02](A09-architekturentscheidungen.md) und [N1.2-01](../spec/N1-nichtfunktional-anforderungen.md#n121-benutzerauthentifizierung). |
| TECH-04 | Cloud Firestore als zentrale Datenhaltung | Gemeinsame WG-Daten werden zentral in Cloud Firestore gespeichert. Firestore stellt die Echtzeit-Listener und die Offline-Persistenz für bereits synchronisierte Einkaufslistendaten bereit. Siehe [ADR-03](A09-architekturentscheidungen.md) und [CON-3c-01](../spec/P1-constraints.md#con-3c-01-zentrale-datensynchronisation). |
| TECH-05 | Kein eigener App-Server | In der ersten Version wird kein separater Backend- oder App-Server betrieben. Der Zugriff auf Firebase erfolgt über die offiziellen Firebase Web-SDKs. Siehe [ADR-04](A09-architekturentscheidungen.md). |
| TECH-06 | Echtzeit-Synchronisation | Änderungen an Einkaufslisten sollen für alle Mitglieder derselben WG innerhalb von höchstens 2 Sekunden sichtbar werden. Siehe [N1.1-01](../spec/N1-nichtfunktional-anforderungen.md#n111-echtzeit-synchronisation) und [CON-3b-03](../spec/P1-constraints.md#con-3b-03-echtzeit-synchronisation). |
| TECH-07 | Eingeschränkter Offline-Modus | Offline können bereits synchronisierte Einkaufslistendaten angezeigt und bearbeitet werden. Registrierung, Login ohne lokale Sitzung, WG-Erstellung und WG-Beitritt benötigen eine Verbindung. Siehe [N1.3-03](../spec/N1-nichtfunktional-anforderungen.md#n133-offline-verfügbarkeit) und [N2.3](../spec/N2-querschnittskonzepte.md#n23-offline-modus). |
| TECH-08 | Sicherheitsregeln auf Datenebene | Der Zugriff auf WG-Daten wird durch Authentifizierung und Firestore Security Rules auf berechtigte Mitglieder beschränkt. Die Kommunikation erfolgt über HTTPS. Siehe [N1.2](../spec/N1-nichtfunktional-anforderungen.md#n12-sicherheitsanforderungen) und [N2.2](../spec/N2-querschnittskonzepte.md#n22-autorisierung). |
| TECH-09 | Kontrollierte Geldbeträge | Beträge werden mit zwei Nachkommastellen verarbeitet. Rundungsdifferenzen bei der Kostenaufteilung werden kontrolliert ausgeglichen. Siehe [N2](../spec/N2-querschnittskonzepte.md) und [AF-01](../spec/F3-anwendungsfunktionen.md#af-01-kostenaufteilung-berechnen). |

---

## 2.2 Fachliche und organisatorische Randbedingungen

| ID | Randbedingung | Beschreibung / Quelle |
|---|---|---|
| ORG-01 | Hochschulprojekt | Die Entwicklung erfolgt im Rahmen des Moduls WK_1106 und orientiert sich an den vorgegebenen Projektmeilensteinen. Siehe [CON-3f-01](../spec/P1-constraints.md#con-3f-01-hochschulprojekt). |
| ORG-02 | Entwicklung durch sechs Studierende | Konzept, Architektur, Implementierung und Tests werden durch ein studentisches Team aus sechs Personen erstellt. Siehe [TEAMINFO.md](../../TEAMINFO.md) und [CON-3g-01](../spec/P1-constraints.md#con-3g-01-entwicklung-durch-ein-studentisches-team). |
| ORG-03 | Fokus auf ein MVP | Die erste Version konzentriert sich auf Benutzerverwaltung, WG-Verwaltung, Einkaufsliste, Kostenaufteilung und Synchronisation. Siehe [CON-3g-02](../spec/P1-constraints.md#con-3g-02-fokus-auf-mvp). |
| ORG-04 | Eine WG pro Benutzer | Ein Benutzer kann in der ersten Version gleichzeitig nur Mitglied einer WG sein. Siehe [CON-3a-01](../spec/P1-constraints.md#con-3a-01-eine-wg-pro-benutzer). |
| ORG-05 | Eine gemeinsame Einkaufsliste | Jede WG besitzt genau eine gemeinsame Einkaufsliste. Private Einkaufslisten sind nicht Bestandteil der ersten Version. Siehe [CON-3a-02](../spec/P1-constraints.md#con-3a-02-gemeinsame-einkaufsliste). |
| ORG-06 | Einfache Rollenstruktur | Das System unterscheidet nur zwischen `admin` und `member`. Komplexe Rollen- und Berechtigungskonzepte sind nicht vorgesehen. Siehe [CON-3a-04](../spec/P1-constraints.md#con-3a-04-einfache-rollenstruktur) und [ADR-06](A09-architekturentscheidungen.md). |
| ORG-07 | Keine Zahlungsabwicklung | WG-ShopSync berechnet und dokumentiert Kostenanteile sowie Schulden. Zahlungen, Bankanbindungen und Geldtransfers erfolgen außerhalb des Systems. Siehe [CON-3a-03](../spec/P1-constraints.md#con-3a-03-kostenaufteilung-ohne-zahlungsabwicklung). |
| ORG-08 | Begrenzter Projektumfang | Preisvergleich, Shop-APIs, automatische Bon-Erkennung, Push-Benachrichtigungen und weitere Erweiterungen gehören nicht zum MVP. Siehe [P1.4 Projektumfang](../spec/P1-ziele-rahmenbedingungen.md#p14-projektumfang). |

---

## 2.3 Dokumentations- und Entwicklungskonventionen

| ID | Konvention | Beschreibung / Quelle |
|---|---|---|
| CONV-01 | Trennung von Spezifikation und Architektur | Fachliche Anforderungen werden in `docs/spec/` gepflegt; architekturelle Entscheidungen und Sichten werden in `docs/arch/` dokumentiert. |
| CONV-02 | Markdown-Dokumentation | Spezifikation und Architekturdokumentation werden als versionierte Markdown-Dateien im Repository geführt. Siehe [CON-3f-02](../spec/P1-constraints.md#con-3f-02-dokumentation-im-repository). |
| CONV-03 | Arc42-Struktur | Die Architekturdokumentation folgt dem Arc42-Aufbau mit einem Dokument pro Kapitel und nummerierten Überschriften. Siehe [README.md](../../README.md). |
| CONV-04 | Nachvollziehbare Referenzen | Anforderungen, Architekturentscheidungen und Querschnittskonzepte werden über IDs und relative Markdown-Links miteinander verknüpft. |
| CONV-05 | Git-basierte Zusammenarbeit | Änderungen an Spezifikation und Architektur werden versioniert im gemeinsamen Repository gepflegt und vor der Abnahme nachvollziehbar gehalten. |

Die technischen Entscheidungen werden in [A09 – Architekturentscheidungen](A09-architekturentscheidungen.md) begründet. Die systemweite Umsetzung von Authentifizierung, Autorisierung, Synchronisation, Offline-Modus und Datenvalidierung ist in [A08 – Querschnittliche Konzepte](A08-querschnittliche-konzepte.md) beschrieben.
