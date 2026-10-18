#!/bin/bash

# Quick Reference Card for Nutrition PWA

echo "
╔════════════════════════════════════════════════════════════════════╗
║           NUTRITION PWA - QUICK REFERENCE GUIDE                    ║
╚════════════════════════════════════════════════════════════════════╝
"

echo "📦 PROJECT STRUCTURE"
echo "==================="
echo "
nutrition-pwa/
├── backend/          → Python FastAPI server
├── frontend/         → React Vite PWA
├── docker-compose.yml → One-command deployment
├── README.md         → Full documentation
├── SETUP.md          → Setup & customization guide
└── ARCHITECTURE.md   → Technical deep-dive
"

echo ""
echo "🚀 QUICK START COMMANDS"
echo "======================="
echo "
# Docker (Recommended)
cd nutrition-pwa
docker-compose up -d

# Manual - Backend
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\\Scripts\\activate
pip install -r requirements.txt
python main.py

# Manual - Frontend
cd frontend
npm install
npm run dev

# Production build
npm run build
npm run preview
"

echo ""
echo "🌐 ACCESS POINTS"
echo "================"
echo "
Local Development:
  Frontend:     http://localhost:5173
  Backend API:  http://localhost:8000
  API Docs:     http://localhost:8000/docs
  ReDoc:        http://localhost:8000/redoc

Docker:
  Frontend:     http://localhost
  Backend API:  http://localhost/api
  API Docs:     http://localhost/api/docs
"

echo ""
echo "📝 COMMON COMMANDS"
echo "=================="
echo "
# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Restart services
docker-compose restart backend
docker-compose restart frontend

# Stop services
docker-compose down

# Remove volumes (reset database)
docker-compose down -v

# Rebuild images
docker-compose build --no-cache

# Backend Python shell
docker exec -it nutrition-api python -c \"from database import *; db = SessionLocal(); ...\"

# Backend database reset
docker exec -it nutrition-api rm /app/data/nutrition_app.db
docker-compose restart backend

# Frontend rebuild
cd frontend
npm install
npm run build
"

echo ""
echo "🔧 CONFIGURATION"
echo "================"
echo "
Daily Macro Goals (edit Dashboard.jsx):
  const MACRO_GOALS = {
    calories: 2000,
    protein: 150,
    carbs: 250,
    fat: 65,
  }

API URL (edit .env):
  Development:  VITE_API_URL=http://localhost:8000/api
  Production:   VITE_API_URL=/api  (served from same origin)

CORS Allowed Origins (edit main.py):
  Development: allow_origins=['*']
  Production:  allow_origins=['https://yourdomain.com']

Database Location:
  Docker:   /app/data/nutrition_app.db (volume: nutrition-db)
  Manual:   ./backend/nutrition_app.db
"

echo ""
echo "📊 API ENDPOINTS QUICK REFERENCE"
echo "================================="
echo "
Foods API:
  GET    /api/foods                    List all foods
  POST   /api/foods                    Create food
  GET    /api/foods/{id}               Get food
  DELETE /api/foods/{id}               Delete food

Barcode API:
  GET    /api/barcode/{barcode}        Lookup Open Food Facts

Logs API:
  POST   /api/logs                     Add meal
  GET    /api/logs/today               Get today's meals
  GET    /api/logs/date/{YYYY-MM-DD}   Get meals by date
  DELETE /api/logs/{id}                Delete meal

Totals API:
  GET    /api/totals/today             Get today's totals
  GET    /api/totals/date/{YYYY-MM-DD} Get totals by date

Health:
  GET    /api/health                   Health check
"

echo ""
echo "🛠️ TROUBLESHOOTING"
echo "=================="
echo "
Issue: Barcode scanner shows black screen
  ✓ Check camera permissions
  ✓ Ensure HTTPS is used (required for camera)
  ✓ For localhost development, use http://localhost:5173

Issue: \"Cannot connect to backend\"
  ✓ Check VITE_API_URL in .env
  ✓ Verify backend is running: curl http://localhost:8000/api/health
  ✓ Check CORS configuration

