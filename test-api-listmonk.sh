#!/bin/bash

# Script de test simple pour l'API Listmonk
# Teste l'authentification et les endpoints de base

echo "🧪 Test de l'API Listmonk"
echo "========================="

API_URL="http://localhost:9000/api"

# Test de santé
echo "1. Test de santé..."
if curl -s "$API_URL/health" > /dev/null; then
    echo "✅ API accessible"
else
    echo "❌ API non accessible"
    exit 1
fi

# Test d'authentification
echo "2. Test d'authentification..."
cookie_jar=$(mktemp)

login_response=$(curl -s -c "$cookie_jar" -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"listmonk"}' \
    "$API_URL/auth/login")

if echo "$login_response" | grep -q '"status":"success"'; then
    echo "✅ Authentification réussie"
else
    echo "❌ Échec de l'authentification"
    echo "Réponse: $login_response"
    rm -f "$cookie_jar"
    exit 1
fi

# Test des abonnés
echo "3. Test de l'endpoint subscribers..."
subscribers_response=$(curl -s -b "$cookie_jar" "$API_URL/subscribers?per_page=1")

if echo "$subscribers_response" | grep -q '"total"'; then
    total=$(echo "$subscribers_response" | grep -o '"total":[0-9]*' | cut -d: -f2)
    echo "✅ Endpoint subscribers accessible - Total: $total abonnés"
else
    echo "❌ Problème avec l'endpoint subscribers"
    echo "Réponse: $subscribers_response"
fi

# Test des listes
echo "4. Test de l'endpoint lists..."
lists_response=$(curl -s -b "$cookie_jar" "$API_URL/lists")

if echo "$lists_response" | grep -q '"data"'; then
    echo "✅ Endpoint lists accessible"
else
    echo "❌ Problème avec l'endpoint lists"
fi

# Nettoyer
rm -f "$cookie_jar"

echo ""
echo "✅ Tests terminés"
echo ""
echo "Pour importer les mairies :"
echo "  ./docker-integration-mairies.sh"