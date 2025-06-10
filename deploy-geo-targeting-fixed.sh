#!/bin/bash

# Script de déploiement des fonctionnalités de ciblage géographique
# Version corrigée avec détection automatique de la configuration DB

set -e

echo "🎯 Déploiement du ciblage géographique dans Listmonk Docker (Version corrigée)"
echo "============================================================================="

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

# Configuration
CONTAINER_NAME="listmonk_mairies_app"
DB_CONTAINER="listmonk_mairies_db"
API_USER="api"
API_TOKEN="RmAp4lu4hiMSE9GCV2KOSpjLWH0k7h1o"
API_URL="http://localhost:9000/api"

# Variables pour la DB (à détecter)
DB_USER=""
DB_NAME=""

# Détecter la configuration de la base de données
detect_db_config() {
    log_info "Détection de la configuration de la base de données..."
    
    # Essayer différents utilisateurs
    if docker exec "$DB_CONTAINER" psql -U postgres -c "SELECT 1;" &>/dev/null; then
        DB_USER="postgres"
        log_success "Utilisateur PostgreSQL détecté : postgres"
    elif docker exec "$DB_CONTAINER" psql -c "SELECT 1;" &>/dev/null; then
        DB_USER=""
        log_success "Connexion PostgreSQL sans utilisateur spécifique"
    elif docker exec "$DB_CONTAINER" psql -U listmonk -c "SELECT 1;" &>/dev/null; then
        DB_USER="listmonk"
        log_success "Utilisateur PostgreSQL détecté : listmonk"
    else
        log_error "Impossible de se connecter à PostgreSQL"
        return 1
    fi
    
    # Détecter le nom de la base de données
    if [ -n "$DB_USER" ]; then
        db_list=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -t -c "\l" | grep -E "(listmonk|mairies)" | head -1)
    else
        db_list=$(docker exec "$DB_CONTAINER" psql -t -c "\l" | grep -E "(listmonk|mairies)" | head -1)
    fi
    
    if echo "$db_list" | grep -q "listmonk_mairies"; then
        DB_NAME="listmonk_mairies"
    elif echo "$db_list" | grep -q "listmonk"; then
        DB_NAME="listmonk"
    else
        DB_NAME="listmonk_mairies"  # Par défaut
    fi
    
    log_success "Base de données détectée : $DB_NAME"
    
    return 0
}

# Exécuter une commande SQL
execute_sql() {
    local sql_file="$1"
    local description="$2"
    
    log_info "$description..."
    
    if [ -n "$DB_USER" ]; then
        if docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < "$sql_file"; then
            log_success "$description terminé"
            return 0
        else
            log_error "Échec : $description"
            return 1
        fi
    else
        if docker exec -i "$DB_CONTAINER" psql -d "$DB_NAME" < "$sql_file"; then
            log_success "$description terminé"
            return 0
        else
            log_error "Échec : $description"
            return 1
        fi
    fi
}

# Vérifier l'environnement
check_environment() {
    log_info "Vérification de l'environnement..."
    
    # Vérifier Docker
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "Conteneur $CONTAINER_NAME non trouvé"
        exit 1
    fi
    
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        log_error "Conteneur $DB_CONTAINER non trouvé"
        exit 1
    fi
    
    # Vérifier l'API
    if ! curl -s -u "$API_USER:$API_TOKEN" "$API_URL/lists" > /dev/null; then
        log_error "API Listmonk non accessible"
        exit 1
    fi
    
    # Détecter la configuration DB
    if ! detect_db_config; then
        exit 1
    fi
    
    log_success "Environnement vérifié"
}

# Créer les tables de géolocalisation
create_geo_tables() {
    log_info "Création des tables de géolocalisation..."
    
    # Script SQL pour créer les tables
    cat > /tmp/geo_tables.sql << 'EOF'
-- Table des départements français
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Ajouter des colonnes aux abonnés pour la géolocalisation
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='department_code') THEN
        ALTER TABLE subscribers ADD COLUMN department_code VARCHAR(3);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='commune_code') THEN
        ALTER TABLE subscribers ADD COLUMN commune_code VARCHAR(10);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='subscribers' AND column_name='population') THEN
        ALTER TABLE subscribers ADD COLUMN population INTEGER DEFAULT 0;
    END IF;
END $$;

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_subscribers_department ON subscribers(department_code);
CREATE INDEX IF NOT EXISTS idx_subscribers_population ON subscribers(population);
EOF

    execute_sql "/tmp/geo_tables.sql" "Création des tables de géolocalisation"
    rm -f /tmp/geo_tables.sql
}

