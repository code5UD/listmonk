#!/bin/bash

# Script d'intégration des mairies pour déploiement Docker Listmonk
# Version avec clé API

set -e

echo "🇫🇷 Intégration des mairies dans Listmonk Docker (Clé API)"
echo "=========================================================="

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage coloré
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration Docker
CONTAINER_NAME="listmonk_mairies_app"
DB_CONTAINER="listmonk_mairies_db"
LISTMONK_URL="http://localhost:9000"
API_URL="${LISTMONK_URL}/api"

# Clé API
API_KEY="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"

# Vérifier que Docker fonctionne
check_docker() {
    log_info "Vérification de Docker..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        exit 1
    fi
    
    if ! docker ps &> /dev/null; then
        log_error "Docker n'est pas accessible. Vérifiez les permissions."
        exit 1
    fi
    
    log_success "Docker accessible"
}

# Vérifier les conteneurs
check_containers() {
    log_info "Vérification des conteneurs Listmonk..."
    
    # Vérifier le conteneur principal
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "Conteneur Listmonk '$CONTAINER_NAME' non trouvé ou arrêté"
        log_info "Conteneurs en cours d'exécution :"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        exit 1
    fi
    
    # Vérifier le conteneur de base de données
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        log_error "Conteneur de base de données '$DB_CONTAINER' non trouvé ou arrêté"
        exit 1
    fi
    
    log_success "Conteneurs Listmonk trouvés et en cours d'exécution"
}

# Vérifier l'accès à Listmonk
check_listmonk_access() {
    log_info "Vérification de l'accès à Listmonk..."
    
    local max_attempts=30
    for attempt in $(seq 1 $max_attempts); do
        if curl -s "$LISTMONK_URL/api/health" > /dev/null 2>&1; then
            log_success "Listmonk accessible sur $LISTMONK_URL"
            return 0
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            log_error "Impossible d'accéder à Listmonk après $max_attempts tentatives"
            log_info "Vérifiez que le conteneur est en bonne santé :"
            docker ps | grep "$CONTAINER_NAME"
            log_info "Logs du conteneur :"
            docker logs --tail 20 "$CONTAINER_NAME"
            exit 1
        fi
        
        log_info "Tentative $attempt/$max_attempts - Attente de Listmonk..."
        sleep 2
    done
}

# Tester l'authentification avec clé API
test_api_key() {
    log_info "Test de l'authentification avec clé API..."
    
    # Test avec clé API dans l'en-tête Authorization
    auth_response=$(curl -s -H "Authorization: Bearer $API_KEY" "$API_URL/subscribers?per_page=1")
    
    if echo "$auth_response" | grep -q '"data"'; then
        log_success "Authentification avec clé API réussie (Bearer)"
        AUTH_HEADER="Authorization: Bearer $API_KEY"
        return 0
    fi
    
    # Test avec clé API dans l'en-tête X-API-Key
    auth_response=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/subscribers?per_page=1")
    
    if echo "$auth_response" | grep -q '"data"'; then
        log_success "Authentification avec clé API réussie (X-API-Key)"
        AUTH_HEADER="X-API-Key: $API_KEY"
        return 0
    fi
    
    # Test avec clé API en paramètre
    auth_response=$(curl -s "$API_URL/subscribers?per_page=1&api_key=$API_KEY")
    
    if echo "$auth_response" | grep -q '"data"'; then
        log_success "Authentification avec clé API réussie (paramètre)"
        AUTH_PARAM="api_key=$API_KEY"
        return 0
    fi
    
    log_error "Impossible de s'authentifier avec la clé API"
    log_info "Réponse d'erreur : $auth_response"
    return 1
}

