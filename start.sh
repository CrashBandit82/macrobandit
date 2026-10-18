#!/bin/bash

# Development startup script for Nutrition PWA

set -e

echo "🚀 Starting Nutrition PWA Development Environment"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is available
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo -e "${BLUE}📦 Using Docker...${NC}"
    docker-compose up
else
    echo -e "${BLUE}🔧 Using manual setup...${NC}"
    
    # Start backend
    echo -e "${GREEN}Starting Backend...${NC}"
    cd backend
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate
    pip install -q -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!
    cd ..
    
    sleep 2
    
    # Start frontend
    echo -e "${GREEN}Starting Frontend...${NC}"
    cd frontend
    npm install > /dev/null 2>&1
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
    echo ""
    echo -e "${GREEN}✓ Backend running on http://localhost:8000${NC}"
    echo -e "${GREEN}✓ Frontend running on http://localhost:5173${NC}"
    echo -e "${GREEN}✓ API Docs: http://localhost:8000/docs${NC}"
    echo ""
    echo "Press Ctrl+C to stop"
    
    # Cleanup on exit
    trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null" EXIT
    
    wait
fi
