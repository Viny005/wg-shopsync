# N1 – Nichtfunktionale Anforderungen

Nichtfunktionale Anforderungen beschreiben die Qualitätsmerkmale von WG-ShopSync. Im Gegensatz zu den funktionalen Anforderungen legen sie nicht fest, welche Funktionen das System bereitstellt, sondern welche Qualitätsziele dabei eingehalten werden müssen.

---

# N1.1 Performance-Anforderungen

## N1.1-01: Echtzeit-Synchronisation

Änderungen an der gemeinsamen Einkaufsliste müssen für alle Mitglieder einer WG nahezu in Echtzeit sichtbar sein.

### Fit Criterion

Änderungen an der Einkaufsliste werden innerhalb von 2 Sekunden auf den Geräten aller verbundenen WG-Mitglieder angezeigt.

---

## N1.1-02: Schnelle Anmeldung

Die Anmeldung eines Benutzers soll ohne spürbare Verzögerung erfolgen.

### Fit Criterion

Der Anmeldevorgang ist innerhalb von 3 Sekunden abgeschlossen.

---

## N1.1-03: Schnelles Speichern

Das Speichern neuer Artikel oder Ausgaben soll ohne wahrnehmbare Verzögerung erfolgen.

### Fit Criterion

Ein neuer Artikel oder eine neue Ausgabe wird innerhalb von 1 Sekunde gespeichert.

---

# N1.2 Sicherheitsanforderungen

## N1.2-01: Benutzerauthentifizierung

Nur registrierte Benutzer dürfen auf die Anwendung zugreifen.

### Fit Criterion

Nicht authentifizierte Benutzer erhalten keinen Zugriff auf die Anwendung.

---

## N1.2-02: Zugriffsschutz

Benutzer dürfen ausschließlich auf die Daten ihrer eigenen Wohngemeinschaft zugreifen.

### Fit Criterion

Ein Benutzer kann weder Einkaufslisten noch Ausgaben anderer Wohngemeinschaften anzeigen oder bearbeiten.

---

## N1.2-03: Passwortschutz

Benutzerpasswörter dürfen nicht im Klartext gespeichert werden.

### Fit Criterion

Alle Passwörter werden ausschließlich als kryptografische Hashwerte gespeichert.

---

## N1.2-04: Sichere Kommunikation

Die Kommunikation zwischen der mobilen Anwendung und dem Server muss verschlüsselt erfolgen.

### Fit Criterion

Sämtliche Datenübertragungen erfolgen ausschließlich über HTTPS.

---

# N1.3 Verfügbarkeitsanforderungen

## N1.3-01: Plattformunterstützung

Die Anwendung muss sowohl auf Android- als auch auf iOS-Geräten lauffähig sein.

### Fit Criterion

Alle Kernfunktionen stehen auf beiden Betriebssystemen zur Verfügung.

---

## N1.3-02: Hohe Verfügbarkeit

Die Anwendung soll den Benutzern jederzeit zur Verfügung stehen.

### Fit Criterion

Die Anwendung erreicht eine monatliche Verfügbarkeit von mindestens 99 %.

---

## N1.3-03: Offline-Verfügbarkeit

Die zuletzt synchronisierten Einkaufslisten sollen auch ohne aktive Internetverbindung verfügbar sein.

### Fit Criterion

Einkaufslisten können ohne Internetverbindung angezeigt und bearbeitet werden, sofern zuvor eine Synchronisation erfolgt ist. Lokale Änderungen werden nach Wiederherstellung der Verbindung automatisch synchronisiert.

---

# N1.4 Usability-Anforderungen

## N1.4-01: Einfache Bedienbarkeit

Die wichtigsten Funktionen sollen mit möglichst wenigen Benutzerschritten erreichbar sein.

### Fit Criterion

Ein neuer Artikel kann mit höchstens drei Benutzeraktionen zur Einkaufsliste hinzugefügt werden.

---

## N1.4-02: Intuitive Benutzeroberfläche

Die Benutzeroberfläche soll ohne Schulung verständlich und einfach bedienbar sein.

### Fit Criterion

Ein neuer Benutzer kann eine WG erstellen, einen Artikel hinzufügen und eine Ausgabe erfassen, ohne eine Anleitung zu lesen.

---

## N1.4-03: Verständliche Fehlermeldungen

Fehlermeldungen sollen eindeutig formuliert sein und dem Benutzer helfen, das Problem zu beheben.

### Fit Criterion

Jede Fehlermeldung beschreibt den Fehler verständlich und enthält einen Hinweis zur Behebung, sofern dies möglich ist.