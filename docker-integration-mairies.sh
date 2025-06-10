#!/bin/bash

# Script d'intégration des mairies pour déploiement Docker Listmonk
# Compatible avec votre configuration Docker existante

set -e

echo "🇫🇷 Intégration des mairies dans Listmonk Docker"
echo "================================================"

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

# Copier le fichier CSV dans le conteneur
copy_csv_to_container() {
    log_info "Copie du fichier CSV dans le conteneur..."
    
    # Copier le fichier dans le conteneur
    if docker cp mairielist-converted.csv "$CONTAINER_NAME:/tmp/mairies.csv"; then
        log_success "Fichier CSV copié dans le conteneur"
    else
        log_error "Échec de la copie du fichier CSV"
        exit 1
    fi
}

# Importer les données via l'API
import_data_via_api() {
    log_info "Import des données des mairies via l'API..."
    
    # Créer un script Python temporaire pour l'import
    cat > /tmp/import_mairies.py << 'EOF'
#!/usr/bin/env python3
import requests
import sys
import time

def import_mairies():
    base_url = "http://localhost:9000"
    api_url = f"{base_url}/api"
    
    # Authentification
    session = requests.Session()
    login_data = {"username": "admin", "password": "listmonk"}
    
    print("🔐 Authentification...")
    response = session.post(f"{api_url}/auth/login", json=login_data)
    if response.status_code != 200:
        print(f"❌ Échec de l'authentification: {response.status_code}")
        return False
    
    print("✅ Authentification réussie")
    
    # Import du fichier CSV
    print("📤 Import du fichier CSV...")
    try:
        with open('/tmp/mairies.csv', 'rb') as f:
            files = {'file': ('mairies.csv', f, 'text/csv')}
            data = {
                'create_subscribers': 'true',
                'update_existing': 'true'
            }
            
            response = session.post(
                f"{api_url}/geo/import",
                files=files,
                data=data,
                timeout=300
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Import réussi !")
                data = result.get('data', {})
                print(f"   - Enregistrements traités : {data.get('total_records', 'N/A')}")
                print(f"   - Enregistrements importés : {data.get('imported_records', 'N/A')}")
                print(f"   - Erreurs : {data.get('error_records', 'N/A')}")
                return True
            else:
                print(f"❌ Échec de l'import : {response.status_code}")
                print(f"   Réponse : {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ Erreur lors de l'import : {e}")
        return False

if __name__ == "__main__":
    if import_mairies():
        sys.exit(0)
    else:
        sys.exit(1)
EOF

    # Copier le script dans le conteneur et l'exécuter
    docker cp /tmp/import_mairies.py "$CONTAINER_NAME:/tmp/import_mairies.py"
    
    if docker exec "$CONTAINER_NAME" python3 /tmp/import_mairies.py; then
        log_success "Données des mairies importées avec succès"
    else
        log_error "Échec de l'import des données"
        return 1
    fi
    
    # Nettoyer les fichiers temporaires
    docker exec "$CONTAINER_NAME" rm -f /tmp/mairies.csv /tmp/import_mairies.py
    rm -f /tmp/import_mairies.py
}

# Vérifier l'intégration
verify_integration() {
    log_info "Vérification de l'intégration..."
    
    # Créer un script de vérification
    cat > /tmp/verify_integration.py << 'EOF'
#!/usr/bin/env python3
import requests
import sys

def verify():
    base_url = "http://localhost:9000"
    api_url = f"{base_url}/api"
    
    session = requests.Session()
    login_data = {"username": "admin", "password": "listmonk"}
    
    # Authentification
    response = session.post(f"{api_url}/auth/login", json=login_data)
    if response.status_code != 200:
        print("❌ Échec de l'authentification")
        return False
    
    # Vérifier les abonnés
    response = session.get(f"{api_url}/subscribers?per_page=1")
    if response.status_code == 200:
        data = response.json().get('data', {})
        total = data.get('total', 0)
        print(f"✅ Total des abonnés : {total}")
        
        if total > 0:
            print("✅ Intégration réussie !")
            return True
        else:
            print("⚠️  Aucun abonné trouvé")
            return False
    else:
        print(f"❌ Erreur lors de la vérification : {response.status_code}")
        return False

if __name__ == "__main__":
    if verify():
        sys.exit(0)
    else:
        sys.exit(1)
EOF

    # Exécuter la vérification
    docker cp /tmp/verify_integration.py "$CONTAINER_NAME:/tmp/verify_integration.py"
    
    if docker exec "$CONTAINER_NAME" python3 /tmp/verify_integration.py; then
        log_success "Vérification réussie"
    else
        log_warning "Problème lors de la vérification"
    fi
    
    # Nettoyer
    docker exec "$CONTAINER_NAME" rm -f /tmp/verify_integration.py
    rm -f /tmp/verify_integration.py
}

# Afficher les informations finales
show_final_info() {
    echo ""
    echo "🎉 Intégration des mairies terminée !"
    echo "===================================="
    echo ""
    echo "🌐 Interface web : $LISTMONK_URL"
    echo "👤 Utilisateur   : admin"
    echo "🔑 Mot de passe  : listmonk"
    echo ""
    echo "📋 Fonctionnalités disponibles :"
    echo "   ✅ Import automatique des mairies françaises"
    echo "   ✅ Ciblage géographique par département"
    echo "   ✅ Ciblage par nombre d'habitants"
    echo "   ✅ Interface de gestion des campagnes"
    echo ""
    echo "🚀 Prochaines étapes :"
    echo "   1. Ouvrez $LISTMONK_URL dans votre navigateur"
    echo "   2. Connectez-vous avec admin/listmonk"
    echo "   3. Allez dans 'Abonnés' pour voir les mairies importées"
    echo "   4. Créez votre première campagne"
    echo ""
    echo "🔧 Gestion Docker :"
    echo "   - Voir les logs : docker logs $CONTAINER_NAME"
    echo "   - Redémarrer : docker restart $CONTAINER_NAME"
    echo "   - Arrêter : docker stop $CONTAINER_NAME"
    echo ""
}

# Fonction principale
main() {
    echo "Ce script va intégrer les données des mairies françaises"
    echo "dans votre installation Docker de Listmonk existante."
    echo ""
    echo "Étapes :"
    echo "  1. Vérifier l'environnement Docker"
    echo "  2. Préparer le fichier CSV des mairies"
    echo "  3. Importer les données via l'API"
    echo "  4. Vérifier l'intégration"
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
    prepare_csv
    copy_csv_to_container
    import_data_via_api
    verify_integration
    show_final_info
}

# Exécuter le script principal
main "$@"