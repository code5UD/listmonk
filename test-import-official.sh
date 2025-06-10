#!/bin/bash

# Test de l'import selon la documentation officielle Listmonk

echo "📤 Test import officiel Listmonk"
echo "================================"

API_URL="http://localhost:9000/api"
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"

echo "Utilisateur : $API_USER"
echo "Token : $API_TOKEN"
echo ""

# Vérifier que le fichier CSV existe
if [ ! -f "mairielist-converted.csv" ]; then
    echo "❌ Fichier mairielist-converted.csv non trouvé"
    echo "Créons un fichier de test..."
    
    cat > test-import.csv << 'EOF'
email,name
test1@example.com,Test User 1
test2@example.com,Test User 2
test3@example.com,Test User 3
EOF
    
    echo "✅ Fichier test-import.csv créé"
    CSV_FILE="test-import.csv"
else
    echo "✅ Fichier mairielist-converted.csv trouvé"
    CSV_FILE="mairielist-converted.csv"
fi

echo ""
echo "1. Test de l'authentification..."
auth_test=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists")
if echo "$auth_test" | grep -q '"data"'; then
    echo "✅ Authentification OK"
else
    echo "❌ Authentification échouée: $auth_test"
    exit 1
fi

echo ""
echo "2. Vérification du statut d'import actuel..."
status=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/import/subscribers")
echo "Statut actuel: $status"

echo ""
echo "3. Test d'import selon la documentation officielle..."
echo "Fichier: $CSV_FILE"

# Paramètres selon la documentation
import_params='{"mode":"subscribe", "subscription_status":"confirmed", "delim":",", "lists":[], "overwrite": true}'
echo "Paramètres: $import_params"

echo ""
echo "Commande curl:"
echo "curl -u \"$API_USER:$API_TOKEN\" -X POST \\"
echo "  -F 'params=$import_params' \\"
echo "  -F 'file=@$CSV_FILE' \\"
echo "  '$API_URL/import/subscribers'"

echo ""
echo "Exécution de l'import..."
import_response=$(curl -s -u "$API_USER:$API_TOKEN" -X POST \
    -F "params=$import_params" \
    -F "file=@$CSV_FILE" \
    "$API_URL/import/subscribers")

echo "Réponse d'import: $import_response"

echo ""
echo "4. Vérification du statut après import..."
sleep 2
status_after=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/import/subscribers")
echo "Statut après import: $status_after"

echo ""
echo "5. Vérification des logs d'import..."
logs=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/import/subscribers/logs")
echo "Logs: $logs"

echo ""
echo "6. Vérification des abonnés..."
subscribers=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/subscribers?per_page=5")
total=$(echo "$subscribers" | grep -o '"total":[0-9]*' | cut -d: -f2)
echo "Total abonnés: $total"

# Nettoyer le fichier de test si créé
if [ "$CSV_FILE" = "test-import.csv" ]; then
    rm -f test-import.csv
    echo "Fichier de test supprimé"
fi

echo ""
echo "=== ANALYSE ==="
if echo "$import_response" | grep -q '"data"'; then
    echo "✅ Import lancé avec succès"
    if echo "$status_after" | grep -q '"status":"finished"'; then
        echo "✅ Import terminé"
    elif echo "$status_after" | grep -q '"status":"running"'; then
        echo "⏳ Import en cours"
    else
        echo "⚠️  Statut d'import inconnu"
    fi
else
    echo "❌ Échec de l'import"
    echo "Vérifiez:"
    echo "1. Les permissions de l'utilisateur API"
    echo "2. Le format du fichier CSV"
    echo "3. Les paramètres d'import"
fi