# Insérer les données des départements
insert_departments_data() {
    log_info "Insertion des données des départements..."
    
    cat > /tmp/departments_data.sql << 'EOF'
INSERT INTO departments (code, name, region) VALUES
('01', 'Ain', 'Auvergne-Rhône-Alpes'),
('02', 'Aisne', 'Hauts-de-France'),
('03', 'Allier', 'Auvergne-Rhône-Alpes'),
('04', 'Alpes-de-Haute-Provence', 'Provence-Alpes-Côte d''Azur'),
('05', 'Hautes-Alpes', 'Provence-Alpes-Côte d''Azur'),
('06', 'Alpes-Maritimes', 'Provence-Alpes-Côte d''Azur'),
('07', 'Ardèche', 'Auvergne-Rhône-Alpes'),
('08', 'Ardennes', 'Grand Est'),
('09', 'Ariège', 'Occitanie'),
('10', 'Aube', 'Grand Est'),
('11', 'Aude', 'Occitanie'),
('12', 'Aveyron', 'Occitanie'),
('13', 'Bouches-du-Rhône', 'Provence-Alpes-Côte d''Azur'),
('14', 'Calvados', 'Normandie'),
('15', 'Cantal', 'Auvergne-Rhône-Alpes'),
('16', 'Charente', 'Nouvelle-Aquitaine'),
('17', 'Charente-Maritime', 'Nouvelle-Aquitaine'),
('18', 'Cher', 'Centre-Val de Loire'),
('19', 'Corrèze', 'Nouvelle-Aquitaine'),
('20', 'Corse', 'Corse'),
('21', 'Côte-d''Or', 'Bourgogne-Franche-Comté'),
('22', 'Côtes-d''Armor', 'Bretagne'),
('23', 'Creuse', 'Nouvelle-Aquitaine'),
('24', 'Dordogne', 'Nouvelle-Aquitaine'),
('25', 'Doubs', 'Bourgogne-Franche-Comté'),
('26', 'Drôme', 'Auvergne-Rhône-Alpes'),
('27', 'Eure', 'Normandie'),
('28', 'Eure-et-Loir', 'Centre-Val de Loire'),
('29', 'Finistère', 'Bretagne'),
('30', 'Gard', 'Occitanie'),
('31', 'Haute-Garonne', 'Occitanie'),
('32', 'Gers', 'Occitanie'),
('33', 'Gironde', 'Nouvelle-Aquitaine'),
('34', 'Hérault', 'Occitanie'),
('35', 'Ille-et-Vilaine', 'Bretagne'),
('36', 'Indre', 'Centre-Val de Loire'),
('37', 'Indre-et-Loire', 'Centre-Val de Loire'),
('38', 'Isère', 'Auvergne-Rhône-Alpes'),
('39', 'Jura', 'Bourgogne-Franche-Comté'),
('40', 'Landes', 'Nouvelle-Aquitaine'),
('41', 'Loir-et-Cher', 'Centre-Val de Loire'),
('42', 'Loire', 'Auvergne-Rhône-Alpes'),
('43', 'Haute-Loire', 'Auvergne-Rhône-Alpes'),
('44', 'Loire-Atlantique', 'Pays de la Loire'),
('45', 'Loiret', 'Centre-Val de Loire'),
('46', 'Lot', 'Occitanie'),
('47', 'Lot-et-Garonne', 'Nouvelle-Aquitaine'),
('48', 'Lozère', 'Occitanie'),
('49', 'Maine-et-Loire', 'Pays de la Loire'),
('50', 'Manche', 'Normandie'),
('51', 'Marne', 'Grand Est'),
('52', 'Haute-Marne', 'Grand Est'),
('53', 'Mayenne', 'Pays de la Loire'),
('54', 'Meurthe-et-Moselle', 'Grand Est'),
('55', 'Meuse', 'Grand Est'),
('56', 'Morbihan', 'Bretagne'),
('57', 'Moselle', 'Grand Est'),
('58', 'Nièvre', 'Bourgogne-Franche-Comté'),
('59', 'Nord', 'Hauts-de-France'),
('60', 'Oise', 'Hauts-de-France'),
('61', 'Orne', 'Normandie'),
('62', 'Pas-de-Calais', 'Hauts-de-France'),
('63', 'Puy-de-Dôme', 'Auvergne-Rhône-Alpes'),
('64', 'Pyrénées-Atlantiques', 'Nouvelle-Aquitaine'),
('65', 'Hautes-Pyrénées', 'Occitanie'),
('66', 'Pyrénées-Orientales', 'Occitanie'),
('67', 'Bas-Rhin', 'Grand Est'),
('68', 'Haut-Rhin', 'Grand Est'),
('69', 'Rhône', 'Auvergne-Rhône-Alpes'),
('70', 'Haute-Saône', 'Bourgogne-Franche-Comté'),
('71', 'Saône-et-Loire', 'Bourgogne-Franche-Comté'),
('72', 'Sarthe', 'Pays de la Loire'),
('73', 'Savoie', 'Auvergne-Rhône-Alpes'),
('74', 'Haute-Savoie', 'Auvergne-Rhône-Alpes'),
('75', 'Paris', 'Île-de-France'),
('76', 'Seine-Maritime', 'Normandie'),
('77', 'Seine-et-Marne', 'Île-de-France'),
('78', 'Yvelines', 'Île-de-France'),
('79', 'Deux-Sèvres', 'Nouvelle-Aquitaine'),
('80', 'Somme', 'Hauts-de-France'),
('81', 'Tarn', 'Occitanie'),
('82', 'Tarn-et-Garonne', 'Occitanie'),
('83', 'Var', 'Provence-Alpes-Côte d''Azur'),
('84', 'Vaucluse', 'Provence-Alpes-Côte d''Azur'),
('85', 'Vendée', 'Pays de la Loire'),
('86', 'Vienne', 'Nouvelle-Aquitaine'),
('87', 'Haute-Vienne', 'Nouvelle-Aquitaine'),
('88', 'Vosges', 'Grand Est'),
('89', 'Yonne', 'Bourgogne-Franche-Comté'),
('90', 'Territoire de Belfort', 'Bourgogne-Franche-Comté'),
('91', 'Essonne', 'Île-de-France'),
('92', 'Hauts-de-Seine', 'Île-de-France'),
('93', 'Seine-Saint-Denis', 'Île-de-France'),
('94', 'Val-de-Marne', 'Île-de-France'),
('95', 'Val-d''Oise', 'Île-de-France')
ON CONFLICT (code) DO NOTHING;
EOF

    execute_sql "/tmp/departments_data.sql" "Insertion des données des départements"
    rm -f /tmp/departments_data.sql
}

