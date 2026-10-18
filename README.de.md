<p align="right"><a href="README.md">English</a> · <b>Deutsch</b></p>

<p align="center"><img src="frontend/public/logo.png" width="96" alt="MacroBandit"></p>

<h1 align="center">MacroBandit</h1>

<p align="center">
  Kostenloser, werbefreier Makro- &amp; Kalorien-Tracker für Sportler – als PWA installierbar.<br>
  Online unter <a href="https://macrobandit.at">macrobandit.at</a>
</p>

---

## Funktionen

- **Barcode-Scanner** – Produkte mit der Handykamera scannen, Nährwerte kommen von Open Food Facts
- **Grammgenau erfassen** – jeder Eintrag in Gramm, Kalorien und Makros werden sofort berechnet
- **Eigene Lebensmittel & Mahlzeiten-Vorlagen** – Favoriten und ganze Mahlzeiten speichern, mit einem Tippen eintragen
- **TDEE-Rechner** – täglicher Energiebedarf (Mifflin-St Jeor) und persönliche Makro-Ziele
- **Wochen- & Monatsauswertung** – Summen, Durchschnitte und Zielerreichung
- **Gewichtstracker** – Körpergewicht eintragen und Verlauf verfolgen
- **Erinnerungen** – optionale Push-Benachrichtigung, wenn noch nichts eingetragen wurde
- **Konto** – Registrierung mit E-Mail-Bestätigung, Passwort zurücksetzen, Profilbild, Datenexport, Konto löschen
- **Admin-Bereich** – Nutzerverwaltung, Rundmail, Inaktivitäts-Erinnerungen, Statistiken
- **PWA** – auf Android/iOS installierbar, offline-tolerant, Update-Hinweis bei neuen Versionen
- **Deutsch & Englisch**, helles & dunkles Design

## Technik

| Teil | Technologie |
|---|---|
| Frontend | React, Vite, Tailwind CSS, i18next, Service Worker |
| Backend | Python, FastAPI, SQLAlchemy |
| Datenbank | PostgreSQL |
| Webserver | nginx (liefert das gebaute Frontend aus, leitet `/api` ans Backend weiter) |

## Aufbau

```
backend/            FastAPI-App (main.py, routers/, models.py)
  send_reminders.py Push-Erinnerungen (läuft minütlich per Cron)
  import_bls.py     optionaler Import des Bundeslebensmittelschlüssels (BLS)
frontend/           React-App (src/, public/, vite.config.js)
nginx.conf          Beispiel-Konfiguration für nginx
deploy.sh           Frontend bauen + Backend neu starten
```

## Einrichtung

### Voraussetzungen
- Python 3.11+, Node.js 20+, PostgreSQL 15+, nginx

### Backend

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 127.0.0.1 --port 8000
```

Die Tabellen werden beim ersten Start automatisch angelegt. Die Konfiguration kommt aus Umgebungsvariablen:

| Variable | Zweck |
|---|---|
| `DATABASE_URL` | z. B. `postgresql://macrobandit:<passwort>@localhost/macrobandit` |
| `SECRET_KEY`, `REFRESH_SECRET_KEY` | Schlüssel für die JWT-Anmeldung – lange Zufallswerte |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` | E-Mail für Bestätigung / Passwort zurücksetzen (optional) |
| `NOTIFY_EMAIL` | bekommt Meldungen zu neuen Registrierungen und Feedback (optional) |
| `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_CLAIMS` | Push-Erinnerungen (optional) |

Im Betrieb das Backend als systemd-Dienst laufen lassen.

### Frontend

```bash
cd frontend
npm ci
npm run dev      # Entwicklung: http://localhost:5173
npm run build    # Produktions-Build in frontend/dist
```

nginx auf `frontend/dist` zeigen lassen und `/api/` an `127.0.0.1:8000` weiterleiten (siehe `nginx.conf`). Davor TLS (Let's Encrypt oder dein Reverse Proxy).

### Neue Version ausrollen

1. `version` in `frontend/package.json` erhöhen (Semantic Versioning).
2. `deploy.sh` ausführen – stempelt den Service Worker, baut das Frontend und startet das Backend neu.
3. Beim nächsten Besuch sehen die Nutzer einen Update-Hinweis.

## Sicherung

Die PostgreSQL-Datenbank regelmäßig sichern, z. B. täglich:

```bash
pg_dump macrobandit > backup/db_$(date +%Y%m%d).sql
```

## Lizenz

Copyright (C) 2026 CrashBandit82

MacroBandit ist freie Software: Du darfst sie unter den Bedingungen der **GNU Affero General Public License v3.0** der Free Software Foundation weitergeben und verändern. Wer eine veränderte Version als Online-Dienst betreibt, muss den Nutzern den Quellcode zur Verfügung stellen. Der vollständige Text steht in [LICENSE](LICENSE) (rechtlich gilt die englische Fassung).
