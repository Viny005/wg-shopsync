# P2 – Architekturüberblick

Dieser Baustein beschreibt die Einbettung von WG-ShopSync in seine Systemumgebung.

Ziel dieses Dokuments ist die Beschreibung der beteiligten Systeme sowie der Kommunikationsbeziehungen zwischen diesen Systemen.

Detaillierte Architekturentscheidungen, interne Komponenten, APIs oder Datenbankstrukturen sind nicht Bestandteil dieses Dokuments und werden in späteren Architekturartefakten dokumentiert.

---

## P2.1 Systemkontext

Die Architektur von WG-ShopSync folgt einem klassischen, mandantenfähigen Client-Server-Modell. Das System gliedert sich in drei wesentliche Schichten, um eine klare Trennung von Benutzeroberfläche, Geschäftslogik und Datenhaltung zu gewährleisten.

Architekturdiagramm
Das folgende Diagramm zeigt den Systemkontext und die architektonischen Hauptkomponenten im C4-Modell-Stil:

<p align="center">
  <img src="./images/wg-shopsync-Architektur.png" alt="wg-shopsync-Architektur" width="800">
</p>


### Beschreibung der Architekturschichten

- Client-Schicht (Mobile App):
Die plattformübergreifende Anwendung läuft auf den mobilen Endgeräten der Benutzer (Android). Sie stellt die Benutzeroberfläche bereit, verarbeitet direkte Benutzereingaben und hält relevante Daten für den Offline-Modus lokal vor (gemäß N1.3-03 und N2.3).

- Server-Schicht (Backend & Geschäftslogik):
Der zentrale App-Server (API) verarbeitet die Anfragen der Clients, setzt die Autorisierungs- und Zugriffsregeln basierend auf den WG-Mitgliedschaften durch und koordiniert den Datenabgleich (Synchronisation) zwischen den Geräten (N2.4).

- Datenhaltung:
Die persistente Speicherung aller fachlichen Entitäten erfolgt in einer zentralen Cloud-Datenbank, die als autoritative Master-Instanz für die Konsistenz der Daten dient.
---

## P2.2 Nachbarsysteme

Vollständige Liste der Systeme, mit denen WG-ShopSync kommuniziert. Detaillierte Schnittstellenverträge (Endpunkte, Nutzdaten, Fehlersemantik) gehören in S1 – Schnittstellen benachbarter Systeme; diese Tabelle stellt das Inventar dar.

|Ausweis|	System|	Rolle|	Richtung|	Kupplung|	Frequenz|	Eigentümer|
|-------|-------|------|----------|---------|---------|-----------|
|NB-01	|Mobile App-Client (Android) |	Einziger menschlicher Akteur; Auslöser für Einkaufslisten-, Ausgaben- und WG-Aktionen|eingehende |	enge (synchrone Anfrage) |	pro Benutzeraktion|	WG-Mitglied	|	
|NB-02	|Authentifizierungs-Dienst| 	Verifizierung von E-Mail-Adressen und Passwort-Hashes, Sitzungsverwaltung |	bidirektional (Anfrage: Credentials; Antwort: Token / Status) |	enge (synchron; blockiert bei Antwort)| pro Login / Registrierung |  Drittanbieter / Cloud-Dienst|		
|NB-03 |	Cloud-Datenbank |	Persistente Speicherung aller Entitäten gemäß D1 und D2 (User, WG, ShoppingItem, Expense etc.) |	bidirektional (Lese- und Schreiboperationen) |	enge (synchron / persistenter Stream)	| permanent / pro Datenänderung |	Cloud-Provider (Drittanbieter)|		
|NB-04 |	Push-Dienst (FCM / APNs) |	Versand von Echtzeit-Benachrichtigungen bei Listen- und Ausgabenänderungen an mobile Endgeräte |	ausgehend (App-Server sendet Push an Benachrichtigungs-Gateway) |	lose (asynchron) |	pro Listen- oder Ausgaben-Update |	Google / Apple (Drittanbieter)|		
								

---

## Hinweise

- Die konkrete Technologie der Cloud-Datenhaltung wird im Architekturteil festgelegt.
- Die genaue API-Struktur wird im Architekturentwurf beschrieben.
- Schnittstellen und Kommunikationsdetails werden im Baustein S1 behandelt.
- Das System ist als Greenfield-Projekt konzipiert und besitzt keine Altsysteme.
