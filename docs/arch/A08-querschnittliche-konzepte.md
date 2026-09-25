# A08 – Querschnittliche Konzepte

Dieses Kapitel beschreibt Konzepte, die mehrere Bausteine und Anwendungsfälle von WG-ShopSync betreffen. Die fachlichen Anforderungen dazu sind in [N2 – Querschnittskonzepte](../spec/N2-querschnittskonzepte.md) und den verlinkten Anwendungsfunktionen beschrieben.

## 8.1 Authentifizierung und Autorisierung

Firebase Authentication verwaltet Registrierung, Anmeldung, Sitzung und Benutzer-ID. Firestore Security Rules prüfen bei jedem Zugriff, ob der authentifizierte Benutzer Mitglied der adressierten WG ist.

- `admin` kennzeichnet den Ersteller der WG. Im MVP besitzt diese Rolle für Einkaufsliste, Ausgaben und eigene Schulden dieselben fachlichen Datenfunktionen wie `member`.
- `admin` und `member` dürfen den Einladungscode der eigenen WG sehen.
- `member` darf die WG verlassen; `admin` darf sie im MVP nicht verlassen, da keine Rollenübertragung oder Ernennung eines weiteren `admin` vorgesehen ist.
- Nur der jeweilige Schuldner darf eine eigene offene Debt als bezahlt markieren.
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

Cloud Firestore stellt Realtime-Listener und Offline-Persistenz bereit. Bereits synchronisierte Einkaufslistendaten bleiben aus dem lokalen Cache lesbar.

Das Hinzufügen eines neuen Artikels kann offline als ausstehender Firestore-Schreibvorgang vorgemerkt werden. Der Realtime-Listener macht Cache-Zustand und `hasPendingWrites` für die Oberfläche sichtbar. Nach Wiederherstellung der Verbindung synchronisiert Firestore den ausstehenden Schreibvorgang.

Artikel bearbeiten (UC-07) und als gekauft markieren (UC-09) verwenden Firestore-Transaktionen und benötigen eine aktive Verbindung. Ausgaben- und Schuldenänderungen besitzen ebenfalls keinen Offline-Schreibworkflow.

Bei konkurrierenden Online-Änderungen gilt der serverseitige Datenstand. Der Benutzer wird über den Konflikt informiert und kann die aktuellen Serverdaten laden. Eine gewünschte Änderung kann anschließend als neue Bearbeitung durchgeführt werden.
## 8.4 Fehlerbehandlung

Technische Firebase- oder Exception-Details werden nicht ungefiltert in der Benutzeroberfläche angezeigt. Die Services und Screens behandeln insbesondere folgende Fehlerklassen:

| Fehlerklasse | Beispiel | Folgeaktion |
|---|---|---|
| Validierung | Betrag oder Pflichtfeld ungültig | Eingabe korrigieren |
| Authentifizierung | Falsche Zugangsdaten | Zugangsdaten prüfen oder erneut anmelden |
| Netzwerk | Verbindung unterbrochen | Erneut versuchen oder Offline-Modus nutzen |
| Synchronisation | Konflikt mit Serverstand | Aktuellen Serverstand laden, prüfen und bei Bedarf erneut bearbeiten |

## 8.5 Kosten, Schulden und Salden

Beträge werden mit zwei Nachkommastellen verarbeitet. Die Kostenaufteilung erfolgt gleichmäßig auf alle oder ausgewählte Mitglieder. Cent-Rundungsdifferenzen werden so ausgeglichen, dass die Summe der `ExpenseShare`-Beträge exakt der Ausgabe entspricht.

Jede Ausgabe erzeugt für jedes beteiligte Mitglied außer dem Zahler eine eigene, der Ausgabe zugeordnete Schuld (`Debt.expenseId`) in Höhe seines Kostenanteils. Zwischen denselben zwei Mitgliedern können mehrere Schulden aus unterschiedlichen Ausgaben nebeneinander bestehen; sie werden nicht zu einer einzigen Schuld zusammengefasst. Der Saldo berücksichtigt nur Schulden mit Status `open` und wird zur Laufzeit als Summe dieser offenen Schulden gebildet; Schulden mit Status `paid` werden nicht erneut als offen angezeigt, bleiben aber als Historie erhalten. Sobald eine Schuld einer Ausgabe den Status `paid` besitzt, wird sie durch eine spätere Bearbeitung derselben Ausgabe nicht mehr verändert. Die Schuldensicht zeigt jedem Benutzer nur eigene Forderungen und Verbindlichkeiten; Firestore Security Rules erlauben das Lesen einer Schuld nur dem Gläubiger und dem Schuldner.

## 8.6 Datenschutz und Passwortschutz

Es werden nur Daten gespeichert, die für Benutzerverwaltung, WG-Zugehörigkeit, Einkaufsliste, Ausgaben und Schuldenübersicht erforderlich sind. Passwörter werden nicht von der Anwendung im Klartext gespeichert. Die Kommunikation mit Firebase erfolgt verschlüsselt über HTTPS.

Personenbezogene Daten werden nur so lange aufbewahrt, wie sie für die Nutzung, Nachvollziehbarkeit und Abnahme erforderlich sind. Löschung und Berichtigung müssen bei einer späteren Produktivsetzung nach den geltenden Datenschutzanforderungen, insbesondere der DSGVO, umgesetzt und dokumentiert werden. Eine Anonymisierung ist im MVP nicht vorgesehen.

Ein optionales Attribut `receiptUrl` im Datenmodell wird in der ersten Version nicht durch einen eigenen Beleg-Workflow unterstützt und daher nicht aktiv befüllt oder öffentlich zugänglich gemacht. Sollte die Funktion später umgesetzt werden, müssen Belege in einem privaten, autorisierten Speicher liegen; öffentliche URLs und ungeschützte Direktzugriffe sind ausgeschlossen.
