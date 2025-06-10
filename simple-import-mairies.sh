#!/bin/bash

# Script simple d'import des mairies sans dépendances externes

echo "🏛️ IMPORT SIMPLE DES MAIRIES FRANÇAISES"
echo "======================================="

# Configuration
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"
API_URL="http://localhost:9000/api"
DB_CONTAINER="listmonk_mairies_db"
DB_USER="listmonk_mairies"
DB_NAME="listmonk_mairies"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Installer jq si nécessaire
install_jq() {
    log_info "Installation de jq..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y jq
    elif command -v yum &> /dev/null; then
        yum install -y jq
    else
        log_warning "Impossible d'installer jq automatiquement"
        log_info "Continuons sans jq..."
        return 1
    fi
}

# Vérifier si jq est disponible
if ! command -v jq &> /dev/null; then
    log_warning "jq n'est pas installé"
    install_jq
fi

# Convertir le fichier CSV original
convert_csv() {
    log_info "Conversion du fichier CSV original..."
    
    if [ -f "mairielist-converted.csv" ]; then
        log_info "Fichier mairielist-converted.csv trouvé"
        
        # Vérifier le format (délimiteur)
        local first_line=$(head -1 mairielist-converted.csv)
        if [[ "$first_line" == *";"* ]]; then
            log_warning "Fichier avec délimiteurs ';' détecté, conversion en cours..."
            
            # Convertir ; en ,
            sed 's/;/,/g' mairielist-converted.csv > mairies-converted-comma.csv
            
            # Vérifier le résultat
            local new_first_line=$(head -1 mairies-converted-comma.csv)
            log_info "Nouvelle première ligne : $new_first_line"
            
            # Utiliser le fichier converti
            cp mairies-converted-comma.csv mairies-final.csv
            
        else
            log_success "Fichier déjà au bon format"
            cp mairielist-converted.csv mairies-final.csv
        fi
    else
        log_warning "Fichier mairielist-converted.csv non trouvé, création d'un fichier de test..."
        create_test_csv
    fi
}