Issue: Service Worker not caching
  ✓ Clear browser cache (Ctrl+Shift+Delete)
  ✓ Hard refresh (Ctrl+Shift+R / Cmd+Shift+R)
  ✓ Check DevTools > Application > Service Workers

Issue: Database errors
  ✓ Delete and recreate database
  ✓ Ensure write permissions on database directory
  ✓ Check disk space

Issue: Frontend build fails
  ✓ Clear node_modules and package-lock.json
  ✓ Reinstall: npm ci
  ✓ Check Node version: node --version (need v18+)
"

echo ""
echo "🚀 DEPLOYMENT OPTIONS"
echo "====================="
echo "
Option 1: Homelab (recommended)
  - Docker Compose on your server
  - Nginx reverse proxy with SSL
  - Local network access

Option 2: VPS
  - Cloud server (Linode, DigitalOcean, Hetzner)
  - Docker or systemd
  - Let's Encrypt SSL

Option 3: Kubernetes
  - Self-hosted K3s cluster
  - Helm charts
  - Advanced networking

Deployment Steps:
  1. Clone repository
  2. Create .env.production
  3. Build Docker images
  4. Configure Nginx/SSL
  5. Start services
  6. Verify health checks
  7. Setup backups
"

echo ""
echo "🔐 SECURITY CHECKLIST"
echo "===================="
echo "
[ ] Update CORS allowed_origins
[ ] Enable HTTPS/SSL certificates
[ ] Set strong database backups
[ ] Configure firewall rules
[ ] Enable rate limiting (future)
[ ] Keep dependencies updated
[ ] Monitor logs regularly
[ ] Test offline functionality
[ ] Verify camera permissions
[ ] Check error handling
"

echo ""
echo "📚 DOCUMENTATION FILES"
echo "====================="
echo "
README.md           Complete documentation & features
SETUP.md            Setup guide & customization
ARCHITECTURE.md     Technical deep-dive & system design
backend/main.py     API implementation with docstrings
frontend/src/*.jsx  React components with comments
"

echo ""
echo "💾 BACKUP & RECOVERY"
echo "===================="
echo "
Backup Database:
  cp backend/nutrition_app.db backup/nutrition_app.db.\$(date +%Y%m%d_%H%M%S)

Export Data:
  sqlite3 backend/nutrition_app.db \".mode json\" \".output data.json\" \"SELECT * FROM daily_logs;\"

Restore Database:
  cp backup/nutrition_app.db.20240516_120000 backend/nutrition_app.db

Backup in Docker:
  docker exec nutrition-api cp /app/data/nutrition_app.db /app/backup/
"

echo ""
echo "✨ USEFUL KEYBOARD SHORTCUTS"
echo "============================"
echo "
Frontend Development:
  Ctrl+Shift+I / Cmd+Option+I  → DevTools
  Ctrl+K                       → Search bar
  F12                          → DevTools toggle

Backend (with FastAPI docs):
  http://localhost:8000/docs   → Swagger UI
  http://localhost:8000/redoc  → ReDoc documentation

Browser PWA:
  Cmd+Shift+M / Ctrl+Shift+M   → Device toolbar
  Cmd+Option+U / Ctrl+Shift+U  → View source
"

echo ""
echo "🎯 NEXT STEPS"
echo "=============="
echo "
1. Start the project:
   cd nutrition-pwa && docker-compose up -d

2. Open frontend:
   http://localhost (Docker) or http://localhost:5173 (dev)

3. Check API docs:
   http://localhost:8000/docs (or /api/docs via Docker)

4. Add some foods and test:
   - Scan a barcode or add food manually
   - Log some meals
   - Check daily totals

5. Test offline:
   - Disconnect network
   - Verify cached data still loads

6. Install as PWA:
   - On mobile: More options → Install app
   - On desktop: More options → Install (Chrome/Edge only)

7. Deploy to production:
   - See docker-compose.yml and nginx.conf
   - Configure your domain
   - Setup SSL certificates
   - Deploy!
"

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "Happy macro tracking! 💪 Need help? Check README.md or SETUP.md"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
