#!/bin/bash

# Test de la clé API Listmonk

echo "🔑 Test de la clé API Listmonk"
echo "=============================="

API_URL="http://localhost:9000/api"
API_KEY="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"

echo "Clé API utilisée : $API_KEY"
echo ""

echo "1. Test avec Authorization: Bearer..."
response1=$(curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/subscribers?per_page=1")
echo "Réponse: $response1"
echo ""

echo "2. Test avec X-API-Key..."
response2=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/subscribers?per_page=1")
echo "Réponse: $response2"
echo ""

echo "3. Test avec paramètre api_key..."
response3=$(curl -s "$API_URL/subscribers?per_page=1&api_key=$API_KEY")
echo "Réponse: $response3"
echo ""

echo "4. Test de l'endpoint health..."
health=$(curl -s "$API_URL/health")
echo "Health: $health"
echo ""

echo "5. Test de l'endpoint config avec clé API..."
config=$(curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/config")
echo "Config: $config" | head -200
echo ""

echo "6. Test de l'endpoint lists..."
lists=$(curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/lists")
echo "Lists: $lists"
echo ""

# Analyser les résultats
echo "=== ANALYSE ==="
if echo "$response1" | grep -q '"data"'; then
    echo "✅ Authorization: Bearer fonctionne"
elif echo "$response2" | grep -q '"data"'; then
    echo "✅ X-API-Key fonctionne"
elif echo "$response3" | grep -q '"data"'; then
    echo "✅ Paramètre api_key fonctionne"
else
    echo "❌ Aucune méthode d'authentification ne fonctionne"
    echo "Vérifiez que la clé API est correcte"
fi