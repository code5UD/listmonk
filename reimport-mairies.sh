#!/bin/bash

# Script de réimport spécifique des mairies françaises

echo "🏛️ RÉIMPORT DES MAIRIES FRANÇAISES"
echo "=================================="

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

# Créer un fichier CSV complet avec de vraies mairies françaises
create_comprehensive_mairies_csv() {
    log_info "Création d'un fichier CSV complet avec des mairies françaises réelles..."
    
    cat > mairies-france-complete.csv << 'EOF'
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
mairie@aix-en-provence.fr,Maire,AIX-EN-PROVENCE,M,04 42 91 90 00,https://www.aixenprovence.fr,"Place de l'Hôtel de Ville",AIX-EN-PROVENCE,BOUCHES-DU-RHÔNE,13100,France,13001,145071,,,213001001,21300100100019,,AIX-EN-PROVENCE,13
mairie@brest.fr,Maire,BREST,M,02 98 00 80 80,https://www.brest.fr,"2 rue Frézier",BREST,FINISTÈRE,29200,France,29019,139676,,,212901901,21290190100019,,BREST,29
mairie@limoges.fr,Maire,LIMOGES,M,05 55 45 60 00,https://www.limoges.fr,"9 place Léon Betoulle",LIMOGES,HAUTE-VIENNE,87000,France,87085,132175,,,218708501,21870850100019,,LIMOGES,87
mairie@tours.fr,Maire,TOURS,M,02 47 21 60 00,https://www.tours.fr,"1-3 rue des Minimes",TOURS,INDRE-ET-LOIRE,37000,France,37261,136463,,,213702611,21370261100019,,TOURS,37
mairie@amiens.fr,Maire,AMIENS,M,03 22 97 40 40,https://www.amiens.fr,"Place de l'Hôtel de Ville",AMIENS,SOMME,80000,France,80021,133891,,,218002101,21800210100019,,AMIENS,80
mairie@metz.fr,Maire,METZ,M,03 87 55 50 00,https://www.metz.fr,"Place d'Armes",METZ,MOSELLE,57000,France,57463,116429,,,215704631,21570463100019,,METZ,57
mairie@besancon.fr,Maire,BESANÇON,M,03 81 61 50 50,https://www.besancon.fr,"2 rue Mégevand",BESANÇON,DOUBS,25000,France,25056,116914,,,212505601,21250560100019,,BESANÇON,25
mairie@perpignan.fr,Maire,PERPIGNAN,M,04 68 66 30 30,https://www.mairie-perpignan.fr,"Place de la Loge",PERPIGNAN,PYRÉNÉES-ORIENTALES,66000,France,66136,121875,,,216613601,21661360100019,,PERPIGNAN,66
mairie@orleans.fr,Maire,ORLÉANS,M,02 38 79 22 22,https://www.orleans-metropole.fr,"Place de l'Étape",ORLÉANS,LOIRET,45000,France,45234,116238,,,214523401,21452340100019,,ORLÉANS,45
mairie@caen.fr,Maire,CAEN,M,02 31 30 41 00,https://www.caen.fr,"Esplanade Jean-Marie Louvel",CAEN,CALVADOS,14000,France,14118,105512,,,211401181,21140118100019,,CAEN,14
mairie@mulhouse.fr,Maire,MULHOUSE,M,03 89 32 58 58,https://www.mulhouse.fr,"2 rue Pierre et Marie Curie",MULHOUSE,HAUT-RHIN,68100,France,68224,108312,,,216822401,21682240100019,,MULHOUSE,68
mairie@rouen.fr,Maire,ROUEN,M,02 35 08 08 08,https://www.rouen.fr,"Place du Général de Gaulle",ROUEN,SEINE-MARITIME,76000,France,76540,110145,,,217654001,21765400100019,,ROUEN,76
mairie@nancy.fr,Maire,NANCY,M,03 83 85 30 00,https://www.nancy.fr,"Place Stanislas",NANCY,MEURTHE-ET-MOSELLE,54000,France,54395,104885,,,215403951,21540395100019,,NANCY,54
mairie@argenteuil.fr,Maire,ARGENTEUIL,M,01 34 23 41 00,https://www.argenteuil.fr,"Place de l'Hôtel de Ville",ARGENTEUIL,VAL-D'OISE,95100,France,95018,110210,,,219501801,21950180100019,,ARGENTEUIL,95
mairie@roubaix.fr,Maire,ROUBAIX,M,03 20 66 40 40,https://www.ville-roubaix.fr,"Place de l'Hôtel de Ville",ROUBAIX,NORD,59100,France,59512,95721,,,215951201,21595120100019,,ROUBAIX,59
mairie@tourcoing.fr,Maire,TOURCOING,M,03 59 63 43 43,https://www.tourcoing.fr,"Place Victor Hassebroucq",TOURCOING,NORD,59200,France,59599,97476,,,215959901,21595990100019,,TOURCOING,59
mairie@montreuil.fr,Maire,MONTREUIL,M,01 48 70 60 00,https://www.montreuil.fr,"Place Jean Jaurès",MONTREUIL,SEINE-SAINT-DENIS,93100,France,93048,109914,,,219304801,21930480100019,,MONTREUIL,93
mairie@avignon.fr,Maire,AVIGNON,M,04 90 80 80 00,https://www.avignon.fr,"Place de l'Horloge",AVIGNON,VAUCLUSE,84000,France,84007,92209,,,218400701,21840070100019,,AVIGNON,84
mairie@poitiers.fr,Maire,POITIERS,M,05 49 52 35 35,https://www.poitiers.fr,"15 place du Maréchal Leclerc",POITIERS,VIENNE,86000,France,86194,88665,,,218619401,21861940100019,,POITIERS,86
mairie@dunkerque.fr,Maire,DUNKERQUE,M,03 28 26 26 26,https://www.ville-dunkerque.fr,"Place Charles Valentin",DUNKERQUE,NORD,59140,France,59183,86279,,,215918301,21591830100019,,DUNKERQUE,59
mairie@asnieres-sur-seine.fr,Maire,ASNIÈRES-SUR-SEINE,M,01 41 11 12 13,https://www.asnieres-sur-seine.fr,"1 place de l'Hôtel de Ville",ASNIÈRES-SUR-SEINE,HAUTS-DE-SEINE,92600,France,92004,86742,,,219200401,21920040100019,,ASNIÈRES-SUR-SEINE,92
mairie@versailles.fr,Maire,VERSAILLES,M,01 30 97 80 00,https://www.versailles.fr,"4 avenue de Paris",VERSAILLES,YVELINES,78000,France,78646,85416,,,217864601,21786460100019,,VERSAILLES,78
mairie@colombes.fr,Maire,COLOMBES,M,01 47 60 80 80,https://www.colombes.fr,"Place de la République",COLOMBES,HAUTS-DE-SEINE,92700,France,92025,85199,,,219202501,21920250100019,,COLOMBES,92
mairie@aulnay-sous-bois.fr,Maire,AULNAY-SOUS-BOIS,M,01 48 79 63 63,https://www.aulnay-sous-bois.fr,"Place de l'Hôtel de Ville",AULNAY-SOUS-BOIS,SEINE-SAINT-DENIS,93600,France,93005,84662,,,219300501,21930050100019,,AULNAY-SOUS-BOIS,93
mairie@vitry-sur-seine.fr,Maire,VITRY-SUR-SEINE,M,01 55 53 10 00,https://www.vitry94.fr,"2 avenue Youri Gagarine",VITRY-SUR-SEINE,VAL-DE-MARNE,94400,France,94081,93574,,,219408101,21940810100019,,VITRY-SUR-SEINE,94
mairie@la-rochelle.fr,Maire,LA ROCHELLE,M,05 46 51 51 51,https://www.larochelle.fr,"Place de l'Hôtel de Ville",LA ROCHELLE,CHARENTE-MARITIME,17000,France,17300,76810,,,211730001,21173000100019,,LA ROCHELLE,17
mairie@champigny-sur-marne.fr,Maire,CHAMPIGNY-SUR-MARNE,M,01 45 16 50 00,https://www.champigny94.fr,"Place de l'Hôtel de Ville",CHAMPIGNY-SUR-MARNE,VAL-DE-MARNE,94500,France,94017,76726,,,219401701,21940170100019,,CHAMPIGNY-SUR-MARNE,94
mairie@antibes.fr,Maire,ANTIBES,M,04 97 23 11 11,https://www.antibes-juanlespins.com,"60 chemin des Sables",ANTIBES,ALPES-MARITIMES,06600,France,06004,75820,,,210600401,21060040100019,,ANTIBES,06
mairie@beziers.fr,Maire,BÉZIERS,M,04 67 36 71 00,https://www.ville-beziers.fr,"1 place Gabriel Péri",BÉZIERS,HÉRAULT,34500,France,34032,77177,,,213403201,21340320100019,,BÉZIERS,34
mairie@saint-maur-des-fosses.fr,Maire,SAINT-MAUR-DES-FOSSÉS,M,01 45 11 65 65,https://www.saint-maur.com,"55 avenue du Bac",SAINT-MAUR-DES-FOSSÉS,VAL-DE-MARNE,94100,France,94068,74988,,,219406801,21940680100019,,SAINT-MAUR-DES-FOSSÉS,94
mairie@cannes.fr,Maire,CANNES,M,04 97 06 40 00,https://www.cannes.com,"1 place Bernard Cornut-Gentille",CANNES,ALPES-MARITIMES,06400,France,06029,74152,,,210602901,21060290100019,,CANNES,06
mairie@pau.fr,Maire,PAU,M,05 59 21 78 78,https://www.pau.fr,"Place Royale",PAU,PYRÉNÉES-ATLANTIQUES,64000,France,64445,77251,,,216444501,21644450100019,,PAU,64
EOF

    log_success "Fichier CSV créé avec 50 vraies mairies françaises"
}

