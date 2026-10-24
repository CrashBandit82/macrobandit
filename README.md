<p align="right"><b>English</b> · <a href="README.de.md">Deutsch</a></p>

<p align="center"><img src="frontend/public/logo.png" width="96" alt="MacroBandit"></p>

<h1 align="center">MacroBandit</h1>

<p align="center">
  Free, ad-free macro &amp; calorie tracker for athletes – installable as a PWA.<br>
  Live at <a href="https://macrobandit.at">macrobandit.at</a>
</p>

---

## Features

- **Barcode scanner** – scan products with the phone camera; nutrition data comes from Open Food Facts
- **Gram-precise logging** – every entry in grams, calories and macros are calculated instantly
- **Own foods & meal templates** – save favourites and whole meals, apply them with one tap
- **TDEE calculator** – daily energy need (Mifflin-St Jeor) and personal macro goals
- **Weekly & monthly reports** – totals, averages and goal achievement
- **Weight tracker** – log body weight and follow the trend
- **Reminders** – optional web push notification if nothing was logged yet
- **Accounts** – registration with e-mail verification, password reset, avatar, data export, account deletion
- **Admin panel** – user management, broadcast e-mail, inactivity reminders, statistics
- **PWA** – installable on Android/iOS, works offline-tolerant, update banner for new versions
- **Android app** – native Flutter app in [`app/`](app/) (no Google services), same account as the web app
- **German & English**, light & dark theme

## Tech stack

| Part | Technology |
|---|---|
| Frontend | React, Vite, Tailwind CSS, i18next, Service Worker |
| Backend | Python, FastAPI, SQLAlchemy |
| Database | PostgreSQL |
| Web server | nginx (serves the built frontend, proxies `/api` to the backend) |

## Project layout

```
backend/            FastAPI app (main.py, routers/, models.py)
  send_reminders.py push reminders (run every minute via cron)
  import_bls.py     optional import of the German food database (BLS)
frontend/           React app (src/, public/, vite.config.js)
nginx.conf          example nginx site
deploy.sh           build frontend + restart backend
```

## Setup

### Requirements
- Python 3.11+, Node.js 20+, PostgreSQL 15+, nginx

### Backend

```bash
cd backend
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 127.0.0.1 --port 8000
```

The tables are created automatically on first start. Configuration is read from environment variables:

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | e.g. `postgresql://macrobandit:<password>@localhost/macrobandit` |
| `SECRET_KEY`, `REFRESH_SECRET_KEY` | JWT signing keys – long random values |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` | e-mail for verification / password reset (optional) |
| `NOTIFY_EMAIL` | receives new-registration and feedback notifications (optional) |
| `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_CLAIMS` | web push reminders (optional) |

Run the backend as a systemd service in production.

### Frontend

```bash
cd frontend
npm ci
npm run dev      # development: http://localhost:5173
npm run build    # production build in frontend/dist
```

Point nginx at `frontend/dist` and proxy `/api/` to `127.0.0.1:8000` (see `nginx.conf`). Put TLS in front (Let's Encrypt or your reverse proxy).

### Deploying a new version

1. Raise `version` in `frontend/package.json` (semantic versioning).
2. Run `deploy.sh` – it stamps the service worker, builds the frontend and restarts the backend.
3. Users get an update banner on their next visit.

## Backups

Back up the PostgreSQL database regularly, e.g. daily:

```bash
pg_dump macrobandit > backup/db_$(date +%Y%m%d).sql
```

## License

Copyright (C) 2026 CrashBandit82

MacroBandit is free software: you can redistribute it and/or modify it under the terms of the **GNU Affero General Public License v3.0** as published by the Free Software Foundation. If you run a modified version as a network service, you must make its source code available to its users. See [LICENSE](LICENSE) for the full text.