# Préparer le fichier CSV
prepare_csv() {
    log_info "Préparation du fichier CSV des mairies..."
    
    # Vérifier si le fichier source existe
    if [ ! -f "mairielist.csv" ]; then
        log_error "Fichier mairielist.csv non trouvé"
        log_info "Veuillez placer le fichier des mairies dans ce répertoire"
        exit 1
    fi
    
    # Nettoyer et convertir le CSV
    if [ ! -f "mairielist-converted.csv" ] || [ "mairielist.csv" -nt "mairielist-converted.csv" ]; then
        log_info "Conversion du fichier CSV..."
        if python3 scripts/fix-and-convert-csv.py; then
            log_success "Fichier CSV converti"
        else
            log_error "Échec de la conversion du CSV"
            exit 1
        fi
    else
        log_success "Fichier CSV déjà converti et à jour"
    fi
}

# Importer les données via l'API
import_data_via_api() {
    log_info "Import des données des mairies via l'API..."
    
    # Construire la commande curl avec la clé API
    if [ -n "$AUTH_HEADER" ]; then
        auth_param="-H \"$AUTH_HEADER\""
        log_info "🔐 Utilisation de la clé API dans l'en-tête"
    elif [ -n "$AUTH_PARAM" ]; then
        auth_param=""
        log_info "🔐 Utilisation de la clé API en paramètre"
    else
        log_error "Aucune méthode d'authentification configurée"
        return 1
    fi
    
    # Import du fichier CSV via l'API standard de Listmonk
    log_info "📤 Import du fichier CSV via l'API subscribers..."
    
    # Construire l'URL avec paramètre si nécessaire
    if [ -n "$AUTH_PARAM" ]; then
        import_url="$API_URL/import/subscribers?$AUTH_PARAM"
    else
        import_url="$API_URL/import/subscribers"
    fi
    
    # Utiliser l'endpoint standard d'import de Listmonk
    if [ -n "$AUTH_HEADER" ]; then
        import_response=$(curl -s -H "$AUTH_HEADER" -X POST \
            -F "file=@mairielist-converted.csv" \
            -F "mode=subscribe" \
            -F "delim=," \
            -F "lists=[]" \
            "$import_url")
    else
        import_response=$(curl -s -X POST \
            -F "file=@mairielist-converted.csv" \
            -F "mode=subscribe" \
            -F "delim=," \
            -F "lists=[]" \
            "$import_url")
    fi
    
    if [ $? -eq 0 ]; then
        log_info "Réponse de l'import : $import_response"
        
        # Vérifier la réponse
        if echo "$import_response" | grep -q '"status":"success"' || echo "$import_response" | grep -q '"data"'; then
            log_success "Import du CSV lancé avec succès"
            
            # Attendre que l'import se termine
            log_info "⏳ Attente de la fin de l'import..."
            sleep 10
            
            # Vérifier le statut de l'import
            for i in {1..20}; do
                if [ -n "$AUTH_HEADER" ]; then
                    status_response=$(curl -s -H "$AUTH_HEADER" "$API_URL/import/subscribers")
                else
                    status_response=$(curl -s "$API_URL/import/subscribers?$AUTH_PARAM")
                fi
                
                if echo "$status_response" | grep -q '"status":"finished"'; then
                    log_success "Import terminé avec succès"
                    
                    # Extraire les statistiques si disponibles
                    if echo "$status_response" | grep -q '"imported"'; then
                        imported=$(echo "$status_response" | grep -o '"imported":[0-9]*' | cut -d: -f2)
                        log_success "Enregistrements importés : $imported"
                    fi
                    break
                elif echo "$status_response" | grep -q '"status":"failed"'; then
                    log_error "L'import a échoué"
                    echo "Réponse : $status_response"
                    return 1
                elif echo "$status_response" | grep -q '"status":"running"'; then
                    log_info "Import en cours... (tentative $i/20)"
                    sleep 15
                else
                    log_info "Statut inconnu, vérification... (tentative $i/20)"
                    sleep 10
                fi
            done
            
        else
            log_error "Échec du lancement de l'import"
            echo "Réponse : $import_response"
            return 1
        fi
    else
        log_error "Erreur lors de l'appel à l'API d'import"
        return 1
    fi
    
    log_success "Import des données terminé"
}

# Vérifier l'intégration
verify_integration() {
    log_info "Vérification de l'intégration..."
    
    # Vérifier les abonnés
    if [ -n "$AUTH_HEADER" ]; then
        subscribers_response=$(curl -s -H "$AUTH_HEADER" "$API_URL/subscribers?per_page=1")
    else
        subscribers_response=$(curl -s "$API_URL/subscribers?per_page=1&$AUTH_PARAM")
    fi
    
    if [ $? -eq 0 ]; then
        # Extraire le nombre total d'abonnés
        total=$(echo "$subscribers_response" | grep -o '"total":[0-9]*' | cut -d: -f2)
        
        if [ -n "$total" ] && [ "$total" -gt 0 ]; then
            log_success "Total des abonnés : $total"
            
            if [ "$total" -gt 1000 ]; then
                log_success "Intégration réussie ! Plus de 1000 abonnés trouvés"
            else
                log_warning "Seulement $total abonnés trouvés (attendu: 40000+)"
            fi
        else
            log_warning "Aucun abonné trouvé ou erreur dans la réponse"
            echo "Réponse API : $subscribers_response"
        fi
    else
        log_error "Erreur lors de la vérification des abonnés"
    fi
    
    # Vérifier quelques abonnés récents
    if [ -n "$AUTH_HEADER" ]; then
        recent_response=$(curl -s -H "$AUTH_HEADER" "$API_URL/subscribers?order_by=created_at&order=desc&per_page=3")
    else
        recent_response=$(curl -s "$API_URL/subscribers?order_by=created_at&order=desc&per_page=3&$AUTH_PARAM")
    fi
    
    if [ $? -eq 0 ] && echo "$recent_response" | grep -q '"email"'; then
        log_info "Derniers abonnés importés :"
        echo "$recent_response" | grep -o '"email":"[^"]*"' | head -3 | sed 's/"email":"//g' | sed 's/"//g' | sed 's/^/   - /'
    fi
    
    log_success "Vérification terminée"
}

# Afficher les informations finales
show_final_info() {
    echo ""
    echo "🎉 Intégration des mairies terminée !"
    echo "===================================="
    echo ""
    echo "🌐 Interface web : $LISTMONK_URL"
    echo "🔑 Clé API       : $API_KEY"
    echo ""
    echo "📋 Fonctionnalités disponibles :"
    echo "   ✅ Import automatique des mairies françaises"
    echo "   ✅ Ciblage géographique par département"
    echo "   ✅ Ciblage par nombre d'habitants"
    echo "   ✅ Interface de gestion des campagnes"
    echo ""
    echo "🚀 Prochaines étapes :"
    echo "   1. Ouvrez $LISTMONK_URL dans votre navigateur"
    echo "   2. Connectez-vous avec votre compte"
    echo "   3. Allez dans 'Subscribers' pour voir les mairies importées"
    echo "   4. Créez votre première campagne"
    echo ""
}

# Fonction principale
main() {
    echo "Ce script va intégrer les données des mairies françaises"
    echo "dans votre installation Docker de Listmonk existante."
    echo ""
    echo "🔑 Utilisation de la clé API : $API_KEY"
    echo ""
    echo "Étapes :"
    echo "  1. Vérifier l'environnement Docker"
    echo "  2. Tester l'authentification avec clé API"
    echo "  3. Préparer le fichier CSV des mairies"
    echo "  4. Importer les données via l'API"
    echo "  5. Vérifier l'intégration"
    echo ""
    
    # Demander confirmation
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi
    
    # Exécuter les étapes
    check_docker
    check_containers
    check_listmonk_access
    
    if ! test_api_key; then
        log_error "Impossible de s'authentifier avec la clé API. Arrêt du script."
        exit 1
    fi
    
    prepare_csv
    import_data_via_api
    verify_integration
    show_final_info
}

# Exécuter le script principal
main "$@"