#!/bin/bash
# MacroBandit Deploy Script
# Ausführen nach Code-Änderungen: bash /opt/macrobandit/deploy.sh

set -e

echo "🚀 MacroBandit Deploy gestartet..."

# Build-Timestamp generieren
BUILD_TIME=$(date +%Y%m%d%H%M%S)
echo "📦 Build-Version: $BUILD_TIME"

# Service Worker mit aktuellem Timestamp versehen
sed "s/__BUILD_TIME__/$BUILD_TIME/g" \
  /opt/macrobandit/frontend/public/sw.js.template \
  > /opt/macrobandit/frontend/public/sw.js

echo "✓ Service Worker aktualisiert"

# Frontend bauen
cd /opt/macrobandit/frontend
npm run build
echo "✓ Frontend gebaut"

# Backend neu starten (falls Backend-Dateien geändert)
systemctl restart macrobandit-backend
echo "✓ Backend neugestartet"

echo "✅ Deploy abgeschlossen! Version: $BUILD_TIME"

# Log-Rotation sicherstellen
if [ -f "/var/log/macrobandit/app.log" ]; then
  SIZE=$(du -m /var/log/macrobandit/app.log | cut -f1)
  if [ "$SIZE" -gt 50 ]; then
    echo "⚠️  Log-Datei ist ${SIZE}MB groß"
  fi
fi
