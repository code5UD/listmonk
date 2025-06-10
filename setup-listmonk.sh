#!/bin/bash

# Script de configuration complète de Listmonk avec les mairies françaises
# Ce script télécharge, compile et configure Listmonk automatiquement

set -e

echo "🇫🇷 Configuration complète de Listmonk avec les mairies françaises"
echo "=================================================================="

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

# Détecter l'architecture
detect_architecture() {
    local arch=$(uname -m)
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case $arch in
        x86_64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        *)
            log_error "Architecture non supportée: $arch"
            exit 1
            ;;
    esac
    
    echo "${os}_${arch}"
}

# Télécharger Listmonk
download_listmonk() {
    log_info "Téléchargement de Listmonk..."
    
    local arch_string=$(detect_architecture)
    local version="v3.0.0"  # Version stable
    local download_url="https://github.com/knadh/listmonk/releases/download/${version}/listmonk_${version}_${arch_string}.tar.gz"
    
    log_info "Architecture détectée: $arch_string"
    log_info "URL de téléchargement: $download_url"
    
    # Télécharger et extraire
    if curl -L -o listmonk.tar.gz "$download_url"; then
        tar -xzf listmonk.tar.gz
        chmod +x listmonk
        rm listmonk.tar.gz
        log_success "Listmonk téléchargé et extrait"
        return 0
    else
        log_error "Échec du téléchargement de Listmonk"
        return 1
    fi
}

# Compiler Listmonk depuis les sources (fallback)
compile_listmonk() {
    log_info "Compilation de Listmonk depuis les sources..."
    
    # Vérifier Go
    if ! command -v go &> /dev/null; then
        log_error "Go n'est pas installé. Installation de Go..."
        
        # Installer Go
        local go_version="1.21.5"
        local go_arch=$(uname -m)
        case $go_arch in
            x86_64) go_arch="amd64" ;;
            aarch64|arm64) go_arch="arm64" ;;
            armv7l) go_arch="armv6l" ;;
        esac
        
        wget "https://golang.org/dl/go${go_version}.linux-${go_arch}.tar.gz"
        sudo tar -C /usr/local -xzf "go${go_version}.linux-${go_arch}.tar.gz"
        export PATH=$PATH:/usr/local/go/bin
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        rm "go${go_version}.linux-${go_arch}.tar.gz"
    fi
    
    # Compiler
    if make build; then
        log_success "Listmonk compilé avec succès"
        return 0
    else
        log_error "Échec de la compilation"
        return 1
    fi
}

# Vérifier les prérequis système
check_system_requirements() {
    log_info "Vérification des prérequis système..."
    
    # Vérifier curl
    if ! command -v curl &> /dev/null; then
        log_info "Installation de curl..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl
        else
            log_error "Impossible d'installer curl automatiquement"
            exit 1
        fi
    fi
    
    # Vérifier wget
    if ! command -v wget &> /dev/null; then
        log_info "Installation de wget..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y wget
        elif command -v yum &> /dev/null; then
            sudo yum install -y wget
        fi
    fi
    
    # Vérifier Python3
    if ! command -v python3 &> /dev/null; then
        log_info "Installation de Python3..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y python3 python3-pip
        elif command -v yum &> /dev/null; then
            sudo yum install -y python3 python3-pip
        else
            log_error "Impossible d'installer Python3 automatiquement"
            exit 1
        fi
    fi
    
    # Vérifier PostgreSQL
    if ! command -v psql &> /dev/null; then
        log_warning "PostgreSQL n'est pas installé"
        log_info "Installation de PostgreSQL..."
        
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y postgresql postgresql-contrib
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
        elif command -v yum &> /dev/null; then
            sudo yum install -y postgresql-server postgresql-contrib
            sudo postgresql-setup initdb
            sudo systemctl start postgresql
            sudo systemctl enable postgresql
        else
            log_error "Impossible d'installer PostgreSQL automatiquement"
            log_info "Veuillez installer PostgreSQL manuellement"
            exit 1
        fi
    fi
    
    log_success "Prérequis système vérifiés"
}

