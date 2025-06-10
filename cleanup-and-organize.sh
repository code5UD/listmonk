#!/bin/bash

# Script de nettoyage et organisation du projet

echo "🧹 NETTOYAGE ET ORGANISATION DU PROJET"
echo "======================================"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Créer la structure de répertoires
create_directory_structure() {
    log_info "Création de la structure de répertoires..."
    
    mkdir -p {scripts/{deployment,maintenance,import},docs,data,backup}
    
    log_success "Structure créée :"
    echo "  📁 scripts/"
    echo "    📁 deployment/    # Scripts de déploiement"
    echo "    📁 maintenance/   # Scripts de maintenance"
    echo "    📁 import/        # Scripts d'import"
    echo "  📁 docs/            # Documentation"
    echo "  📁 data/            # Fichiers de données"
    echo "  📁 backup/          # Sauvegardes"
}

# Organiser les scripts
organize_scripts() {
    log_info "Organisation des scripts..."
    
    # Scripts de déploiement
    mv deploy-complete-geo-targeting.sh scripts/deployment/ 2>/dev/null || true
    mv deploy-geo-targeting-final.sh scripts/deployment/ 2>/dev/null || true
    mv install-geo-ui-docker.sh scripts/deployment/ 2>/dev/null || true
    
    # Scripts de maintenance
    mv verify-geo-targeting.sh scripts/maintenance/ 2>/dev/null || true
    mv diagnose-and-fix.sh scripts/maintenance/ 2>/dev/null || true
    mv fix-geo-data-extraction.sh scripts/maintenance/ 2>/dev/null || true
    
    # Scripts d'import
    mv simple-import-mairies.sh scripts/import/ 2>/dev/null || true
    mv reimport-mairies.sh scripts/import/ 2>/dev/null || true
    mv fix-csv-and-install-deps.sh scripts/import/ 2>/dev/null || true
    mv docker-integration-mairies-final.sh scripts/import/ 2>/dev/null || true
    
    log_success "Scripts organisés par catégorie"
}

