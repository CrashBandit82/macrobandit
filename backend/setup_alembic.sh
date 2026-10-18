#!/bin/bash
# Alembic Setup - einmalig ausführen
# bash /opt/macrobandit/backend/setup_alembic.sh

set -e
cd /opt/macrobandit/backend
source venv/bin/activate

echo "📦 Installiere Alembic..."
pip install alembic

echo "🔧 Initialisiere Alembic..."
alembic init alembic

echo "📝 Konfiguriere env.py..."
cp /opt/macrobandit/backend/alembic_env.py /opt/macrobandit/backend/alembic/env.py

echo "📸 Erstelle initiale Migration (aktueller DB-Stand)..."
alembic revision --autogenerate -m "initial_schema"

echo "✅ Alembic eingerichtet!"
echo ""
echo "Nächste Schritte:"
echo "  alembic upgrade head          → Migration anwenden"
echo "  alembic revision --autogenerate -m 'beschreibung'  → Neue Migration erstellen"
echo "  alembic history               → Migrationshistorie"
echo "  alembic current               → Aktuelle Version"