# Configurer PostgreSQL
setup_postgresql() {
    log_info "Configuration de PostgreSQL..."
    
    # Vérifier si PostgreSQL fonctionne
    if ! sudo systemctl is-active --quiet postgresql; then
        log_info "Démarrage de PostgreSQL..."
        sudo systemctl start postgresql
    fi
    
    # Créer la base de données et l'utilisateur
    sudo -u postgres psql -c "CREATE DATABASE listmonk;" 2>/dev/null || log_warning "Base de données listmonk existe déjà"
    sudo -u postgres psql -c "CREATE USER listmonk WITH PASSWORD 'listmonk';" 2>/dev/null || log_warning "Utilisateur listmonk existe déjà"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE listmonk TO listmonk;" 2>/dev/null
    
    log_success "PostgreSQL configuré"
}

# Créer le fichier de configuration
create_config() {
    log_info "Création du fichier de configuration..."
    
    if [ ! -f "config.toml" ]; then
        cat > config.toml << 'EOF'
[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "listmonk"

# Database.
[db]
host = "localhost"
port = 5432
user = "listmonk"
password = "listmonk"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"

# SMTP servers.
[[smtp]]
enabled = true
host = "localhost"
port = 1025
auth_protocol = "none"
username = ""
password = ""
hello_hostname = ""
max_conns = 10
max_msg_retries = 2
idle_timeout = "15s"
wait_timeout = "5s"
tls_enabled = false
tls_skip_verify = false
email_headers = []

[privacy]
individual_tracking = false
unsubscribe_header = true
allow_blocklist = true
allow_export = true
allow_wipe = true
exportable = ["profile", "subscriptions", "campaign_views", "link_clicks"]

[security]
enable_captcha = false

[upload]
provider = "filesystem"
filesystem_upload_path = "uploads"
filesystem_upload_uri = "/uploads"

[bounce]
enabled = false
webhooks_enabled = false
EOF
        log_success "Fichier de configuration créé"
    else
        log_warning "Fichier de configuration existe déjà"
    fi
}

# Fonction principale
main() {
    echo "Ce script va :"
    echo "  1. Vérifier et installer les prérequis système"
    echo "  2. Télécharger ou compiler Listmonk"
    echo "  3. Configurer PostgreSQL"
    echo "  4. Créer la configuration"
    echo "  5. Initialiser la base de données"
    echo "  6. Intégrer les données des mairies"
    echo ""
    
    # Demander confirmation
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi
    
    # Exécuter les étapes
    check_system_requirements
    setup_postgresql
    create_config
    
    # Obtenir Listmonk
    if [ ! -f "./listmonk" ]; then
        log_info "Exécutable Listmonk non trouvé, téléchargement..."
        if ! download_listmonk; then
            log_warning "Échec du téléchargement, tentative de compilation..."
            if ! compile_listmonk; then
                log_error "Impossible d'obtenir Listmonk"
                exit 1
            fi
        fi
    else
        log_success "Exécutable Listmonk trouvé"
    fi
    
    # Initialiser la base de données
    log_info "Initialisation de la base de données..."
    if ./listmonk --config config.toml --install --yes; then
        log_success "Base de données initialisée"
    else
        log_warning "La base de données semble déjà initialisée"
    fi
    
    # Nettoyer et convertir le CSV si nécessaire
    if [ ! -f "mairielist-converted.csv" ]; then
        if [ -f "mairielist.csv" ]; then
            log_info "Conversion du fichier CSV des mairies..."
            python3 scripts/fix-and-convert-csv.py
        else
            log_error "Fichier mairielist.csv non trouvé"
            log_info "Veuillez placer le fichier des mairies dans ce répertoire"
            exit 1
        fi
    fi
    
    log_success "Configuration terminée !"
    echo ""
    echo "🎉 Listmonk est maintenant configuré !"
    echo "================================================"
    echo ""
    echo "Pour démarrer avec les mairies :"
    echo "  ./start-with-mairies.sh"
    echo ""
    echo "Pour démarrer manuellement :"
    echo "  ./listmonk --config config.toml"
    echo ""
    echo "Interface web : http://localhost:9000"
    echo "Utilisateur   : admin"
    echo "Mot de passe  : listmonk"
}

# Exécuter le script principal
main "$@"