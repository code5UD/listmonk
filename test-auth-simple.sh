#!/bin/bash

# Test simple de l'authentification Listmonk

echo "🔐 Test d'authentification Listmonk"
echo "==================================="

API_URL="http://localhost:9000/api"

echo "1. Test sans authentification..."
response1=$(curl -s "$API_URL/subscribers?per_page=1")
echo "Réponse: $response1"

echo ""
echo "2. Test avec authentification admin/listmonk..."
response2=$(curl -s -u admin:listmonk "$API_URL/subscribers?per_page=1")
echo "Réponse: $response2"

echo ""
echo "3. Test de l'endpoint health..."
health=$(curl -s "$API_URL/health")
echo "Health: $health"

echo ""
echo "4. Test de l'endpoint config..."
config=$(curl -s -u admin:listmonk "$API_URL/config")
echo "Config: $config" | head -200

echo ""
echo "5. Vérification des identifiants dans le conteneur..."
docker exec listmonk_mairies_app cat /listmonk/config.toml | grep -A3 -B3 admin || echo "Impossible de lire la config"