# Organiser la documentation
organize_documentation() {
    log_info "Organisation de la documentation..."
    
    # Déplacer les fichiers de documentation
    mv PROJECT_SUMMARY.md docs/ 2>/dev/null || true
    mv README_CIBLAGE_GEOGRAPHIQUE.md docs/ 2>/dev/null || true
    mv UTILISATION_CIBLAGE_GEO.md docs/ 2>/dev/null || true
    mv GUIDE_CIBLAGE_GEOGRAPHIQUE.md docs/ 2>/dev/null || true
    
    # Créer un README principal
    cat > README.md << 'EOF'
# 🎯 Ciblage Géographique Listmonk - Mairies Françaises

## 🚀 Démarrage Rapide

### Installation Complète
```bash
# 1. Récupérer le projet
git clone <repository>
cd listmonk

# 2. Déploiement automatique
./scripts/deployment/deploy-complete-geo-targeting.sh

# 3. Vérification
./scripts/maintenance/verify-geo-targeting.sh
```

### Import des Mairies
```bash
# Import simple et rapide
./scripts/import/simple-import-mairies.sh
```

## 📁 Structure du Projet

```
📦 Ciblage Géographique Listmonk
├── 📁 scripts/
│   ├── 📁 deployment/     # Scripts de déploiement
│   ├── 📁 maintenance/    # Scripts de maintenance
│   └── 📁 import/         # Scripts d'import
├── 📁 docs/               # Documentation complète
├── 📁 data/               # Fichiers de données
└── 📁 backup/             # Sauvegardes
```

## 🎯 Fonctionnalités

✅ **8870+ mairies françaises** importées  
✅ **Ciblage par département** (75, 13, 69, etc.)  
✅ **Ciblage par population** (min/max habitants)  
✅ **Interface graphique** intuitive  
✅ **Filtres rapides** (IDF, PACA, etc.)  
✅ **Scripts automatisés** de déploiement  

## 📚 Documentation

- 📊 **[Synthèse Complète](docs/PROJECT_SUMMARY.md)** - Vue d'ensemble du projet
- 🎯 **[Guide d'Utilisation](docs/README_CIBLAGE_GEOGRAPHIQUE.md)** - Mode d'emploi détaillé
- 🛠️ **[Guide Technique](docs/UTILISATION_CIBLAGE_GEO.md)** - Documentation technique

## 🔧 Scripts Principaux

### 🚀 Déploiement
- `scripts/deployment/deploy-complete-geo-targeting.sh` - Déploiement complet
- `scripts/deployment/deploy-geo-targeting-final.sh` - Déploiement base de données

### 🏛️ Import
- `scripts/import/simple-import-mairies.sh` - Import simple des mairies
- `scripts/import/fix-csv-and-install-deps.sh` - Correction CSV et dépendances

### 🔍 Maintenance
- `scripts/maintenance/verify-geo-targeting.sh` - Vérification système
- `scripts/maintenance/diagnose-and-fix.sh` - Diagnostic et réparation

## 🎯 Utilisation

1. **Interface Web** : http://localhost:9000 → Page "Abonnés" → Bouton "🎯 Ciblage Géo"
2. **Requêtes SQL** : Utilisation directe dans Listmonk
3. **Scripts** : Automatisation via les scripts fournis

## 📞 Support

```bash
# Vérification rapide
./scripts/maintenance/verify-geo-targeting.sh

# Réparation automatique
./scripts/maintenance/diagnose-and-fix.sh

# Logs
docker logs listmonk_mairies_app
```

🇫🇷 **Système de ciblage géographique pour les mairies françaises**
EOF

    log_success "Documentation organisée"
}

# Organiser les fichiers de données
organize_data() {
    log_info "Organisation des fichiers de données..."
    
    # Déplacer les fichiers CSV
    mv *.csv data/ 2>/dev/null || true
    mv geo-targeting-queries.sql data/ 2>/dev/null || true
    mv *.js data/ 2>/dev/null || true
    
    # Créer un fichier d'index des données
    cat > data/README.md << 'EOF'
# 📊 Fichiers de Données

## 📁 Contenu

### 🏛️ Fichiers CSV
- `mairielist-converted.csv` - Liste complète des mairies françaises
- `mairies-final.csv` - Fichier CSV formaté pour l'import
- `mairies-test-100.csv` - Fichier de test (100 mairies)

### 📝 Requêtes SQL
- `geo-targeting-queries.sql` - Exemples de requêtes de ciblage

### 🎨 Interface
- `geo-targeting.js` - Interface JavaScript de ciblage
- `console-geo-targeting.js` - Version console du ciblage

## 🔄 Utilisation

Les fichiers de ce répertoire sont utilisés par les scripts d'import et de déploiement.
Ne modifiez ces fichiers que si vous savez ce que vous faites.
EOF

    log_success "Fichiers de données organisés"
}

# Créer des liens symboliques pour la compatibilité
create_symlinks() {
    log_info "Création de liens symboliques pour la compatibilité..."
    
    # Liens vers les scripts principaux
    ln -sf scripts/deployment/deploy-complete-geo-targeting.sh deploy-complete.sh 2>/dev/null || true
    ln -sf scripts/import/simple-import-mairies.sh import-mairies.sh 2>/dev/null || true
    ln -sf scripts/maintenance/verify-geo-targeting.sh verify.sh 2>/dev/null || true
    
    log_success "Liens symboliques créés"
}

# Nettoyer les fichiers temporaires
cleanup_temp_files() {
    log_info "Nettoyage des fichiers temporaires..."
    
    # Supprimer les fichiers temporaires
    rm -f /tmp/geo-*.sql /tmp/inject-*.sh /tmp/geo-targeting-*.js 2>/dev/null || true
    rm -f *.backup *.tmp 2>/dev/null || true
    
    # Nettoyer les logs
    find . -name "*.log" -type f -delete 2>/dev/null || true
    
    log_success "Fichiers temporaires nettoyés"
}

# Créer un script de démarrage rapide
create_quick_start() {
    log_info "Création du script de démarrage rapide..."
    
    cat > quick-start.sh << 'EOF'
#!/bin/bash

# Script de démarrage rapide pour le ciblage géographique

echo "🎯 DÉMARRAGE RAPIDE - CIBLAGE GÉOGRAPHIQUE"
echo "=========================================="

echo ""
echo "Choisissez une action :"
echo "  1. 🚀 Déploiement complet"
echo "  2. 🏛️ Import des mairies"
echo "  3. 🔍 Vérification système"
echo "  4. 🛠️ Diagnostic et réparation"
echo "  5. 📚 Ouvrir la documentation"
echo ""

read -p "Votre choix (1-5) : " choice

case $choice in
    1)
        echo "🚀 Lancement du déploiement complet..."
        ./scripts/deployment/deploy-complete-geo-targeting.sh
        ;;
    2)
        echo "🏛️ Lancement de l'import des mairies..."
        ./scripts/import/simple-import-mairies.sh
        ;;
    3)
        echo "🔍 Vérification du système..."
        ./scripts/maintenance/verify-geo-targeting.sh
        ;;
    4)
        echo "🛠️ Diagnostic et réparation..."
        ./scripts/maintenance/diagnose-and-fix.sh
        ;;
    5)
        echo "📚 Documentation disponible :"
        echo "  - docs/PROJECT_SUMMARY.md"
        echo "  - docs/README_CIBLAGE_GEOGRAPHIQUE.md"
        echo "  - README.md"
        ;;
    *)
        echo "❌ Choix invalide"
        ;;
esac
EOF

    chmod +x quick-start.sh
    log_success "Script de démarrage rapide créé"
}

# Fonction principale
main() {
    echo ""
    log_info "Ce script va organiser et nettoyer le projet."
    echo ""
    echo "🔧 Actions :"
    echo "  1. Créer la structure de répertoires"
    echo "  2. Organiser les scripts par catégorie"
    echo "  3. Organiser la documentation"
    echo "  4. Organiser les fichiers de données"
    echo "  5. Créer des liens symboliques"
    echo "  6. Nettoyer les fichiers temporaires"
    echo "  7. Créer un script de démarrage rapide"
    echo ""
    
    read -p "Continuer avec l'organisation ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Opération annulée."
        exit 0
    fi
    
    echo ""
    log_info "🧹 DÉBUT DU NETTOYAGE ET DE L'ORGANISATION"
    echo ""
    
    create_directory_structure
    organize_scripts
    organize_documentation
    organize_data
    create_symlinks
    cleanup_temp_files
    create_quick_start
    
    echo ""
    log_success "🎉 ORGANISATION TERMINÉE !"
    echo ""
    log_info "📁 Structure finale :"
    tree -L 2 2>/dev/null || find . -type d -not -path '*/\.*' | head -20
    echo ""
    log_info "🚀 Démarrage rapide : ./quick-start.sh"
    log_info "📚 Documentation : docs/PROJECT_SUMMARY.md"
    echo ""
}

# Exécuter
main "$@"