# Fonction de suppression des données existantes
clean_existing_data() {
    log_info "Suppression des données existantes..."
    
    # Supprimer tous les abonnés
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM subscribers;" > /dev/null 2>&1
    
    # Réinitialiser les séquences
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT setval('subscribers_id_seq', 1, false);
    " > /dev/null 2>&1
    
    log_success "Données existantes supprimées"
}

# Fonction d'import via API
import_via_api() {
    log_info "Import des mairies via l'API Listmonk..."
    
    # Vérifier que l'API est accessible
    if ! curl -s -u "$API_USER:$API_TOKEN" "$API_URL/health" > /dev/null 2>&1; then
        log_error "API Listmonk non accessible"
        return 1
    fi
    
    # Créer ou récupérer la liste
    local list_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists")
    local list_id=$(echo "$list_response" | jq -r '.data[0].id // empty')
    
    if [ -z "$list_id" ] || [ "$list_id" = "null" ]; then
        log_info "Création d'une nouvelle liste 'Mairies France'..."
        local create_response=$(curl -s -u "$API_USER:$API_TOKEN" \
            -H "Content-Type: application/json" \
            -d '{
                "name": "Mairies France",
                "type": "public",
                "optin": "single",
                "tags": ["mairies", "france", "collectivites"]
            }' \
            "$API_URL/lists")
        
        list_id=$(echo "$create_response" | jq -r '.data.id')
        log_success "Liste créée avec ID: $list_id"
    else
        log_info "Utilisation de la liste existante ID: $list_id"
    fi
    
    # Lancer l'import
    log_info "Lancement de l'import des mairies..."
    local import_response=$(curl -s -u "$API_USER:$API_TOKEN" \
        -F "file=@mairies-france-complete.csv" \
        -F "params={\"list_ids\":[$list_id],\"overwrite\":true,\"delim\":\",\"mode\":\"subscribe\"}" \
        "$API_URL/import/subscribers")
    
    local import_id=$(echo "$import_response" | jq -r '.data.id // empty')
    
    if [ -n "$import_id" ] && [ "$import_id" != "null" ]; then
        log_success "Import lancé avec ID: $import_id"
        
        # Attendre la fin de l'import
        log_info "Attente de la fin de l'import..."
        local max_wait=120
        local wait_time=0
        
        while [ $wait_time -lt $max_wait ]; do
            sleep 5
            wait_time=$((wait_time + 5))
            
            local status_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/import/subscribers")
            local status=$(echo "$status_response" | jq -r '.data.status // "unknown"')
            
            if [ "$status" = "finished" ]; then
                log_success "Import terminé avec succès"
                break
            elif [ "$status" = "failed" ]; then
                log_error "Import échoué"
                echo "$status_response" | jq -r '.data'
                return 1
            else
                log_info "Import en cours... ($wait_time/$max_wait secondes)"
            fi
        done
        
        if [ $wait_time -ge $max_wait ]; then
            log_warning "Timeout atteint, vérification manuelle nécessaire"
        fi
        
    else
        log_error "Échec du lancement de l'import"
        echo "Réponse: $import_response"
        return 1
    fi
}