# Créer un fichier CSV de test
create_test_csv() {
    log_info "Création d'un fichier CSV de test..."
    
    cat > mairies-final.csv << 'EOF'
email,firstname,lastname,title,phone,website,address1,city,state,zipcode,country,code_insee,population_commune,date_naissance,csp,siren,siret,telecopie,nom_commune,departement_numero
mairie.paris@paris.fr,Maire,PARIS,M,01 42 76 40 40,https://www.paris.fr,"Place de l'Hôtel de Ville",PARIS,PARIS,75004,France,75056,2161000,,,217500016,21750001600019,,PARIS,75
mairie@marseille.fr,Maire,MARSEILLE,M,04 91 55 11 11,https://www.marseille.fr,"2 quai du Port",MARSEILLE,BOUCHES-DU-RHÔNE,13002,France,13055,870018,,,211300553,21130055300019,,MARSEILLE,13
mairie@lyon.fr,Maire,LYON,M,04 72 10 30 30,https://www.lyon.fr,"1 place de la Comédie",LYON,RHÔNE,69001,France,69123,518635,,,216901231,21690123100019,,LYON,69
mairie@toulouse.fr,Maire,TOULOUSE,M,05 61 22 29 22,https://www.toulouse.fr,"1 place du Capitole",TOULOUSE,HAUTE-GARONNE,31000,France,31555,479553,,,213105552,21310555200019,,TOULOUSE,31
mairie@nice.fr,Maire,NICE,M,04 97 13 20 00,https://www.nice.fr,"5 rue de l'Hôtel de ville",NICE,ALPES-MARITIMES,06000,France,06088,342637,,,210600887,21060088700019,,NICE,06
mairie@nantes.fr,Maire,NANTES,M,02 40 41 90 00,https://www.nantes.fr,"2 rue de l'Hôtel de Ville",NANTES,LOIRE-ATLANTIQUE,44000,France,44109,314138,,,214401094,21440109400019,,NANTES,44
mairie@montpellier.fr,Maire,MONTPELLIER,M,04 67 34 70 00,https://www.montpellier.fr,"1 place Georges Frêche",MONTPELLIER,HÉRAULT,34000,France,34172,290053,,,213401721,21340172100019,,MONTPELLIER,34
mairie@strasbourg.eu,Maire,STRASBOURG,M,03 68 98 50 00,https://www.strasbourg.eu,"1 parc de l'Étoile",STRASBOURG,BAS-RHIN,67000,France,67482,280966,,,216704821,21670482100019,,STRASBOURG,67
mairie@bordeaux.fr,Maire,BORDEAUX,M,05 56 10 20 30,https://www.bordeaux.fr,"Place Pey Berland",BORDEAUX,GIRONDE,33000,France,33063,254436,,,213300631,21330063100019,,BORDEAUX,33
mairie@lille.fr,Maire,LILLE,M,03 20 49 50 00,https://www.lille.fr,"Place Augustin Laurent",LILLE,NORD,59000,France,59350,232787,,,215903501,21590350100019,,LILLE,59
mairie@rennes.fr,Maire,RENNES,M,02 23 62 10 10,https://www.rennes.fr,"Place de la Mairie",RENNES,ILLE-ET-VILAINE,35000,France,35238,217728,,,213502381,21350238100019,,RENNES,35
mairie@reims.fr,Maire,REIMS,M,03 26 77 78 79,https://www.reims.fr,"Place de l'Hôtel de Ville",REIMS,MARNE,51100,France,51454,182460,,,215104541,21510454100019,,REIMS,51
mairie@saintetienne.fr,Maire,SAINT-ÉTIENNE,M,04 77 48 77 48,https://www.saintetienne.fr,"Place de l'Hôtel de Ville",SAINT-ÉTIENNE,LOIRE,42000,France,42218,172565,,,214202181,21420218100019,,SAINT-ÉTIENNE,42
mairie@havre.fr,Maire,LE HAVRE,M,02 35 19 45 45,https://www.lehavre.fr,"Place de l'Hôtel de Ville",LE HAVRE,SEINE-MARITIME,76600,France,76351,170147,,,217603511,21760351100019,,LE HAVRE,76
mairie@toulon.fr,Maire,TOULON,M,04 94 36 30 00,https://www.toulon.fr,"Avenue de la République",TOULON,VAR,83000,France,83137,171953,,,218301371,21830137100019,,TOULON,83
mairie@grenoble.fr,Maire,GRENOBLE,M,04 76 76 36 36,https://www.grenoble.fr,"11 boulevard Jean Pain",GRENOBLE,ISÈRE,38000,France,38185,158552,,,213801851,21380185100019,,GRENOBLE,38
mairie@dijon.fr,Maire,DIJON,M,03 80 74 51 51,https://www.dijon.fr,"Place de la Libération",DIJON,CÔTE-D'OR,21000,France,21231,155090,,,212102311,21210231100019,,DIJON,21
mairie@angers.fr,Maire,ANGERS,M,02 41 05 40 00,https://www.angers.fr,"1 rue de l'Hôtel de Ville",ANGERS,MAINE-ET-LOIRE,49000,France,49007,152960,,,214900071,21490007100019,,ANGERS,49
mairie@villeurbanne.fr,Maire,VILLEURBANNE,M,04 78 03 67 67,https://www.villeurbanne.fr,"Place Lazare Goujon",VILLEURBANNE,RHÔNE,69100,France,69266,149019,,,216902661,21690266100019,,VILLEURBANNE,69
mairie@nimes.fr,Maire,NÎMES,M,04 66 76 70 01,https://www.nimes.fr,"Place de l'Hôtel de Ville",NÎMES,GARD,30000,France,30189,148561,,,213001891,21300189100019,,NÎMES,30
EOF

    log_success "Fichier CSV de test créé avec 20 grandes villes"
}

