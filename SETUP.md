# Project Structure & Quick Setup

## 📁 Complete Project Layout

```
nutrition-pwa/
├── backend/
│   ├── database.py          # SQLAlchemy ORM & database models
│   ├── main.py              # FastAPI application & endpoints
│   ├── requirements.txt      # Python dependencies
│   ├── .gitignore
│   └── nutrition_app.db     # SQLite database (auto-generated)
│
├── frontend/
│   ├── public/
│   │   ├── manifest.json    # PWA manifest
│   │   ├── sw.js            # Service Worker
│   │   └── [icons]          # App icons (add your own)
│   │
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard.jsx        # Main dashboard component
│   │   │   ├── BarcodeScanner.jsx   # Barcode scanner modal
│   │   │   └── MacroProgress.jsx    # Progress bar component
│   │   │
│   │   ├── App.jsx          # Root component
│   │   ├── main.jsx         # React entry point
│   │   ├── api.js           # API client (Axios)
│   │   └── index.css        # Global styles + Tailwind
│   │
│   ├── index.html           # HTML template
│   ├── package.json         # NPM dependencies
│   ├── vite.config.js       # Vite build config
│   ├── tailwind.config.js   # Tailwind CSS config
│   ├── postcss.config.js    # PostCSS config
│   ├── .env                 # Development environment variables
│   ├── .env.production      # Production environment variables
│   ├── .eslintrc.json       # ESLint configuration
│   ├── .gitignore
│   └── node_modules/        # Installed packages (auto-generated)
│
├── Dockerfile.backend       # Backend Docker image
├── Dockerfile.frontend      # Frontend Docker image
├── docker-compose.yml       # Docker Compose orchestration
├── nginx.conf              # Nginx reverse proxy config
├── start.sh                # Development startup script
├── README.md               # Full documentation
└── .gitignore
```

## 🚀 Quick Start (5 minutes)

### Option A: Docker (Recommended)

```bash
# Clone/navigate to project
cd nutrition-pwa

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access
# Frontend: http://localhost
# API Docs: http://localhost/api/docs
```

### Option B: Manual Setup

**Terminal 1 - Backend:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
# Backend runs on http://localhost:8000
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm install
npm run dev
# Frontend runs on http://localhost:5173
```

## 🔑 Key Files Explained

### Backend

**`database.py`** - Database Setup
- `FoodItem` table: Stores custom food definitions (name, brand, macros per 100g)
- `DailyLog` table: Stores meal entries (food_id, amount, calculated macros, timestamp)
- `SessionLocal`: Database connection factory
- `seed_default_foods()`: Pre-populates with common foods

**`main.py`** - API Endpoints
- **Foods API**: CRUD operations for custom foods
- **Barcode API**: Integrates Open Food Facts for product lookup
- **Logs API**: Add/delete/retrieve meal entries
- **Totals API**: Calculate daily macro summaries
- **Error Handling**: Comprehensive exception handling with proper HTTP status codes

### Frontend

**`Dashboard.jsx`** - Main Component
- Displays daily totals (calories, protein, carbs, fat)
- Shows progress bars for each macro
- Lists today's meals with ability to delete
- Modal for adding meals (barcode scan or manual selection)
- Responsive design optimized for mobile

**`BarcodeScanner.jsx`** - Camera Integration
- Uses `html5-qrcode` library
- Full-screen camera interface
- Integrates with barcode lookup API
- Fallback error handling

**`MacroProgress.jsx`** - Reusable Progress Display
- Shows current vs. goal macronutrient
- Visual progress bar with percentage
- Color-coded (protein=blue, carbs=orange, fat=purple)

**`api.js`** - API Client
- Axios instance with error interceptors
- Organized endpoint groups (foodApi, logApi, barcodeApi, etc.)
- Configurable base URL via `.env`

**`sw.js`** - Service Worker
- Offline support with caching strategies
- Network-first for API calls (fallback to cache)
- Cache-first for static assets
- Handles Open Food Facts API caching

## ⚙️ Customization Guide

### Change Daily Macro Goals

In `frontend/src/components/Dashboard.jsx`:
```javascript
const MACRO_GOALS = {
  calories: 2500,  // Change to your goal
  protein: 200,
  carbs: 300,
  fat: 80,
}
```

### Add More Default Foods

In `backend/database.py`, add to the `default_foods` list:
```python
FoodItem(
    name="Your Food",
    brand="Brand Name",
    calories_per_100g=100,
    protein_per_100g=10,
    carbs_per_100g=15,
    fat_per_100g=5
),
```

### Configure CORS for Production

In `backend/main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com", "https://app.yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Update API Base URL

