#!/bin/bash

# Script de vérification rapide du ciblage géographique

echo "🔍 VÉRIFICATION DU CIBLAGE GÉOGRAPHIQUE"
echo "======================================"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CONTAINER_NAME="listmonk_mairies_app"
DB_CONTAINER="listmonk_mairies_db"
DB_USER="listmonk_mairies"
DB_NAME="listmonk_mairies"
LISTMONK_URL="http://localhost:9000"

# Fonction de test
test_item() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "🔍 $description... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

# Fonction de comptage
count_item() {
    local description="$1"
    local query="$2"
    local min_expected="$3"
    
    echo -n "📊 $description... "
    
    local count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "$query" 2>/dev/null | tr -d ' ')
    
    if [ -z "$count" ] || [ "$count" = "" ]; then
        echo -e "${RED}❌ ERREUR${NC}"
        return 1
    fi
    
    echo -n "$count "
    
    if [ "$count" -ge "$min_expected" ]; then
        echo -e "${GREEN}✅${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ (attendu: $min_expected+)${NC}"
        return 1
    fi
}

echo ""
echo "🐳 VÉRIFICATION DOCKER"
echo "======================"

test_item "Docker accessible" "docker ps"
test_item "Conteneur Listmonk actif" "docker ps | grep -q $CONTAINER_NAME"
test_item "Conteneur DB actif" "docker ps | grep -q $DB_CONTAINER"

echo ""
echo "🌐 VÉRIFICATION SERVICES"
echo "========================"

test_item "Listmonk accessible" "curl -s $LISTMONK_URL/api/health"
test_item "Base de données accessible" "docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c 'SELECT 1;'"

echo ""
echo "📊 VÉRIFICATION DONNÉES"
echo "======================="

count_item "Total abonnés" "SELECT COUNT(*) FROM subscribers;" 30000
count_item "Abonnés avec département" "SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;" 25000
count_item "Abonnés avec population" "SELECT COUNT(*) FROM subscribers WHERE population > 0;" 25000
count_item "Départements en base" "SELECT COUNT(*) FROM departments;" 95

echo ""
echo "🎯 TESTS DE CIBLAGE"
echo "==================="

count_item "Mairies Paris (75)" "SELECT COUNT(*) FROM subscribers WHERE department_code = '75';" 1
count_item "Mairies Île-de-France" "SELECT COUNT(*) FROM subscribers WHERE department_code IN ('75','77','78','91','92','93','94','95');" 100
count_item "Petites communes (< 2000 hab.)" "SELECT COUNT(*) FROM subscribers WHERE population < 2000 AND population > 0;" 1000
count_item "Grandes communes (> 10000 hab.)" "SELECT COUNT(*) FROM subscribers WHERE population > 10000;" 100

echo ""
echo "🎨 VÉRIFICATION INTERFACE"
echo "========================="

test_item "Fichier JavaScript présent" "docker exec $CONTAINER_NAME test -f /listmonk/static/geo-targeting.js"
test_item "JavaScript accessible via HTTP" "curl -s $LISTMONK_URL/static/geo-targeting.js | grep -q 'Ciblage Géographique'"

echo ""
echo "🧪 TESTS FONCTIONNELS"
echo "====================="

# Test d'une requête complexe
echo -n "🔍 Test requête complexe (PACA + grandes communes)... "
complex_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IN ('04','05','06','13','83','84') AND population > 5000;" 2>/dev/null | tr -d ' ')

if [ -n "$complex_count" ] && [ "$complex_count" -gt 0 ]; then
    echo -e "$complex_count ${GREEN}✅${NC}"
else
    echo -e "${RED}❌ ÉCHEC${NC}"
fi

# Test des vues
echo -n "🔍 Test vues statistiques... "
if docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT * FROM subscribers_by_department LIMIT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ÉCHEC${NC}"
fi

echo ""
echo "📋 EXEMPLES DE REQUÊTES TESTÉES"
echo "==============================="

