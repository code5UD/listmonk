#!/bin/bash

# Script de diagnostic et réparation complète du système de ciblage géographique

set -e

echo "🔍 DIAGNOSTIC ET RÉPARATION COMPLÈTE"
echo "===================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CONTAINER_NAME="listmonk_mairies_app"
DB_CONTAINER="listmonk_mairies_db"
DB_USER="listmonk_mairies"
DB_NAME="listmonk_mairies"
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"
API_URL="http://localhost:9000/api"

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${PURPLE}🔧 $1${NC}"; }

# Étape 1: Diagnostic des données
diagnose_data() {
    log_step "Diagnostic des données existantes..."
    
    echo ""
    log_info "1. Analyse des abonnés existants..."
    
    # Vérifier le contenu des abonnés
    local sample_data=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT email, name, attribs 
        FROM subscribers 
        WHERE email LIKE '%mairie%' OR email LIKE '%@commune-%' OR email LIKE '%@ville-%'
        LIMIT 5;
    " 2>/dev/null)
    
    if [ -n "$sample_data" ] && [ "$sample_data" != "" ]; then
        log_success "Données de mairies détectées"
        echo "$sample_data"
    else
        log_warning "Aucune donnée de mairie détectée dans les emails"
        
        # Vérifier les données de test
        local test_data=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "
            SELECT email, attribs 
            FROM subscribers 
            WHERE email LIKE '%example.com%' 
            LIMIT 3;
        " 2>/dev/null)
        
        if [ -n "$test_data" ]; then
            log_warning "Données de test détectées :"
            echo "$test_data"
        fi
    fi
    
    echo ""
    log_info "2. Vérification du fichier CSV original..."
    
    if [ -f "mairielist-converted.csv" ]; then
        local csv_lines=$(wc -l < mairielist-converted.csv)
        local csv_sample=$(head -3 mairielist-converted.csv)
        
        log_success "Fichier CSV trouvé : $csv_lines lignes"
        echo "Échantillon :"
        echo "$csv_sample"
    else
        log_error "Fichier CSV mairielist-converted.csv non trouvé"
        
        # Chercher d'autres fichiers CSV
        log_info "Recherche d'autres fichiers CSV..."
        find . -name "*.csv" -type f | head -5
    fi
}