For production, edit `frontend/.env.production`:
```env
VITE_API_URL=https://api.yourdomain.com/api
```

## 📊 API Usage Examples

### Add a Meal
```bash
curl -X POST http://localhost:8000/api/logs \
  -H "Content-Type: application/json" \
  -d '{
    "food_item_id": 1,
    "amount_grams": 150
  }'
```

### Get Today's Totals
```bash
curl http://localhost:8000/api/totals/today
```

Response:
```json
{
  "total_calories": 2145.5,
  "total_protein": 155.3,
  "total_carbs": 242.1,
  "total_fat": 68.2,
  "entries_count": 6,
  "date": "2024-05-16"
}
```

### Lookup Barcode
```bash
curl http://localhost:8000/api/barcode/5901234123457
```

## 🔐 Security Checklist

- [ ] Update CORS `allow_origins` for your domain
- [ ] Use HTTPS in production
- [ ] Enable rate limiting on API endpoints
- [ ] Keep database file backed up
- [ ] Validate and sanitize all inputs (already done with Pydantic)
- [ ] Use environment variables for sensitive data
- [ ] Enable logging for debugging

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Barcode scanner shows black screen | Check camera permissions; use HTTPS |
| API returns 403 CORS error | Check CORS configuration in `main.py` |
| "Product not found" on barcode scan | Product not in Open Food Facts; add manually |
| Frontend can't connect to backend | Check `VITE_API_URL` in `.env` |
| Service worker not caching | Clear browser cache and hard refresh |
| Database locked error | Close other database connections; restart backend |

## 📱 Testing on Mobile

1. **Local Network**: Replace `localhost` with your computer's IP (e.g., `192.168.1.100`)
2. **ngrok Tunnel**: `ngrok http 8000` for remote access
3. **Mobile Chrome**: Enable "Add to Home Screen" to test PWA installation

## 🚀 Deployment

### Using Systemd (Linux/Homelab)
```bash
# Backend service
sudo cp services/nutrition-backend.service /etc/systemd/system/
sudo systemctl enable nutrition-backend
sudo systemctl start nutrition-backend

# Frontend (via Nginx)
sudo cp frontend/dist/* /var/www/nutrition-pwa/
# Configure Nginx virtual host
```

### Using Docker Swarm
```bash
docker stack deploy -c docker-compose.yml nutrition-pwa
```

### Using Kubernetes
See deployment manifests in `k8s/` folder (create as needed)

## 📈 Performance Optimization

- ✅ Tailwind CSS with tree-shaking
- ✅ Code splitting in Vite build
- ✅ Gzip compression in Nginx
- ✅ Service Worker caching strategies
- ✅ Lazy loading for components
- ✅ Optimized database queries

## 🔄 Backup & Recovery

```bash
# Backup database
cp backend/nutrition_app.db backups/nutrition_app.db.$(date +%Y%m%d_%H%M%S)

# Export data to JSON
python backend/export_data.py > backup.json

# Restore from backup
cp backups/nutrition_app.db.20240516_120000 backend/nutrition_app.db
```

## 📞 Getting Help

- **FastAPI Docs**: http://localhost:8000/docs (interactive API explorer)
- **React DevTools**: Install browser extension
- **Network Tab**: Check browser DevTools for API calls
- **Logs**: `docker-compose logs backend` or `docker-compose logs frontend`

## ✨ Next Steps

1. Run the project
2. Add your favorite foods
3. Log some meals
4. Test barcode scanner
5. Install as PWA (iOS/Android)
6. Deploy to your homelab
7. Share feedback!

Enjoy tracking your macros! 💪