# Mettre à jour les données des abonnés avec les informations géographiques
update_subscribers_geo_data() {
    log_info "Mise à jour des données géographiques des abonnés..."
    
    cat > /tmp/update_geo.sql << 'EOF'
-- Extraire le code département depuis les attributs
UPDATE subscribers 
SET department_code = CASE 
    WHEN attribs->>'code_departement' IS NOT NULL 
    THEN LPAD(attribs->>'code_departement', 2, '0')
    ELSE NULL
END,
population = CASE 
    WHEN attribs->>'population' IS NOT NULL 
    THEN (attribs->>'population')::INTEGER
    ELSE 0
END,
commune_code = attribs->>'code_insee'
WHERE attribs IS NOT NULL;
EOF

    execute_sql "/tmp/update_geo.sql" "Mise à jour des données géographiques"
    rm -f /tmp/update_geo.sql
}

# Créer des vues pour les statistiques
create_geo_views() {
    log_info "Création des vues de ciblage géographique..."
    
    cat > /tmp/geo_views.sql << 'EOF'
-- Vue pour le ciblage par département
CREATE OR REPLACE VIEW subscribers_by_department AS
SELECT 
    d.code as department_code,
    d.name as department_name,
    d.region,
    COUNT(s.id) as subscriber_count,
    COALESCE(AVG(s.population), 0) as avg_population
FROM departments d
LEFT JOIN subscribers s ON s.department_code = d.code
GROUP BY d.code, d.name, d.region
ORDER BY subscriber_count DESC;

-- Vue pour le ciblage par population
CREATE OR REPLACE VIEW subscribers_by_population AS
SELECT 
    CASE 
        WHEN population < 500 THEN 'Très petites communes (< 500 hab.)'
        WHEN population < 2000 THEN 'Petites communes (500-2000 hab.)'
        WHEN population < 10000 THEN 'Communes moyennes (2000-10000 hab.)'
        WHEN population < 50000 THEN 'Grandes communes (10000-50000 hab.)'
        ELSE 'Très grandes communes (> 50000 hab.)'
    END as population_category,
    COUNT(*) as subscriber_count,
    MIN(population) as min_population,
    MAX(population) as max_population
FROM subscribers 
WHERE population > 0
GROUP BY population_category
ORDER BY MIN(population);
EOF

    execute_sql "/tmp/geo_views.sql" "Création des vues de ciblage"
    rm -f /tmp/geo_views.sql
}

