#!/bin/bash

# Script pour corriger le CSV et installer les dépendances

echo "🔧 CORRECTION DU CSV ET INSTALLATION DES DÉPENDANCES"
echo "===================================================="

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

# Installer jq
install_jq() {
    log_info "Installation de jq..."
    
    if command -v jq &> /dev/null; then
        log_success "jq déjà installé"
        return 0
    fi
    
    if command -v apt-get &> /dev/null; then
        apt-get update > /dev/null 2>&1
        apt-get install -y jq > /dev/null 2>&1
        log_success "jq installé via apt-get"
    elif command -v yum &> /dev/null; then
        yum install -y jq > /dev/null 2>&1
        log_success "jq installé via yum"
    elif command -v dnf &> /dev/null; then
        dnf install -y jq > /dev/null 2>&1
        log_success "jq installé via dnf"
    else
        log_error "Impossible d'installer jq automatiquement"
        log_info "Installez jq manuellement : https://stedolan.github.io/jq/download/"
        return 1
    fi
}

# Corriger le fichier CSV original
fix_csv_format() {
    log_info "Correction du format CSV..."
    
    if [ -f "mairielist-converted.csv" ]; then
        # Vérifier le format actuel
        local first_line=$(head -1 mairielist-converted.csv)
        log_info "Format actuel : $first_line"
        
        if [[ "$first_line" == *";"* ]]; then
            log_warning "Délimiteurs ';' détectés, conversion en cours..."
            
            # Sauvegarder l'original
            cp mairielist-converted.csv mairielist-converted.csv.backup
            
            # Convertir le fichier complet
            log_info "Conversion de $(wc -l < mairielist-converted.csv) lignes..."
            
            # Remplacer les ; par des , mais attention aux ; dans les adresses
            # Méthode plus sûre : remplacer seulement les ; qui séparent les champs
            awk -F';' 'BEGIN{OFS=","} {
                for(i=1; i<=NF; i++) {
                    # Nettoyer les guillemets si nécessaire
                    gsub(/^"/, "", $i)
                    gsub(/"$/, "", $i)
                }
                print
            }' mairielist-converted.csv > mairielist-converted-fixed.csv
            
            # Vérifier le résultat
            local new_first_line=$(head -1 mairielist-converted-fixed.csv)
            log_success "Nouveau format : $new_first_line"
            
            # Remplacer l'original
            mv mairielist-converted-fixed.csv mairielist-converted.csv
            
            log_success "Fichier CSV corrigé"
            
        else
            log_success "Fichier CSV déjà au bon format"
        fi
        
        # Afficher quelques statistiques
        local total_lines=$(wc -l < mairielist-converted.csv)
        local sample_lines=$(head -3 mairielist-converted.csv)
        
        log_info "Statistiques du fichier :"
        log_info "  - Total lignes : $total_lines"
        log_info "  - Échantillon :"
        echo "$sample_lines"
        
    else
        log_error "Fichier mairielist-converted.csv non trouvé"
        log_info "Fichiers CSV disponibles :"
        find . -name "*.csv" -type f | head -5
        return 1
    fi
}

# Créer un fichier CSV de test à partir de l'original
create_test_from_original() {
    log_info "Création d'un fichier de test à partir de l'original..."
    
    if [ -f "mairielist-converted.csv" ]; then
        # Prendre les 100 premières lignes + en-tête
        head -101 mairielist-converted.csv > mairies-test-100.csv
        
        local test_lines=$(wc -l < mairies-test-100.csv)
        log_success "Fichier de test créé avec $test_lines lignes"
        
        # Afficher un échantillon
        log_info "Échantillon du fichier de test :"
        head -3 mairies-test-100.csv
        
    else
        log_error "Impossible de créer le fichier de test"
    fi
}

# Vérifier la structure du fichier
verify_csv_structure() {
    log_info "Vérification de la structure CSV..."
    
    if [ -f "mairielist-converted.csv" ]; then
        local header=$(head -1 mairielist-converted.csv)
        log_info "En-tête détecté : $header"
        
        # Compter les colonnes
        local col_count=$(echo "$header" | tr ',' '\n' | wc -l)
        log_info "Nombre de colonnes : $col_count"
        
        # Vérifier les colonnes importantes
        if [[ "$header" == *"email"* ]]; then
            log_success "Colonne 'email' trouvée"
        else
            log_warning "Colonne 'email' non trouvée"
        fi
        
        if [[ "$header" == *"departement"* ]] || [[ "$header" == *"code_departement"* ]]; then
            log_success "Colonne département trouvée"
        else
            log_warning "Colonne département non trouvée"
        fi
        
        if [[ "$header" == *"population"* ]]; then
            log_success "Colonne population trouvée"
        else
            log_warning "Colonne population non trouvée"
        fi
        
        # Vérifier quelques lignes de données
        log_info "Vérification des données (lignes 2-4) :"
        sed -n '2,4p' mairielist-converted.csv
        
    else
        log_error "Fichier non trouvé pour vérification"
    fi
}

# Fonction principale
main() {
    echo ""
    log_info "Ce script va :"
    echo "  1. Installer jq (outil JSON)"
    echo "  2. Corriger le format du fichier CSV"
    echo "  3. Vérifier la structure des données"
    echo "  4. Créer un fichier de test"
    echo ""
    
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    echo ""
    log_info "🔧 DÉBUT DE LA CORRECTION"
    echo ""
    
    # Installer jq
    install_jq
    
    # Corriger le CSV
    fix_csv_format
    
    # Vérifier la structure
    verify_csv_structure
    
    # Créer un fichier de test
    create_test_from_original
    
    echo ""
    log_success "🎉 CORRECTION TERMINÉE !"
    echo ""
    log_info "📁 Fichiers disponibles :"
    log_info "  - mairielist-converted.csv (original corrigé)"
    log_info "  - mairies-test-100.csv (fichier de test)"
    if [ -f "mairielist-converted.csv.backup" ]; then
        log_info "  - mairielist-converted.csv.backup (sauvegarde)"
    fi
    echo ""
    log_info "🚀 Vous pouvez maintenant lancer :"
    log_info "  ./simple-import-mairies.sh"
    log_info "  ou"
    log_info "  ./reimport-mairies.sh"
    echo ""
}

# Exécuter
main "$@"