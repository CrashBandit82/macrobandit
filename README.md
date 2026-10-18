# Nutrition PWA - Installation & Setup Guide

A mobile-first Progressive Web App for tracking daily calories and macronutrients. Self-hosted with FastAPI backend and React frontend.

## 🚀 Quick Start

### Prerequisites
- **Docker & Docker Compose** (recommended)
- OR: **Python 3.11+**, **Node.js 18+**, **npm**

### Using Docker (Recommended)

```bash
cd nutrition-pwa
docker-compose up -d
```

Access the app at `http://localhost`

### Manual Setup

#### Backend Setup

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
uvicorn main:app --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`
- API Docs: `http://localhost:8000/docs`
- OpenAPI: `http://localhost:8000/openapi.json`

#### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Development server
npm run dev
# Access at http://localhost:5173

# Build for production
npm run build
npm run preview
```

## 📱 Features

### 1. **Barcode Scanning**
- Scan product barcodes using your phone camera
- Fetches nutritional data from Open Food Facts API
- Automatic macronutrient calculation

### 2. **Local Favorites**
- Add and manage custom food items
- Pre-populated with common foods (chicken, eggs, oats, etc.)
- Quick selection without API calls

### 3. **Daily Tracking**
- Log meals with portion sizes in grams
- Real-time calorie and macro calculations
- Daily totals with visual progress bars

### 4. **Offline Support**
- Service Worker enables offline functionality
- Cached API responses for offline access
- Syncs when reconnected

### 5. **PWA Installation**
- Install as standalone app on mobile
- Home screen icon
- Offline-first design
- Camera permissions for barcode scanner

## 🔧 Configuration

### Backend Configuration

Edit `backend/main.py` to adjust:
- **CORS allowed origins** (Line ~40)
- **Database location** (Line ~10 in `database.py`)
- **Default food items** (Line ~100 in `database.py`)

```python
# Modify CORS for production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],  # Change this
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Frontend Configuration

Edit `.env` and `.env.production`:

```env
# Development
VITE_API_URL=http://localhost:8000/api

# Production
VITE_API_URL=/api
```

Modify macro goals in `src/components/Dashboard.jsx`:

```javascript
const MACRO_GOALS = {
  calories: 2000,  // Your daily calorie goal
  protein: 150,    // Grams of protein per day
  carbs: 250,      // Grams of carbs per day
  fat: 65,         // Grams of fat per day
}
```

## 📊 API Endpoints

### Foods
- `GET /api/foods` - List all custom foods
- `POST /api/foods` - Create custom food
- `GET /api/foods/{id}` - Get specific food
- `DELETE /api/foods/{id}` - Delete food

### Barcode
- `GET /api/barcode/{barcode}` - Lookup Open Food Facts

### Daily Logs
- `POST /api/logs` - Add meal entry
- `GET /api/logs/today` - Get today's meals
- `GET /api/logs/date/{date}` - Get meals by date (YYYY-MM-DD)
- `DELETE /api/logs/{id}` - Delete meal entry

### Totals
- `GET /api/totals/today` - Get today's totals
- `GET /api/totals/date/{date}` - Get totals by date

### Health
- `GET /api/health` - Health check

## 🗄️ Database Schema

### `food_items` Table
```sql
CREATE TABLE food_items (
    id INTEGER PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(255),
    calories_per_100g FLOAT,
    protein_per_100g FLOAT,
    carbs_per_100g FLOAT,
    fat_per_100g FLOAT,
    created_at DATETIME
)
```

### `daily_logs` Table
```sql
CREATE TABLE daily_logs (
    id INTEGER PRIMARY KEY,
    food_item_id INTEGER NOT NULL,
    food_name VARCHAR(255),
    amount_grams FLOAT,
    calories FLOAT,
    protein FLOAT,
    carbs FLOAT,
    fat FLOAT,
    created_at DATETIME,
    date DATE
)
```

## 🔒 Security Considerations

1. **CORS**: Update `allow_origins` for your domain
2. **HTTPS**: Use a reverse proxy (Nginx, Traefik) with SSL certificates
3. **API Rate Limiting**: Add rate limiting middleware for production
4. **Input Validation**: All inputs are validated via Pydantic
5. **Database**: Keep database file secure and backed up

## 📦 Production Deployment

### Using Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl http2;
    server_name nutrition.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/nutrition.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nutrition.yourdomain.com/privkey.pem;
    
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
    }
}
```

### Docker Compose for Production

```bash
# Build images
docker-compose build

# Run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## 🐛 Troubleshooting

### Barcode Scanner Not Working
- Check browser camera permissions
- Ensure HTTPS is used (required for camera access)
- Use `http://localhost` for development

### API Connection Issues
- Verify backend is running: `curl http://localhost:8000/api/health`
- Check `VITE_API_URL` in `.env`
- Check CORS configuration in `backend/main.py`

### Database Issues
- Delete `nutrition_app.db` to reset
- Check file permissions on database directory
- Verify SQLite installation: `python -c "import sqlite3; print(sqlite3.sqlite_version)"`

### Service Worker Problems
- Clear browser cache
- Check browser console for SW registration errors
- Hard refresh (Cmd+Shift+R / Ctrl+Shift+R)

## 📝 Adding Custom Foods

### Via API
```bash
curl -X POST http://localhost:8000/api/foods \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Custom Food",
    "brand": "My Brand",
    "calories_per_100g": 250,
    "protein_per_100g": 20,
    "carbs_per_100g": 30,
    "fat_per_100g": 5
  }'
```

### Via UI
1. Click "Add Meal"
2. Search for food
3. Select from list or use barcode scanner

## 🔄 Data Backup

SQLite database is located at:
- Docker: `nutrition-db` volume (managed by Docker)
- Manual: `backend/nutrition_app.db`

Backup command:
```bash
cp backend/nutrition_app.db backup/nutrition_app.db.$(date +%s)
```

## 📄 License

MIT License - feel free to modify and use for personal projects

## 🤝 Contributing

For issues or improvements, please submit a PR or open an issue.

## 📞 Support

For questions or issues, refer to:
- FastAPI Docs: https://fastapi.tiangolo.com
- React Docs: https://react.dev
- PWA Docs: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps
