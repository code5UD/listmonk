#!/bin/bash

# Script d'intégration final des mairies pour déploiement Docker Listmonk
# Version corrigée avec le bon format CSV

set -e

echo "🇫🇷 Intégration des mairies dans Listmonk Docker (Version finale)"
echo "================================================================="

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

# Identifiants selon la documentation officielle
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"

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

# Tester l'authentification
test_auth() {
    log_info "Test de l'authentification..."
    
    auth_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists")
    
    if echo "$auth_response" | grep -q '"data"'; then
        log_success "✅ Authentification réussie"
        return 0
    else
        log_error "❌ Authentification échouée: $auth_response"
        return 1
    fi
}

# Corriger le format CSV
fix_csv_format() {
    log_info "Correction du format CSV..."
    
    # Vérifier si le fichier source existe
    if [ ! -f "mairielist-converted.csv" ]; then
        log_error "Fichier mairielist-converted.csv non trouvé"
        exit 1
    fi
    
    # Vérifier le format actuel
    first_line=$(head -1 mairielist-converted.csv)
    log_info "Format actuel : $first_line"
    
    # Si le fichier utilise des points-virgules, le convertir
    if echo "$first_line" | grep -q ";"; then
        log_info "Conversion des points-virgules en virgules..."
        
        # Créer une sauvegarde
        cp mairielist-converted.csv mairielist-converted.csv.backup
        
        # Convertir les points-virgules en virgules
        sed 's/;/,/g' mairielist-converted.csv.backup > mairielist-converted.csv
        
        log_success "Format CSV corrigé"
        log_info "Nouveau format : $(head -1 mairielist-converted.csv)"
    else
        log_success "Format CSV déjà correct"
    fi
    
    # Vérifier que la colonne email existe
    if head -1 mairielist-converted.csv | grep -q "email"; then
        log_success "Colonne 'email' trouvée"
    else
        log_error "Colonne 'email' non trouvée dans l'en-tête"
        exit 1
    fi
}

# Importer les données via l'API
import_data_via_api() {
    log_info "Import des données des mairies via l'API..."
    
    # Paramètres JSON selon la documentation officielle
    # Utilisation de virgule comme délimiteur
    import_params='{"mode":"subscribe", "subscription_status":"confirmed", "delim":",", "lists":[], "overwrite": true}'
    
    log_info "📤 Import du fichier CSV avec les paramètres : $import_params"
    
    # Lancer l'import
    import_response=$(curl -s -u "$API_USER:$API_TOKEN" -X POST \
        -F "params=$import_params" \
        -F "file=@mairielist-converted.csv" \
        "$API_URL/import/subscribers")
    
    if [ $? -eq 0 ]; then
        log_info "Réponse de l'import : $import_response"
        
        # Vérifier la réponse selon la structure officielle
        if echo "$import_response" | grep -q '"data"'; then
            log_success "Import du CSV lancé avec succès"
            
            # Attendre que l'import se termine
            log_info "⏳ Attente de la fin de l'import..."
            sleep 5
            
            # Vérifier le statut de l'import
            for i in {1..30}; do
                status_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/import/subscribers")
                
                log_info "Statut import (tentative $i): $status_response"
                
                if echo "$status_response" | grep -q '"status":"finished"'; then
                    log_success "Import terminé avec succès"
                    
                    # Extraire les statistiques
                    total=$(echo "$status_response" | grep -o '"total":[0-9]*' | cut -d: -f2)
                    imported=$(echo "$status_response" | grep -o '"imported":[0-9]*' | cut -d: -f2)
                    
                    log_success "Total traité : $total"
                    log_success "Enregistrements importés : $imported"
                    break
                elif echo "$status_response" | grep -q '"status":"failed"'; then
                    log_error "L'import a échoué"
                    
                    # Récupérer les logs d'erreur
                    log_info "Récupération des logs d'erreur..."
                    logs_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/import/subscribers/logs")
                    echo "Logs d'erreur : $logs_response"
                    return 1
                elif echo "$status_response" | grep -q '"status":"running"' || echo "$status_response" | grep -q '"status":"importing"'; then
                    log_info "Import en cours... (tentative $i/30)"
                    sleep 10
                else
                    log_info "Statut inconnu, vérification... (tentative $i/30)"
                    sleep 5
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
    subscribers_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/subscribers?per_page=1")
    
    if [ $? -eq 0 ]; then
        # Extraire le nombre total d'abonnés
        total=$(echo "$subscribers_response" | grep -o '"total":[0-9]*' | cut -d: -f2)
        
        if [ -n "$total" ] && [ "$total" -gt 0 ]; then
            log_success "Total des abonnés : $total"
            
            if [ "$total" -gt 10000 ]; then
                log_success "🎉 Intégration réussie ! Plus de 10 000 abonnés trouvés"
            elif [ "$total" -gt 1000 ]; then
                log_success "✅ Intégration réussie ! Plus de 1 000 abonnés trouvés"
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
    recent_response=$(curl -s -u "$API_USER:$API_TOKEN" "$API_URL/subscribers?order_by=created_at&order=desc&per_page=5")
    if [ $? -eq 0 ] && echo "$recent_response" | grep -q '"email"'; then
        log_info "Derniers abonnés importés :"
        echo "$recent_response" | grep -o '"email":"[^"]*"' | head -5 | sed 's/"email":"//g' | sed 's/"//g' | sed 's/^/   - /'
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
    echo "👤 Utilisateur API : $API_USER"
    echo "🔑 Token API : $API_TOKEN"
    echo ""
    echo "📋 Fonctionnalités disponibles :"
    echo "   ✅ Import automatique des mairies françaises"
    echo "   ✅ Gestion des abonnés via API"
    echo "   ✅ Interface de gestion des campagnes"
    echo ""
    echo "🚀 Prochaines étapes :"
    echo "   1. Ouvrez $LISTMONK_URL dans votre navigateur"
    echo "   2. Connectez-vous avec votre compte"
    echo "   3. Allez dans 'Subscribers' pour voir les mairies importées"
    echo "   4. Créez votre première campagne"
    echo ""
    echo "🔧 Commandes API utiles :"
    echo "   curl -u \"$API_USER:$API_TOKEN\" $API_URL/subscribers"
    echo "   curl -u \"$API_USER:$API_TOKEN\" $API_URL/lists"
    echo ""
}

# Fonction principale
main() {
    echo "Ce script va intégrer les données des mairies françaises"
    echo "dans votre installation Docker de Listmonk existante."
    echo ""
    echo "🔑 Utilisation des identifiants :"
    echo "   Utilisateur : $API_USER"
    echo "   Token : $API_TOKEN"
    echo ""
    echo "Étapes :"
    echo "  1. Vérifier l'environnement Docker"
    echo "  2. Tester l'authentification"
    echo "  3. Corriger le format CSV"
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
    
    if ! test_auth; then
        log_error "Impossible de s'authentifier. Arrêt du script."
        exit 1
    fi
    
    fix_csv_format
    import_data_via_api
    verify_integration
    show_final_info
}

# Exécuter le script principal
main "$@"