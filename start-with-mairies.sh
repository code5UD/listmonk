#!/bin/bash

# Script de démarrage automatique de Listmonk avec intégration des mairies
# Ce script configure et démarre Listmonk avec toutes les données des mairies françaises

set -e

echo "🇫🇷 Démarrage de Listmonk avec les mairies françaises"
echo "=================================================="

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

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier que nous sommes dans le bon répertoire
    if [ ! -f "./listmonk" ]; then
        log_error "Exécutable listmonk non trouvé."
        log_info "Listmonk n'est pas encore configuré sur ce système."
        echo ""
        echo "Voulez-vous exécuter la configuration automatique ? (y/N)"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Lancement de la configuration automatique..."
            if [ -f "./setup-listmonk.sh" ]; then
                ./setup-listmonk.sh
                if [ ! -f "./listmonk" ]; then
                    log_error "La configuration a échoué"
                    exit 1
                fi
            else
                log_error "Script de configuration non trouvé"
                log_info "Veuillez télécharger et exécuter setup-listmonk.sh"
                exit 1
            fi
        else
            log_error "Configuration annulée"
            log_info "Pour configurer Listmonk manuellement :"
            log_info "  1. Exécutez ./setup-listmonk.sh"
            log_info "  2. Ou téléchargez Listmonk depuis https://github.com/knadh/listmonk/releases"
            exit 1
        fi
    fi
    
    # Vérifier la configuration
    if [ ! -f "config.toml" ]; then
        log_error "Fichier config.toml non trouvé."
        exit 1
    fi
    
    # Vérifier Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 est requis mais non installé."
        exit 1
    fi
    
    # Vérifier les données des mairies
    if [ ! -f "mairielist-converted.csv" ]; then
        log_warning "Fichier des mairies non trouvé. Tentative de génération..."
        if [ -f "mairielist.csv" ]; then
            log_info "Conversion du fichier des mairies..."
            python3 scripts/convert-mairielist-csv.py
        else
            log_error "Aucun fichier de données des mairies trouvé."
            exit 1
        fi
    fi
    
    log_success "Prérequis vérifiés"
}

# Initialiser la base de données
init_database() {
    log_info "Initialisation de la base de données..."
    
    # Vérifier si la DB est déjà initialisée
    if ./listmonk --config config.toml --install --yes; then
        log_success "Base de données initialisée"
    else
        log_warning "La base de données semble déjà initialisée"
    fi
}

# Démarrer Listmonk en arrière-plan
start_listmonk() {
    log_info "Démarrage de Listmonk..."
    
    # Vérifier si Listmonk est déjà en cours d'exécution
    if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
        log_warning "Listmonk semble déjà en cours d'exécution"
        return 0
    fi
    
    # Démarrer Listmonk en arrière-plan
    nohup ./listmonk --config config.toml > listmonk.log 2>&1 &
    LISTMONK_PID=$!
    
    # Attendre que Listmonk soit prêt
    log_info "Attente du démarrage de Listmonk..."
    for i in {1..30}; do
        if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
            log_success "Listmonk démarré (PID: $LISTMONK_PID)"
            echo $LISTMONK_PID > listmonk.pid
            return 0
        fi
        sleep 2
        echo -n "."
    done
    
    log_error "Impossible de démarrer Listmonk"
    return 1
}

# Intégrer les données des mairies
integrate_mairies() {
    log_info "Intégration des données des mairies..."
    
    # Exécuter le script d'intégration Python
    if python3 scripts/init-mairies-integration.py; then
        log_success "Données des mairies intégrées avec succès"
    else
        log_error "Échec de l'intégration des données"
        return 1
    fi
}

# Afficher les informations de connexion
show_connection_info() {
    echo ""
    echo "🎉 Listmonk est prêt avec les mairies françaises !"
    echo "================================================"
    echo ""
    echo "🌐 Interface web : http://localhost:9000"
    echo "👤 Utilisateur   : admin"
    echo "🔑 Mot de passe  : listmonk"
    echo ""
    echo "📋 Fonctionnalités disponibles :"
    echo "   ✅ Import automatique des 40 000+ mairies françaises"
    echo "   ✅ Ciblage géographique par département"
    echo "   ✅ Ciblage par nombre d'habitants"
    echo "   ✅ Opérateurs ET/OU avancés"
    echo "   ✅ Interface de ciblage graphique"
    echo ""
    echo "🚀 Prochaines étapes :"
    echo "   1. Ouvrez http://localhost:9000 dans votre navigateur"
    echo "   2. Connectez-vous avec admin/listmonk"
    echo "   3. Allez dans 'Mairies' > 'Ciblage géographique'"
    echo "   4. Testez les filtres de ciblage"
    echo "   5. Créez votre première campagne ciblée"
    echo ""
    echo "📚 Documentation :"
    echo "   - CIBLAGE_AVANCE_DOCUMENTATION.md"
    echo "   - IMPLEMENTATION_CIBLAGE_AVANCE.md"
    echo ""
    echo "🛑 Pour arrêter Listmonk :"
    echo "   ./stop-listmonk.sh"
    echo ""
}

# Créer un script d'arrêt
create_stop_script() {
    cat > stop-listmonk.sh << 'EOF'
#!/bin/bash

echo "🛑 Arrêt de Listmonk..."

if [ -f "listmonk.pid" ]; then
    PID=$(cat listmonk.pid)
    if kill -0 $PID 2>/dev/null; then
        kill $PID
        echo "✅ Listmonk arrêté (PID: $PID)"
        rm -f listmonk.pid
    else
        echo "⚠️  Processus Listmonk non trouvé"
        rm -f listmonk.pid
    fi
else
    echo "⚠️  Fichier PID non trouvé"
    # Essayer de tuer par nom de processus
    pkill -f "./listmonk" && echo "✅ Processus Listmonk arrêté"
fi
EOF
    chmod +x stop-listmonk.sh
}

# Fonction de nettoyage en cas d'interruption
cleanup() {
    log_warning "Interruption détectée. Nettoyage..."
    if [ -f "listmonk.pid" ]; then
        PID=$(cat listmonk.pid)
        kill $PID 2>/dev/null || true
        rm -f listmonk.pid
    fi
    exit 1
}

# Capturer les signaux d'interruption
trap cleanup INT TERM

# Fonction principale
main() {
    echo "Démarrage automatique de Listmonk avec les mairies françaises..."
    echo "Ce script va :"
    echo "  1. Vérifier les prérequis"
    echo "  2. Initialiser la base de données"
    echo "  3. Démarrer Listmonk"
    echo "  4. Intégrer les données des mairies"
    echo "  5. Configurer le ciblage géographique"
    echo ""
    
    # Demander confirmation
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi
    
    # Exécuter les étapes
    check_prerequisites
    init_database
    start_listmonk
    
    # Attendre un peu pour que Listmonk soit complètement prêt
    sleep 5
    
    integrate_mairies
    create_stop_script
    show_connection_info
    
    # Garder le script en vie pour surveiller Listmonk
    log_info "Listmonk fonctionne en arrière-plan. Appuyez sur Ctrl+C pour arrêter."
    
    # Boucle de surveillance
    while true; do
        if [ -f "listmonk.pid" ]; then
            PID=$(cat listmonk.pid)
            if ! kill -0 $PID 2>/dev/null; then
                log_error "Listmonk s'est arrêté de manière inattendue"
                rm -f listmonk.pid
                break
            fi
        else
            log_error "Fichier PID perdu"
            break
        fi
        sleep 10
    done
}

# Exécuter le script principal
main "$@"