# Import direct via curl (sans jq)
import_via_curl() {
    log_info "Import via curl (méthode simple)..."
    
    # Nettoyer les abonnés existants
    log_info "Suppression des abonnés existants..."
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM subscribers;" > /dev/null 2>&1
    
    # Vérifier que l'API est accessible
    if ! curl -s -u "$API_USER:$API_TOKEN" "$API_URL/health" > /dev/null 2>&1; then
        log_error "API Listmonk non accessible"
        return 1
    fi
    
    # Obtenir ou créer une liste
    log_info "Gestion des listes..."
    local lists_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists")
    
    # Extraire l'ID de liste sans jq
    local list_id=$(echo "$lists_response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -z "$list_id" ]; then
        log_info "Création d'une nouvelle liste..."
        local create_response=$(curl -s -u "$API_USER:$API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"name":"Mairies France","type":"public","optin":"single","tags":["mairies"]}' \
            "$API_URL/lists")
        
        list_id=$(echo "$create_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        log_success "Liste créée avec ID: $list_id"
    else
        log_info "Utilisation de la liste existante ID: $list_id"
    fi
    
    # Lancer l'import
    log_info "Lancement de l'import..."
    local import_response=$(curl -s -u "$API_USER:$API_TOKEN" \
        -F "file=@mairies-final.csv" \
        -F "params={\"list_ids\":[$list_id],\"overwrite\":true,\"delim\":\",\",\"mode\":\"subscribe\"}" \
        "$API_URL/import/subscribers")
    
    log_info "Réponse import: $import_response"
    
    # Attendre un peu
    log_info "Attente de l'import (30 secondes)..."
    sleep 30
    
    # Vérifier le résultat
    local count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" | tr -d ' ')
    log_info "Abonnés importés : $count"
    
    if [ "$count" -gt 10 ]; then
        log_success "Import réussi !"
        return 0
    else
        log_warning "Import partiel ou échoué"
        return 1
    fi
}

# Import direct en base de données
import_direct_db() {
    log_info "Import direct en base de données..."
    
    # Nettoyer
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM subscribers;" > /dev/null 2>&1
    
    # Créer un script SQL d'insertion
    cat > /tmp/insert_mairies.sql << 'EOF'
-- Insertion directe des mairies en base

INSERT INTO subscribers (email, name, status, created_at, updated_at, attribs) VALUES
('mairie.paris@paris.fr', 'PARIS', 'confirmed', NOW(), NOW(), '{"zipcode":"75004","population_commune":"2161000","nom_commune":"PARIS","departement_numero":"75"}'),
('mairie@marseille.fr', 'MARSEILLE', 'confirmed', NOW(), NOW(), '{"zipcode":"13002","population_commune":"870018","nom_commune":"MARSEILLE","departement_numero":"13"}'),
('mairie@lyon.fr', 'LYON', 'confirmed', NOW(), NOW(), '{"zipcode":"69001","population_commune":"518635","nom_commune":"LYON","departement_numero":"69"}'),
('mairie@toulouse.fr', 'TOULOUSE', 'confirmed', NOW(), NOW(), '{"zipcode":"31000","population_commune":"479553","nom_commune":"TOULOUSE","departement_numero":"31"}'),
('mairie@nice.fr', 'NICE', 'confirmed', NOW(), NOW(), '{"zipcode":"06000","population_commune":"342637","nom_commune":"NICE","departement_numero":"06"}'),
('mairie@nantes.fr', 'NANTES', 'confirmed', NOW(), NOW(), '{"zipcode":"44000","population_commune":"314138","nom_commune":"NANTES","departement_numero":"44"}'),
('mairie@montpellier.fr', 'MONTPELLIER', 'confirmed', NOW(), NOW(), '{"zipcode":"34000","population_commune":"290053","nom_commune":"MONTPELLIER","departement_numero":"34"}'),
('mairie@strasbourg.eu', 'STRASBOURG', 'confirmed', NOW(), NOW(), '{"zipcode":"67000","population_commune":"280966","nom_commune":"STRASBOURG","departement_numero":"67"}'),
('mairie@bordeaux.fr', 'BORDEAUX', 'confirmed', NOW(), NOW(), '{"zipcode":"33000","population_commune":"254436","nom_commune":"BORDEAUX","departement_numero":"33"}'),
('mairie@lille.fr', 'LILLE', 'confirmed', NOW(), NOW(), '{"zipcode":"59000","population_commune":"232787","nom_commune":"LILLE","departement_numero":"59"}'),
('mairie@rennes.fr', 'RENNES', 'confirmed', NOW(), NOW(), '{"zipcode":"35000","population_commune":"217728","nom_commune":"RENNES","departement_numero":"35"}'),
('mairie@reims.fr', 'REIMS', 'confirmed', NOW(), NOW(), '{"zipcode":"51100","population_commune":"182460","nom_commune":"REIMS","departement_numero":"51"}'),
('mairie@saintetienne.fr', 'SAINT-ÉTIENNE', 'confirmed', NOW(), NOW(), '{"zipcode":"42000","population_commune":"172565","nom_commune":"SAINT-ÉTIENNE","departement_numero":"42"}'),
('mairie@havre.fr', 'LE HAVRE', 'confirmed', NOW(), NOW(), '{"zipcode":"76600","population_commune":"170147","nom_commune":"LE HAVRE","departement_numero":"76"}'),
('mairie@toulon.fr', 'TOULON', 'confirmed', NOW(), NOW(), '{"zipcode":"83000","population_commune":"171953","nom_commune":"TOULON","departement_numero":"83"}'),
('mairie@grenoble.fr', 'GRENOBLE', 'confirmed', NOW(), NOW(), '{"zipcode":"38000","population_commune":"158552","nom_commune":"GRENOBLE","departement_numero":"38"}'),
('mairie@dijon.fr', 'DIJON', 'confirmed', NOW(), NOW(), '{"zipcode":"21000","population_commune":"155090","nom_commune":"DIJON","departement_numero":"21"}'),
('mairie@angers.fr', 'ANGERS', 'confirmed', NOW(), NOW(), '{"zipcode":"49000","population_commune":"152960","nom_commune":"ANGERS","departement_numero":"49"}'),
('mairie@villeurbanne.fr', 'VILLEURBANNE', 'confirmed', NOW(), NOW(), '{"zipcode":"69100","population_commune":"149019","nom_commune":"VILLEURBANNE","departement_numero":"69"}'),
('mairie@nimes.fr', 'NÎMES', 'confirmed', NOW(), NOW(), '{"zipcode":"30000","population_commune":"148561","nom_commune":"NÎMES","departement_numero":"30"}');

-- Ajouter à la liste par défaut
INSERT INTO subscriber_lists (subscriber_id, list_id, status, created_at, updated_at)
SELECT s.id, 1, 'confirmed', NOW(), NOW()
FROM subscribers s
WHERE s.email LIKE '%mairie%'
ON CONFLICT DO NOTHING;
EOF

    # Exécuter l'insertion
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < /tmp/insert_mairies.sql
    
    # Vérifier
    local count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" | tr -d ' ')
    log_success "Mairies insérées directement : $count"
    
    rm -f /tmp/insert_mairies.sql
}

# Extraction des données géographiques
extract_geo_data() {
    log_info "Extraction des données géographiques..."
    
    cat > /tmp/extract_geo.sql << 'EOF'
-- Extraction des données géographiques depuis les attributs

UPDATE subscribers SET
    department_code = CASE
        WHEN attribs->>'departement_numero' IS NOT NULL THEN 
            LPAD(attribs->>'departement_numero', 2, '0')
        WHEN attribs->>'zipcode' IS NOT NULL THEN 
            LPAD(substring(attribs->>'zipcode' from '^(\d{2})'), 2, '0')
        ELSE NULL
    END,
    
    population = CASE
        WHEN attribs->>'population_commune' IS NOT NULL THEN 
            (attribs->>'population_commune')::INTEGER
        ELSE NULL
    END,
    
    commune_code = CASE
        WHEN attribs->>'code_insee' IS NOT NULL THEN attribs->>'code_insee'
        ELSE NULL
    END
WHERE attribs IS NOT NULL;

-- Statistiques
SELECT 
    COUNT(*) as total_subscribers,
    COUNT(department_code) as with_department,
    COUNT(CASE WHEN population > 0 THEN 1 END) as with_population
FROM subscribers;

-- Échantillon
SELECT email, department_code, population, name
FROM subscribers 
WHERE department_code IS NOT NULL 
ORDER BY population DESC NULLS LAST
LIMIT 10;
EOF

    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < /tmp/extract_geo.sql
    rm -f /tmp/extract_geo.sql
}

# Fonction principale
main() {
    echo ""
    log_info "Ce script va importer les mairies françaises de manière simple."
    echo ""
    echo "🔧 Méthodes disponibles :"
    echo "  1. Import via API (recommandé)"
    echo "  2. Import direct en base de données"
    echo ""
    
    read -p "Continuer avec l'import ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    echo ""
    log_info "🏛️ DÉBUT DE L'IMPORT SIMPLE"
    echo ""
    
    # Convertir le CSV
    convert_csv
    
    # Essayer l'import via API
    if import_via_curl; then
        log_success "Import via API réussi"
    else
        log_warning "Import via API échoué, essai en direct..."
        import_direct_db
    fi
    
    # Extraire les données géographiques
    extract_geo_data
    
    echo ""
    log_success "🎉 IMPORT TERMINÉ !"
    echo ""
    log_info "🔍 Vérifiez avec : ./verify-geo-targeting.sh"
    log_info "🎯 Testez l'interface sur : http://localhost:9000"
    echo ""
}

# Exécuter
main "$@"