# Créer un script de requête SQL pour le ciblage
create_targeting_queries() {
    log_info "Création des requêtes de ciblage..."
    
    cat > geo-targeting-queries.sql << 'EOF'
-- Exemples de requêtes pour le ciblage géographique

-- 1. Sélectionner toutes les mairies d'un département
-- Exemple pour le département 75 (Paris)
SELECT id, email, name, attribs->>'nom_commune' as commune
FROM subscribers 
WHERE department_code = '75';

-- 2. Sélectionner les mairies par tranche de population
-- Exemple : communes de 1000 à 5000 habitants
SELECT id, email, name, population, attribs->>'nom_commune' as commune
FROM subscribers 
WHERE population BETWEEN 1000 AND 5000
ORDER BY population DESC;

-- 3. Sélectionner les mairies de plusieurs départements
-- Exemple : Île-de-France (75, 77, 78, 91, 92, 93, 94, 95)
SELECT id, email, name, department_code, attribs->>'nom_commune' as commune
FROM subscribers 
WHERE department_code IN ('75', '77', '78', '91', '92', '93', '94', '95');

-- 4. Combiner département et population
-- Exemple : grandes communes (> 10000 hab.) en Auvergne-Rhône-Alpes
SELECT s.id, s.email, s.name, s.population, s.department_code, d.name as department_name
FROM subscribers s
JOIN departments d ON s.department_code = d.code
WHERE d.region = 'Auvergne-Rhône-Alpes' 
AND s.population > 10000
ORDER BY s.population DESC;

-- 5. Statistiques par département
SELECT * FROM subscribers_by_department;

-- 6. Statistiques par tranche de population
SELECT * FROM subscribers_by_population;

-- 7. Top 10 des départements avec le plus de mairies
SELECT department_code, COUNT(*) as nb_mairies
FROM subscribers 
WHERE department_code IS NOT NULL
GROUP BY department_code
ORDER BY nb_mairies DESC
LIMIT 10;
EOF

    log_success "Fichier de requêtes créé : geo-targeting-queries.sql"
}

# Afficher les informations finales
show_final_info() {
    echo ""
    echo "🎯 Déploiement du ciblage géographique terminé !"
    echo "==============================================="
    echo ""
    echo "✅ Fonctionnalités déployées :"
    echo "   📊 Tables de géolocalisation créées"
    echo "   🗺️  Données des départements français"
    echo "   👥 Abonnés enrichis avec données géographiques"
    echo "   🔍 Vues de ciblage configurées"
    echo ""
    echo "🚀 Utilisation dans Listmonk :"
    echo ""
    echo "1. 🎯 Allez dans 'Subscribers' > 'Advanced' ou 'SQL Query'"
    echo ""
    echo "2. 📋 Exemples de requêtes :"
    echo "   • Par département : department_code = '75'"
    echo "   • Par population : population BETWEEN 1000 AND 5000"
    echo "   • Par région : JOIN avec departments"
    echo ""
    echo "3. 📊 Vérifier les données :"
    echo "   SELECT * FROM subscribers_by_department;"
    echo "   SELECT * FROM subscribers_by_population;"
    echo ""
    echo "4. 🔧 Statistiques rapides :"
    echo "   SELECT COUNT(*) FROM subscribers WHERE department_code IS NOT NULL;"
    echo "   SELECT COUNT(*) FROM subscribers WHERE population > 0;"
    echo ""
    echo "📚 Documentation complète : GUIDE_CIBLAGE_GEOGRAPHIQUE.md"
    echo "📝 Requêtes d'exemple : geo-targeting-queries.sql"
    echo ""
}

# Fonction principale
main() {
    echo "Ce script va déployer les fonctionnalités de ciblage géographique"
    echo "dans votre installation Docker de Listmonk existante."
    echo ""
    echo "Fonctionnalités à déployer :"
    echo "  ✅ Tables de géolocalisation"
    echo "  ✅ Données des départements français"
    echo "  ✅ Enrichissement des abonnés"
    echo "  ✅ Requêtes de ciblage"
    echo ""
    
    # Demander confirmation
    read -p "Continuer ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 0
    fi
    
    # Exécuter les étapes
    check_environment
    create_geo_tables
    insert_departments_data
    update_subscribers_geo_data
    create_geo_views
    create_targeting_queries
    show_final_info
}

# Exécuter le script principal
main "$@"