#!/bin/bash

# Test de l'authentification selon la documentation officielle Listmonk

echo "🔐 Test authentification officielle Listmonk"
echo "============================================="

API_URL="http://localhost:9000/api"
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"

echo "Utilisateur : $API_USER"
echo "Token : $API_TOKEN"
echo "URL API : $API_URL"
echo ""

echo "1. Test de santé de l'API (sans auth)..."
health=$(curl -s "$API_URL/health")
echo "Health: $health"
echo ""

echo "2. Test BasicAuth (méthode recommandée)..."
echo "Commande: curl -u \"$API_USER:$API_TOKEN\" $API_URL/lists"
response1=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists")
echo "Réponse: $response1"
echo ""

echo "3. Test Authorization token header..."
echo "Commande: curl -H \"Authorization: token $API_USER:$API_TOKEN\" $API_URL/lists"
response2=$(curl -s -H "Authorization: token $API_USER:$API_TOKEN" "$API_URL/lists")
echo "Réponse: $response2"
echo ""

echo "4. Test endpoint subscribers avec BasicAuth..."
subscribers=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/subscribers?per_page=1")
echo "Subscribers: $subscribers"
echo ""

echo "5. Test endpoint config..."
config=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/config")
echo "Config: $config" | head -200
echo ""

# Analyser les résultats
echo "=== ANALYSE ==="
if echo "$response1" | grep -q '"data"'; then
    echo "✅ BasicAuth fonctionne parfaitement"
    echo "   Utilisez: curl -u \"$API_USER:$API_TOKEN\" [URL]"
elif echo "$response2" | grep -q '"data"'; then
    echo "✅ Authorization token fonctionne"
    echo "   Utilisez: curl -H \"Authorization: token $API_USER:$API_TOKEN\" [URL]"
else
    echo "❌ Aucune méthode d'authentification ne fonctionne"
    echo ""
    echo "Vérifications à faire :"
    echo "1. Le conteneur Listmonk est-il en cours d'exécution ?"
    echo "   docker ps | grep listmonk"
    echo ""
    echo "2. L'API est-elle accessible ?"
    echo "   curl $API_URL/health"
    echo ""
    echo "3. Les identifiants sont-ils corrects ?"
    echo "   Vérifiez dans l'interface admin de Listmonk"
    echo ""
    echo "4. L'utilisateur API a-t-il les bonnes permissions ?"
    echo "   Admin -> Users -> Vérifiez les rôles"
fi

echo ""
echo "📚 Documentation officielle :"
echo "   https://listmonk.app/docs/apis/apis/"