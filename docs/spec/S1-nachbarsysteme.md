# S1 – Nachbarsysteme

## Übersicht
Auflistung aller externen Systeme, mit denen WG-ShopSync Daten austauscht.

| ID | Nachbarsystem | Zweck | Richtung |
|----|---------------|-------|----------|
| NB-01 | E-Mail-Dienst (z.B. SendGrid) | Versand von Bestätigungs-/Reset-E-Mails | ausgehend |
| NB-02 | Push-Notification-Dienst (z.B. Firebase Cloud Messaging) | Benachrichtigungen bei neuen Artikeln/Zuweisungen | ausgehend |
| NB-03 | Cloud-Datenbank | Persistenz & Synchronisation | bidirektional |
| NB-04 | Google/Apple SSO | Alternative Authentifizierung | bidirektional |

## Details je Nachbarsystem
### NB-01 – E-Mail-Dienst
- Genutzt in: UC-01 (Registrierung), UC-02 (Passwort-Reset)
- Schnittstelle: REST-API
...
