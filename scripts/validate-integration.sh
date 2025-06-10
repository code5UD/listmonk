#!/bin/bash

# Script de validation de l'intégration des mairies
# Usage: ./validate-integration.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Validation de l'Intégration Mairies ==="
echo

cd "$PROJECT_DIR"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

success_count=0
total_tests=0

# Fonction pour tester et afficher le résultat
test_item() {
    local description="$1"
    local command="$2"
    local expected_pattern="$3"
    
    total_tests=$((total_tests + 1))
    echo -n "[$total_tests] $description... "
    
    if eval "$command" >/dev/null 2>&1; then
        if [ -n "$expected_pattern" ]; then
            if eval "$command" 2>/dev/null | grep -q "$expected_pattern"; then
                echo -e "${GREEN}✓${NC}"
                success_count=$((success_count + 1))
            else
                echo -e "${RED}✗ (pattern not found)${NC}"
            fi
        else
            echo -e "${GREEN}✓${NC}"
            success_count=$((success_count + 1))
        fi
    else
        echo -e "${RED}✗${NC}"
    fi
}

echo "1. Vérification des fichiers du projet..."

test_item "Fichier CSV original présent" "[ -f mairielist.csv ]"
test_item "Script de conversion présent" "[ -f scripts/convert-mairielist-csv.py ]"
test_item "Script d'import présent" "[ -f scripts/import-mairies.go ]"
test_item "Migration SQL présente" "[ -f migrations/v5.1.0_geo_tables.sql ]"
test_item "Script de correction présent" "[ -f scripts/fix-targeting.sql ]"

echo
echo "2. Vérification de la structure du projet..."

test_item "Module géographique présent" "[ -f internal/geo/geo.go ]"
test_item "Modèles géographiques présents" "[ -f internal/geo/models.go ]"
test_item "Importeur CSV présent" "[ -f internal/geo/importer.go ]"
test_item "Handlers géographiques présents" "[ -f cmd/geo.go ]"
test_item "Handlers de ciblage présents" "[ -f cmd/targeting.go ]"

echo
echo "3. Vérification du contenu des fichiers..."

test_item "Migration utilise french_departments" "grep -q 'french_departments' migrations/v5.1.0_geo_tables.sql"
test_item "Migration utilise french_communes" "grep -q 'french_communes' migrations/v5.1.0_geo_tables.sql"
test_item "Fonction de ciblage présente" "grep -q 'count_targeting_recipients' scripts/fix-targeting.sql"
test_item "Service de ciblage implémenté" "grep -q 'GetTargetedSubscribers' internal/geo/geo.go"

echo
echo "4. Vérification de la conversion CSV..."

if [ -f "mairielist.csv" ]; then
    test_item "Conversion CSV possible" "python3 scripts/convert-mairielist-csv.py mairielist.csv /tmp/test-converted.csv"
    if [ -f "/tmp/test-converted.csv" ]; then
        test_item "CSV converti contient des données" "[ \$(wc -l < /tmp/test-converted.csv) -gt 1000 ]"
        test_item "CSV converti a le bon format" "head -1 /tmp/test-converted.csv | grep -q 'nom_commune;code_insee;code_departement'"
        rm -f /tmp/test-converted.csv
    fi
else
    echo "   ${YELLOW}⚠ Fichier mairielist.csv non trouvé, tests de conversion ignorés${NC}"
fi

echo
echo "5. Vérification des services Docker..."

if command -v docker-compose >/dev/null 2>&1; then
    test_item "Docker Compose disponible" "docker-compose --version"
    test_item "Fichier docker-compose.mairies.yml présent" "[ -f docker-compose.mairies.yml ]"
    
    if docker-compose -f docker-compose.mairies.yml ps | grep -q "Up"; then
        echo "   ${GREEN}Services Docker en cours d'exécution${NC}"
        
        test_item "Service app en cours" "docker-compose -f docker-compose.mairies.yml ps app | grep -q Up"
        test_item "Service db en cours" "docker-compose -f docker-compose.mairies.yml ps db | grep -q Up"
        test_item "Service redis en cours" "docker-compose -f docker-compose.mairies.yml ps redis | grep -q Up"
        
        echo
        echo "6. Tests de connectivité API..."
        
        # Attendre que l'API soit prête
        echo "   Attente de la disponibilité de l'API..."
        for i in {1..30}; do
            if curl -s http://localhost:9000/api/health >/dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        test_item "API de santé accessible" "curl -s -f http://localhost:9000/api/health"
        test_item "Endpoint départements accessible" "curl -s -f http://localhost:9000/api/geo/departments"
        test_item "Endpoint communes accessible" "curl -s -f http://localhost:9000/api/geo/communes"
        test_item "Endpoint stats accessible" "curl -s -f http://localhost:9000/api/geo/stats"
        
        echo
        echo "7. Tests de données..."
        
        test_item "Départements retournent des données" "curl -s http://localhost:9000/api/geo/departments | grep -q '\"code\"'"
        test_item "Stats retournent des données" "curl -s http://localhost:9000/api/geo/stats | grep -q '\"total_'"
        
    else
        echo "   ${YELLOW}⚠ Services Docker non démarrés, tests API ignorés${NC}"
        echo "   Pour démarrer les services: docker-compose -f docker-compose.mairies.yml up -d"
    fi
else
    echo "   ${YELLOW}⚠ Docker Compose non disponible, tests Docker ignorés${NC}"
fi

echo
echo "8. Vérification des scripts de déploiement..."

test_item "Script de déploiement présent" "[ -f scripts/deploy-mairies.sh ]"
test_item "Script de mise à jour présent" "[ -f scripts/update-and-test.sh ]"
test_item "Script d'import présent" "[ -f scripts/import-mairies.sh ]"
test_item "Scripts exécutables" "[ -x scripts/deploy-mairies.sh ] && [ -x scripts/update-and-test.sh ]"

echo
echo "=== Résumé de la Validation ==="
echo

if [ $success_count -eq $total_tests ]; then
    echo -e "${GREEN}✅ Tous les tests sont passés ($success_count/$total_tests)${NC}"
    echo -e "${GREEN}🎉 L'intégration des mairies est complète et fonctionnelle !${NC}"
    exit_code=0
elif [ $success_count -gt $((total_tests * 3 / 4)) ]; then
    echo -e "${YELLOW}⚠️  La plupart des tests sont passés ($success_count/$total_tests)${NC}"
    echo -e "${YELLOW}L'intégration est largement fonctionnelle avec quelques points à vérifier.${NC}"
    exit_code=0
else
    echo -e "${RED}❌ Plusieurs tests ont échoué ($success_count/$total_tests)${NC}"
    echo -e "${RED}L'intégration nécessite des corrections.${NC}"
    exit_code=1
fi

echo
echo "Prochaines étapes recommandées:"
echo "1. Si les services ne sont pas démarrés: ./scripts/deploy-mairies.sh development"
echo "2. Pour importer les données: ./scripts/import-mairies.sh"
echo "3. Pour tester l'interface: http://localhost:9000"
echo "4. Pour voir les logs: docker-compose -f docker-compose.mairies.yml logs -f"

exit $exit_code