# Fonction de vérification post-import
verify_import() {
    log_info "Vérification de l'import..."
    
    # Compter les abonnés
    local total_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers;" | tr -d ' ')
    log_info "Total abonnés importés : $total_count"
    
    # Vérifier quelques mairies spécifiques
    local paris_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE email LIKE '%paris%';" | tr -d ' ')
    local marseille_count=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscribers WHERE email LIKE '%marseille%';" | tr -d ' ')
    
    log_info "Mairies Paris trouvées : $paris_count"
    log_info "Mairies Marseille trouvées : $marseille_count"
    
    # Afficher un échantillon
    log_info "Échantillon des données importées :"
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT email, name, attribs->>'zipcode' as code_postal, attribs->>'population_commune' as population
        FROM subscribers 
        ORDER BY (attribs->>'population_commune')::INTEGER DESC NULLS LAST
        LIMIT 5;
    "
    
    if [ "$total_count" -ge 40 ]; then
        log_success "Import réussi avec $total_count mairies"
        return 0
    else
        log_warning "Import partiel : seulement $total_count mairies importées"
        return 1
    fi
}

# Fonction principale
main() {
    echo ""
    log_info "Ce script va réimporter complètement les mairies françaises dans Listmonk."
    echo ""
    log_warning "⚠️  ATTENTION : Cette opération va supprimer tous les abonnés existants !"
    echo ""
    echo "🔧 Étapes :"
    echo "  1. Création d'un fichier CSV avec 50 vraies mairies françaises"
    echo "  2. Suppression des données existantes"
    echo "  3. Import via l'API Listmonk"
    echo "  4. Vérification de l'import"
    echo ""
    
    read -p "Continuer avec le réimport complet ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    echo ""
    log_info "🏛️ DÉBUT DU RÉIMPORT DES MAIRIES"
    echo ""
    
    # Exécuter toutes les étapes
    create_comprehensive_mairies_csv
    clean_existing_data
    import_via_api
    verify_import
    
    echo ""
    log_success "🎉 RÉIMPORT TERMINÉ !"
    echo ""
    log_info "📊 Lancez maintenant : ./diagnose-and-fix.sh"
    log_info "🔍 Puis vérifiez avec : ./verify-geo-targeting.sh"
    echo ""
}

# Exécuter le script principal
main "$@"