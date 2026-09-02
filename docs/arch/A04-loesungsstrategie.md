# A04 – Lösungsstrategie

## 1. Grundprinzip

WG-ShopSync wird als responsive Webanwendung umgesetzt. Die Weboberfläche und die gemeinsame Geschäftslogik laufen im Browser; Firebase stellt Authentifizierung, Datenhaltung und Synchronisation bereit.

## 2. Architekturstrategie

Die Anwendung wird in folgende Verantwortungsbereiche gegliedert:

1. **Präsentation:** Screens, Formulare, Navigation und Zustandsdarstellung.
2. **Anwendungslogik:** Validierung, Kostenaufteilung, Saldo- und Statusberechnung.
3. **Datenzugriff:** Firebase Authentication, Firestore-Abfragen, Streams und Schreiboperationen.
4. **Lokale Synchronisation:** Nutzung der Firestore-Offline-Persistenz und Behandlung von Konflikten.

## 3. Fachliche Strategien

- Neue Artikel erhalten den Status `open`; gekaufte Artikel den Status `bought`.
- Schulden verwenden die Statuswerte `open` und `paid`.
- Kosten werden in Cent beziehungsweise mit fester Dezimalpräzision verarbeitet, damit Rundungsfehler kontrolliert werden.
- Die Summe der ExpenseShares muss exakt dem Ausgabebetrag entsprechen; die Verteilung erfolgt gleichmäßig auf alle oder ausgewählte Mitglieder.
- Bereits bezahlte Schulden werden bei der Berechnung offener Salden nicht berücksichtigt.
- Bei konkurrierenden Änderungen gewinnt der Serverstand. Der Konflikt wird angezeigt und die lokale Änderung kann nach Prüfung erneut angewendet werden.

## 4. Sicherheitsstrategie

Authentifizierung erfolgt über Firebase Authentication. Jede Firestore-Operation prüft die Zugehörigkeit des Benutzers zur betreffenden WG. Rollen werden in `Membership.role` gespeichert. Der letzte `admin` darf eine WG nicht verlassen, solange kein anderer `admin` vorhanden ist.