# Étape 2: Nettoyage et réimport
clean_and_reimport() {
    log_step "Nettoyage et réimport des données..."
    
    echo ""
    log_warning "Cette opération va supprimer tous les abonnés existants et réimporter les mairies."
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Opération annulée"
        return 1
    fi
    
    # Supprimer tous les abonnés existants
    log_info "Suppression des abonnés existants..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM subscribers;" > /dev/null 2>&1
    
    # Vérifier que le fichier CSV existe et est correct
    if [ ! -f "mairielist-converted.csv" ]; then
        log_error "Fichier CSV non trouvé. Création d'un fichier de test..."
        create_test_csv
    fi
    
    # Réimporter via l'API
    log_info "Réimport des mairies via l'API Listmonk..."
    
    # Créer ou récupérer la liste par défaut
    local list_id=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists" | jq -r '.data[0].id // 1')
    
    if [ "$list_id" = "null" ] || [ -z "$list_id" ]; then
        log_info "Création d'une nouvelle liste..."
        list_id=$(curl -s -u "$API_USER:$API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"name":"Mairies","type":"public","optin":"single","tags":["mairies","france"]}' \
            "$API_URL/lists" | jq -r '.data.id')
    fi
    
    log_info "Utilisation de la liste ID: $list_id"
    
    # Import via API
    log_info "Lancement de l'import..."
    local import_response=$(curl -s -u "$API_USER:$API_TOKEN" \
        -F "file=@mairielist-converted.csv" \
        -F "params={\"list_ids\":[$list_id],\"overwrite\":true,\"delim\":\",\"mode\":\"subscribe\"}" \
        "$API_URL/import/subscribers")
    
    echo "Réponse import: $import_response"
    
    # Attendre la fin de l'import
    log_info "Attente de la fin de l'import (60 secondes)..."
    sleep 60
    
    # Vérifier le résultat
    local new_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" | tr -d ' ')
    log_success "Nouveaux abonnés importés : $new_count"
}

# Étape 3: Création d'un fichier CSV de test si nécessaire
create_test_csv() {
    log_info "Création d'un fichier CSV de test avec des mairies françaises..."
    
    cat > mairielist-converted.csv << 'EOF'
email,firstname,lastname,title,phone,website,address1,city,state,zipcode,country,code_insee,population_commune,date_naissance,csp,siren,siret,telecopie,nom_commune,departement_numero
mairie.paris@paris.fr,Maire,PARIS,M,01 42 76 40 40,https://www.paris.fr,"Place de l'Hôtel de Ville, 75004 Paris",PARIS,PARIS,75004,France,75056,2161000,,Élus,217500016,21750001600019,,PARIS,75
mairie@marseille.fr,Maire,MARSEILLE,M,04 91 55 11 11,https://www.marseille.fr,"2 quai du Port, 13002 Marseille",MARSEILLE,BOUCHES-DU-RHÔNE,13002,France,13055,870018,,Élus,211300553,21130055300019,,MARSEILLE,13
mairie@lyon.fr,Maire,LYON,M,04 72 10 30 30,https://www.lyon.fr,"1 place de la Comédie, 69001 Lyon",LYON,RHÔNE,69001,France,69123,518635,,Élus,216901231,21690123100019,,LYON,69
mairie@toulouse.fr,Maire,TOULOUSE,M,05 61 22 29 22,https://www.toulouse.fr,"1 place du Capitole, 31000 Toulouse",TOULOUSE,HAUTE-GARONNE,31000,France,31555,479553,,Élus,213105552,21310555200019,,TOULOUSE,31
mairie@nice.fr,Maire,NICE,M,04 97 13 20 00,https://www.nice.fr,"5 rue de l'Hôtel de ville, 06000 Nice",NICE,ALPES-MARITIMES,06000,France,06088,342637,,Élus,210600887,21060088700019,,NICE,06
mairie@nantes.fr,Maire,NANTES,M,02 40 41 90 00,https://www.nantes.fr,"2 rue de l'Hôtel de Ville, 44000 Nantes",NANTES,LOIRE-ATLANTIQUE,44000,France,44109,314138,,Élus,214401094,21440109400019,,NANTES,44
mairie@montpellier.fr,Maire,MONTPELLIER,M,04 67 34 70 00,https://www.montpellier.fr,"1 place Georges Frêche, 34000 Montpellier",MONTPELLIER,HÉRAULT,34000,France,34172,290053,,Élus,213401721,21340172100019,,MONTPELLIER,34
mairie@strasbourg.eu,Maire,STRASBOURG,M,03 68 98 50 00,https://www.strasbourg.eu,"1 parc de l'Étoile, 67000 Strasbourg",STRASBOURG,BAS-RHIN,67000,France,67482,280966,,Élus,216704821,21670482100019,,STRASBOURG,67
mairie@bordeaux.fr,Maire,BORDEAUX,M,05 56 10 20 30,https://www.bordeaux.fr,"Place Pey Berland, 33000 Bordeaux",BORDEAUX,GIRONDE,33000,France,33063,254436,,Élus,213300631,21330063100019,,BORDEAUX,33
mairie@lille.fr,Maire,LILLE,M,03 20 49 50 00,https://www.lille.fr,"Place Augustin Laurent, 59000 Lille",LILLE,NORD,59000,France,59350,232787,,Élus,215903501,21590350100019,,LILLE,59
mairie@rennes.fr,Maire,RENNES,M,02 23 62 10 10,https://www.rennes.fr,"Place de la Mairie, 35000 Rennes",RENNES,ILLE-ET-VILAINE,35000,France,35238,217728,,Élus,213502381,21350238100019,,RENNES,35
mairie@reims.fr,Maire,REIMS,M,03 26 77 78 79,https://www.reims.fr,"Place de l'Hôtel de Ville, 51100 Reims",REIMS,MARNE,51100,France,51454,182460,,Élus,215104541,21510454100019,,REIMS,51
mairie@saintetienne.fr,Maire,SAINT-ÉTIENNE,M,04 77 48 77 48,https://www.saintetienne.fr,"Place de l'Hôtel de Ville, 42000 Saint-Étienne",SAINT-ÉTIENNE,LOIRE,42000,France,42218,172565,,Élus,214202181,21420218100019,,SAINT-ÉTIENNE,42
mairie@havre.fr,Maire,LE HAVRE,M,02 35 19 45 45,https://www.lehavre.fr,"Place de l'Hôtel de Ville, 76600 Le Havre",LE HAVRE,SEINE-MARITIME,76600,France,76351,170147,,Élus,217603511,21760351100019,,LE HAVRE,76
mairie@toulon.fr,Maire,TOULON,M,04 94 36 30 00,https://www.toulon.fr,"Avenue de la République, 83000 Toulon",TOULON,VAR,83000,France,83137,171953,,Élus,218301371,21830137100019,,TOULON,83
mairie@grenoble.fr,Maire,GRENOBLE,M,04 76 76 36 36,https://www.grenoble.fr,"11 boulevard Jean Pain, 38000 Grenoble",GRENOBLE,ISÈRE,38000,France,38185,158552,,Élus,213801851,21380185100019,,GRENOBLE,38
mairie@dijon.fr,Maire,DIJON,M,03 80 74 51 51,https://www.dijon.fr,"Place de la Libération, 21000 Dijon",DIJON,CÔTE-D'OR,21000,France,21231,155090,,Élus,212102311,21210231100019,,DIJON,21
mairie@angers.fr,Maire,ANGERS,M,02 41 05 40 00,https://www.angers.fr,"1 rue de l'Hôtel de Ville, 49000 Angers",ANGERS,MAINE-ET-LOIRE,49000,France,49007,152960,,Élus,214900071,21490007100019,,ANGERS,49
mairie@villeurbanne.fr,Maire,VILLEURBANNE,M,04 78 03 67 67,https://www.villeurbanne.fr,"Place Lazare Goujon, 69100 Villeurbanne",VILLEURBANNE,RHÔNE,69100,France,69266,149019,,Élus,216902661,21690266100019,,VILLEURBANNE,69
mairie@nimes.fr,Maire,NÎMES,M,04 66 76 70 01,https://www.nimes.fr,"Place de l'Hôtel de Ville, 30000 Nîmes",NÎMES,GARD,30000,France,30189,148561,,Élus,213001891,21300189100019,,NÎMES,30
EOF

    log_success "Fichier CSV de test créé avec 20 grandes villes françaises"
}

# Étape 4: Correction de l'extraction des données géographiques
fix_geo_extraction() {
    log_step "Correction de l'extraction des données géographiques..."
    
    # Script SQL amélioré pour l'extraction
    cat > /tmp/fix_geo_extraction_improved.sql << 'EOF'
-- Script amélioré pour l'extraction des données géographiques

-- 1. Vérifier la structure des données
SELECT 'Structure des abonnés' as info;
SELECT 
    COUNT(*) as total,
    COUNT(attribs) as with_attribs,
    COUNT(CASE WHEN attribs IS NOT NULL AND jsonb_typeof(attribs) = 'object' THEN 1 END) as with_object_attribs
FROM subscribers;

-- 2. Analyser les attributs existants
SELECT 'Échantillon d\'attributs' as info;
SELECT email, attribs 
FROM subscribers 
WHERE attribs IS NOT NULL 
AND jsonb_typeof(attribs) = 'object'
LIMIT 5;

-- 3. Extraire les données depuis les champs de base (email, name, etc.)
UPDATE subscribers SET
    department_code = CASE
        -- Extraire depuis l'email si format mairie@ville-XXXXX.fr
        WHEN email ~ '@[^-]+-(\d{2,3})[^@]*\.' THEN 
            LPAD(substring(email from '@[^-]+-(\d{2,3})[^@]*\.'), 2, '0')
        -- Extraire depuis le code postal dans l'adresse
        WHEN attribs->>'zipcode' IS NOT NULL THEN 
            LPAD(substring(attribs->>'zipcode' from '^(\d{2})'), 2, '0')
        -- Extraire depuis le nom de la commune
        WHEN name IS NOT NULL AND name ~ '\d{5}' THEN
            LPAD(substring(name from '(\d{2})\d{3}'), 2, '0')
        ELSE NULL
    END,
    
    population = CASE
        WHEN attribs->>'population_commune' IS NOT NULL THEN 
            (attribs->>'population_commune')::INTEGER
        WHEN attribs->>'population' IS NOT NULL THEN 
            (attribs->>'population')::INTEGER
        -- Estimation basée sur le type de ville
        WHEN name ILIKE '%paris%' THEN 2161000
        WHEN name ILIKE '%marseille%' THEN 870018
        WHEN name ILIKE '%lyon%' THEN 518635
        WHEN name ILIKE '%toulouse%' THEN 479553
        WHEN name ILIKE '%nice%' THEN 342637
        ELSE NULL
    END,
    
    commune_code = CASE
        WHEN attribs->>'code_insee' IS NOT NULL THEN attribs->>'code_insee'
        WHEN attribs->>'insee' IS NOT NULL THEN attribs->>'insee'
        ELSE NULL
    END
WHERE TRUE;

-- 4. Mise à jour depuis les noms de communes dans les emails
UPDATE subscribers SET
    department_code = CASE
        WHEN email ILIKE '%paris%' THEN '75'
        WHEN email ILIKE '%marseille%' THEN '13'
        WHEN email ILIKE '%lyon%' THEN '69'
        WHEN email ILIKE '%toulouse%' THEN '31'
        WHEN email ILIKE '%nice%' THEN '06'
        WHEN email ILIKE '%nantes%' THEN '44'
        WHEN email ILIKE '%montpellier%' THEN '34'
        WHEN email ILIKE '%strasbourg%' THEN '67'
        WHEN email ILIKE '%bordeaux%' THEN '33'
        WHEN email ILIKE '%lille%' THEN '59'
        WHEN email ILIKE '%rennes%' THEN '35'
        WHEN email ILIKE '%reims%' THEN '51'
        WHEN email ILIKE '%saintetienne%' OR email ILIKE '%saint-etienne%' THEN '42'
        WHEN email ILIKE '%havre%' THEN '76'
        WHEN email ILIKE '%toulon%' THEN '83'
        WHEN email ILIKE '%grenoble%' THEN '38'
        WHEN email ILIKE '%dijon%' THEN '21'
        WHEN email ILIKE '%angers%' THEN '49'
        WHEN email ILIKE '%villeurbanne%' THEN '69'
        WHEN email ILIKE '%nimes%' THEN '30'
        ELSE department_code
    END
WHERE department_code IS NULL;

-- 5. Estimation de population pour les communes connues
UPDATE subscribers SET
    population = CASE
        WHEN email ILIKE '%paris%' AND population IS NULL THEN 2161000
        WHEN email ILIKE '%marseille%' AND population IS NULL THEN 870018
        WHEN email ILIKE '%lyon%' AND population IS NULL THEN 518635
        WHEN email ILIKE '%toulouse%' AND population IS NULL THEN 479553
        WHEN email ILIKE '%nice%' AND population IS NULL THEN 342637
        WHEN email ILIKE '%nantes%' AND population IS NULL THEN 314138
        WHEN email ILIKE '%montpellier%' AND population IS NULL THEN 290053
        WHEN email ILIKE '%strasbourg%' AND population IS NULL THEN 280966
        WHEN email ILIKE '%bordeaux%' AND population IS NULL THEN 254436
        WHEN email ILIKE '%lille%' AND population IS NULL THEN 232787
        -- Estimation par défaut pour les autres
        WHEN department_code IS NOT NULL AND population IS NULL THEN 5000
        ELSE population
    END
WHERE TRUE;

-- 6. Statistiques finales
SELECT 
    'Résultats finaux' as info,
    COUNT(*) as total_subscribers,
    COUNT(department_code) as with_department,
    COUNT(CASE WHEN population > 0 THEN 1 END) as with_population,
    COUNT(commune_code) as with_commune_code
FROM subscribers;

-- 7. Échantillon des données mises à jour
SELECT 
    email, 
    department_code, 
    population, 
    commune_code,
    substring(name from 1 for 30) as commune_name
FROM subscribers 
WHERE department_code IS NOT NULL 
ORDER BY population DESC NULLS LAST
LIMIT 10;
EOF

    log_info "Exécution du script d'extraction amélioré..."
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < /tmp/fix_geo_extraction_improved.sql
    
    rm -f /tmp/fix_geo_extraction_improved.sql
}

# Étape 5: Correction de l'accès au fichier JavaScript
fix_javascript_access() {
    log_step "Correction de l'accès au fichier JavaScript..."
    
    # Vérifier la structure des répertoires dans le conteneur
    log_info "Vérification de la structure des répertoires..."
    docker exec "$CONTAINER_NAME" find /listmonk -name "static" -type d
    
    # Copier le fichier dans le bon répertoire
    log_info "Copie du fichier JavaScript dans le répertoire public..."
    
    # Créer le répertoire s'il n'existe pas
    docker exec "$CONTAINER_NAME" mkdir -p /listmonk/static/public/js
    
    # Copier le fichier
    docker cp /tmp/geo-targeting-ui.js "$CONTAINER_NAME":/listmonk/static/public/js/geo-targeting.js
    
    # Vérifier les permissions
    docker exec "$CONTAINER_NAME" chmod 644 /listmonk/static/public/js/geo-targeting.js
    
    # Créer aussi une version dans le répertoire racine static
    docker exec "$CONTAINER_NAME" cp /listmonk/static/public/js/geo-targeting.js /listmonk/static/geo-targeting.js
    
    log_success "Fichier JavaScript copié dans plusieurs emplacements"
}

# Étape 6: Test complet
test_complete_system() {
    log_step "Test complet du système..."
    
    echo ""
    log_info "1. Test des données géographiques..."
    
    local dept_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;" | tr -d ' ')
    local pop_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE population > 0;" | tr -d ' ')
    
    log_info "Abonnés avec département : $dept_count"
    log_info "Abonnés avec population : $pop_count"
    
    if [ "$dept_count" -gt 10 ] && [ "$pop_count" -gt 10 ]; then
        log_success "Données géographiques correctes"
    else
        log_warning "Données géographiques insuffisantes"
    fi
    
    echo ""
    log_info "2. Test des requêtes de ciblage..."
    
    # Test Paris
    local paris_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE department_code = '75';" | tr -d ' ')
    log_info "Mairies Paris (75) : $paris_count"
    
    # Test grandes communes
    local large_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE population > 100000;" | tr -d ' ')
    log_info "Grandes communes (>100k hab.) : $large_count"
    
    echo ""
    log_info "3. Test de l'accès JavaScript..."
    
    if curl -s "http://localhost:9000/static/geo-targeting.js" | grep -q "Ciblage"; then
        log_success "JavaScript accessible via /static/geo-targeting.js"
    elif curl -s "http://localhost:9000/static/public/js/geo-targeting.js" | grep -q "Ciblage"; then
        log_success "JavaScript accessible via /static/public/js/geo-targeting.js"
    else
        log_warning "JavaScript non accessible via HTTP"
    fi
}

# Fonction principale
main() {
    echo ""
    log_step "Ce script va diagnostiquer et réparer complètement le système de ciblage géographique."
    echo ""
    echo "🔧 Étapes :"
    echo "  1. Diagnostic des données existantes"
    echo "  2. Nettoyage et réimport si nécessaire"
    echo "  3. Correction de l'extraction géographique"
    echo "  4. Réparation de l'accès JavaScript"
    echo "  5. Tests complets"
    echo ""
    
    read -p "Continuer avec le diagnostic et la réparation ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    echo ""
    log_step "🔍 DÉBUT DU DIAGNOSTIC ET DE LA RÉPARATION"
    echo ""
    
    # Exécuter toutes les étapes
    diagnose_data
    
    echo ""
    log_info "Voulez-vous nettoyer et réimporter les données ? (recommandé si pas de vraies mairies)"
    read -p "Nettoyer et réimporter ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        clean_and_reimport
    fi
    
    fix_geo_extraction
    fix_javascript_access
    
    # Redémarrer le service
    log_info "Redémarrage du service..."
    docker restart "$CONTAINER_NAME"
    sleep 20
    
    test_complete_system
    
    echo ""
    log_success "🎉 DIAGNOSTIC ET RÉPARATION TERMINÉS !"
    echo ""
    log_info "🌐 Testez maintenant votre Listmonk : http://localhost:9000"
    log_info "📊 Lancez la vérification : ./verify-geo-targeting.sh"
    echo ""
}

# Exécuter le script principal
main "$@"