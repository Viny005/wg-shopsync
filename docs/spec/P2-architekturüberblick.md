# P2 – Architekturüberblick

Dieser Baustein beschreibt die Einbettung von WG-ShopSync in seine Systemumgebung.

Ziel dieses Dokuments ist die Beschreibung der beteiligten Systeme sowie der Kommunikationsbeziehungen zwischen diesen Systemen.

Detaillierte Architekturentscheidungen, interne Komponenten, APIs oder Datenbankstrukturen sind nicht Bestandteil dieses Dokuments und werden in späteren Architekturartefakten dokumentiert.

---

## P2.1 Systemkontext

WG-ShopSync besteht aus einer plattformübergreifenden Client-Anwendung, einem Backend-System und einer zentralen Cloud-Datenhaltung.

Benutzer greifen über Smartphone, Tablet oder Webbrowser auf die Anwendung zu.

Das Backend übernimmt die Verwaltung von Benutzerkonten, die Verarbeitung von Anfragen sowie die Kommunikation mit der zentralen Datenhaltung.

Die zentrale Datenhaltung speichert alle Informationen zu Benutzern, Wohngemeinschaften, Einkaufslisten und Ausgaben.


---

## P2.2 Nachbarsysteme

Vollständige Übersicht aller Systeme, mit denen WG-ShopSync kommuniziert.

| ID | System | Rolle | Richtung | Kopplung |
|----|---------|---------|-----------|-----------|
| NB-01 | Benutzer | Verwendet die Anwendung zur Organisation von Einkäufen und Ausgaben | Bidirektional | Direkt |
| NB-02 | WG-ShopSync Client | Benutzeroberfläche auf Smartphone, Tablet oder Webbrowser | Bidirektional | Direkt |
| NB-03 | Backend-System | Verarbeitung von Anfragen, Authentifizierung und Geschäftslogik | Bidirektional | Direkt |
| NB-04 | Cloud-Datenhaltung | Speicherung und Synchronisation aller Daten | Bidirektional | Direkt |

---

## Hinweise

- Die konkrete Technologie der Cloud-Datenhaltung wird im Architekturteil festgelegt.
- Die genaue API-Struktur wird im Architekturentwurf beschrieben.
- Schnittstellen und Kommunikationsdetails werden im Baustein S1 behandelt.
- Das System ist als Greenfield-Projekt konzipiert und besitzt keine Altsysteme.