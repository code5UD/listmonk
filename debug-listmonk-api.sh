#!/bin/bash

# Script de debug pour comprendre l'API Listmonk

echo "🔍 Debug de l'API Listmonk"
echo "=========================="

API_URL="http://localhost:9000"

echo "1. Test de l'interface web..."
curl -s -I "$API_URL" | head -5

echo ""
echo "2. Test de l'endpoint API health..."
curl -s "$API_URL/api/health" | head -200

echo ""
echo "3. Test de l'endpoint API sans auth..."
curl -s "$API_URL/api" | head -200

echo ""
echo "4. Test avec authentification basique..."
curl -s -u admin:listmonk "$API_URL/api/subscribers?per_page=1" | head -200

echo ""
echo "5. Test de l'endpoint d'import..."
curl -s -u admin:listmonk "$API_URL/api/import" | head -200

echo ""
echo "6. Vérification des endpoints disponibles..."
curl -s -u admin:listmonk "$API_URL/api/config" | head -200

echo ""
echo "7. Test de login avec différents endpoints..."
echo "Tentative 1: /api/auth/login"
curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"listmonk"}' "$API_URL/api/auth/login"

echo ""
echo "Tentative 2: /api/login"
curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"listmonk"}' "$API_URL/api/login"

echo ""
echo "Tentative 3: /admin/login"
curl -s -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"listmonk"}' "$API_URL/admin/login"

echo ""
echo "8. Vérification de la version..."
docker exec listmonk_mairies_app /listmonk --version 2>/dev/null || echo "Impossible de récupérer la version"

echo ""
echo "9. Vérification de la configuration..."
docker exec listmonk_mairies_app cat /listmonk/config.toml | grep -A5 -B5 admin || echo "Config non accessible"