# A08 – Querschnittliche Konzepte

Dieses Kapitel beschreibt Konzepte, die mehrere Bausteine und Anwendungsfälle von WG-ShopSync betreffen. Die fachlichen Anforderungen dazu sind in [N2 – Querschnittskonzepte](../spec/N2-querschnittskonzepte.md) und den verlinkten Anwendungsfunktionen beschrieben.

## 8.1 Authentifizierung und Autorisierung

Firebase Authentication verwaltet Registrierung, Anmeldung, Sitzung und Benutzer-ID. Firestore Security Rules prüfen bei jedem Zugriff, ob der authentifizierte Benutzer Mitglied der adressierten WG ist.

- `admin` ist der Ersteller der WG und darf den Einladungscode anzeigen sowie die WG im vorgesehenen Umfang verwalten.
- `member` darf Artikel und Ausgaben verwalten, Schulden einsehen und eigene Schulden als bezahlt markieren.
- Der letzte `admin` darf die WG nicht verlassen, solange kein anderer `admin` vorhanden ist.
- `paidBy`, `creditorId` und `debtorId` dürfen nur auf Benutzer derselben WG verweisen.
- Ein Benutzer darf keine Einkaufslisten, Ausgaben oder Schulden einer fremden WG lesen oder verändern.

Die Autorisierung wird nicht nur in der UI ausgeblendet, sondern serverseitig durch Firestore Security Rules erzwungen. Ein Zugriff ist nur möglich, wenn `request.auth.uid` eine Membership für dieselbe `wgId` besitzt. `paidBy`, `creditorId` und `debtorId` dürfen nur auf Mitglieder derselben WG verweisen. Die fachliche Berechnung von Kostenanteilen und Salden bleibt Aufgabe der Anwendungslogik.

Beispielhafte Regelstruktur:

```text
allow read, write: if request.auth != null
	&& exists(/databases/$(database)/documents/wgs/$(wgId)/memberships/$(request.auth.uid));
```

## 8.2 Datenvalidierung

Eingaben werden in der UI für unmittelbares Feedback und vor dem Schreiben nochmals in der Anwendungslogik geprüft. Sicherheitsrelevante Zugriffsgrenzen werden zusätzlich durch Firestore Security Rules geschützt.

- Benutzername: 2 bis 50 Zeichen, nicht leer.
- Artikelname: 1 bis 100 Zeichen, nicht leer.
- Artikelbeschreibung: optional, höchstens 500 Zeichen.
- Menge: positive Ganzzahl.
- Ausgabe: Betrag größer als 0, Beschreibung nicht leer, mindestens ein Kostenbeteiligter.
- Einladungscode: sechs alphanumerische Zeichen, systemweit eindeutig und gültig.

Ungültige Eingaben werden nicht gespeichert. Fehlermeldungen unterscheiden Validierungs-, Authentifizierungs-, Netzwerk- und Synchronisationsfehler und nennen, sofern möglich, eine konkrete Folgeaktion.

## 8.3 Synchronisation und Offline-Modus

Cloud Firestore stellt Realtime-Listener und Offline-Persistenz bereit. Unterstützt werden offline ausschließlich bereits synchronisierte Einkaufslistendaten. Registrierung, Login ohne lokale Sitzung, WG-Erstellung und WG-Beitritt benötigen eine Verbindung.

Nach Wiederherstellung der Verbindung werden lokale Änderungen automatisch synchronisiert. Bei konkurrierenden Änderungen gilt der serverseitige Datenstand. Der Konflikt wird dem Benutzer verständlich angezeigt; die lokale Änderung geht nicht stillschweigend verloren, sondern kann über eine erneute Aktion wie „Erneut anwenden“ nach Prüfung wieder an den Server gesendet werden. Ausgaben und Schulden besitzen im MVP keinen eigenständigen Offline-Workflow.

## 8.4 Fehlerbehandlung

Technische Details werden protokolliert, aber nicht direkt angezeigt. Die Benutzeroberfläche behandelt mindestens folgende Fehlerklassen:

| Fehlerklasse | Beispiel | Folgeaktion |
|---|---|---|
| Validierung | Betrag oder Pflichtfeld ungültig | Eingabe korrigieren |
| Authentifizierung | Falsche Zugangsdaten | Zugangsdaten prüfen oder erneut anmelden |
| Netzwerk | Verbindung unterbrochen | Erneut versuchen oder Offline-Modus nutzen |
| Synchronisation | Konflikt mit Serverstand | Konflikt prüfen und lokale Änderung erneut anwenden |

## 8.5 Kosten, Schulden und Salden

Beträge werden mit zwei Nachkommastellen verarbeitet. Die Kostenaufteilung erfolgt gleichmäßig auf alle oder ausgewählte Mitglieder. Cent-Rundungsdifferenzen werden so ausgeglichen, dass die Summe der `ExpenseShare`-Beträge exakt der Ausgabe entspricht.

Für eine Ausgabe werden Kostenanteile und daraus entstehende Schuldbeziehungen gespeichert oder aktualisiert. Der Saldo berücksichtigt nur Schulden mit Status `open`; Schulden mit Status `paid` werden nicht erneut als offen angezeigt. Die Schuldensicht zeigt jedem Benutzer nur seine eigenen Forderungen und Verbindlichkeiten.

## 8.6 Datenschutz und Passwortschutz

Es werden nur Daten gespeichert, die für Benutzerverwaltung, WG-Zugehörigkeit, Einkaufsliste, Ausgaben und Schuldenübersicht erforderlich sind. Passwörter werden nicht von der Anwendung im Klartext gespeichert. Die Kommunikation mit Firebase erfolgt verschlüsselt über HTTPS.

Personenbezogene Daten werden nur so lange aufbewahrt, wie sie für die Nutzung, Nachvollziehbarkeit und Abnahme erforderlich sind. Löschung und Berichtigung müssen bei einer späteren Produktivsetzung nach den geltenden Datenschutzanforderungen, insbesondere der DSGVO, umgesetzt und dokumentiert werden. Eine Anonymisierung ist im MVP nicht vorgesehen.

Ein optionales Attribut `receiptUrl` im Datenmodell wird in der ersten Version nicht durch einen eigenen Beleg-Workflow unterstützt und daher nicht aktiv befüllt oder öffentlich zugänglich gemacht. Sollte die Funktion später umgesetzt werden, müssen Belege in einem privaten, autorisierten Speicher liegen; öffentliche URLs und ungeschützte Direktzugriffe sind ausgeschlossen.