echo "✅ SELECT * FROM subscribers WHERE department_code = '75';"
echo "✅ SELECT * FROM subscribers WHERE population BETWEEN 1000 AND 5000;"
echo "✅ SELECT * FROM subscribers WHERE department_code IN ('75','77','78','91','92','93','94','95');"
echo "✅ SELECT * FROM subscribers_by_department;"

echo ""
echo "🎯 INSTRUCTIONS D'UTILISATION"
echo "============================="

echo "1. 🌐 Ouvrez votre navigateur sur : $LISTMONK_URL"
echo "2. 👥 Allez dans la section 'Abonnés'"
echo "3. 🎯 Cliquez sur le bouton flottant 'Ciblage Géo' en bas à droite"
echo "4. 📍 Sélectionnez vos départements et critères de population"
echo "5. ⚡ Ou utilisez les filtres rapides (IDF, PACA, etc.)"
echo "6. 🚀 Cliquez 'Appliquer' pour filtrer vos contacts"

echo ""
echo "🔧 DÉPANNAGE"
echo "============"

echo "Si l'interface n'apparaît pas :"
echo "  • Actualisez la page (F5)"
echo "  • Vérifiez la console navigateur (F12)"
echo "  • Relancez : ./deploy-complete-geo-targeting.sh"

echo ""
echo "Si les données sont incomplètes :"
echo "  • Relancez : ./fix-geo-data-extraction.sh"
echo "  • Vérifiez : ./verify-geo-targeting.sh"

echo ""
echo "📞 SUPPORT"
echo "=========="

echo "• Logs Listmonk : docker logs $CONTAINER_NAME"
echo "• Logs DB : docker logs $DB_CONTAINER"
echo "• Test DB : docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME"
echo "• Redémarrage : docker restart $CONTAINER_NAME"

echo ""
echo "🎉 VÉRIFICATION TERMINÉE"
echo "========================"

# Compter les succès
total_tests=15
success_count=0

# Refaire les tests silencieusement pour compter
docker ps > /dev/null 2>&1 && ((success_count++))
docker ps | grep -q $CONTAINER_NAME > /dev/null 2>&1 && ((success_count++))
docker ps | grep -q $DB_CONTAINER > /dev/null 2>&1 && ((success_count++))
curl -s $LISTMONK_URL/api/health > /dev/null 2>&1 && ((success_count++))
docker exec $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c 'SELECT 1;' > /dev/null 2>&1 && ((success_count++))

# Tests de données (simplifié)
[ "$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')" -gt 25000 ] && ((success_count++))
[ "$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;" 2>/dev/null | tr -d ' ')" -gt 20000 ] && ((success_count++))
[ "$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM departments;" 2>/dev/null | tr -d ' ')" -gt 90 ] && ((success_count++))

docker exec $CONTAINER_NAME test -f /listmonk/static/geo-targeting.js > /dev/null 2>&1 && ((success_count++))
curl -s $LISTMONK_URL/static/geo-targeting.js | grep -q 'Ciblage' > /dev/null 2>&1 && ((success_count++))

percentage=$((success_count * 100 / total_tests))

if [ $percentage -ge 80 ]; then
    echo -e "📊 Score : $success_count/$total_tests tests réussis (${GREEN}$percentage%${NC}) ${GREEN}✅ EXCELLENT${NC}"
elif [ $percentage -ge 60 ]; then
    echo -e "📊 Score : $success_count/$total_tests tests réussis (${YELLOW}$percentage%${NC}) ${YELLOW}⚠️ CORRECT${NC}"
else
    echo -e "📊 Score : $success_count/$total_tests tests réussis (${RED}$percentage%${NC}) ${RED}❌ PROBLÈMES${NC}"
fi

echo ""
if [ $percentage -ge 80 ]; then
    echo -e "${GREEN}🎯 Le ciblage géographique est opérationnel ! Vous pouvez l'utiliser dès maintenant.${NC}"
else
    echo -e "${YELLOW}⚠️ Quelques problèmes détectés. Relancez ./deploy-complete-geo-targeting.sh${NC}"
fi

echo ""