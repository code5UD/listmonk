#!/bin/bash

# Script de diagnostic pour l'environnement Docker Listmonk
# Aide à identifier les problèmes et l'état du système

echo "🔍 Diagnostic Docker Listmonk - Mairies"
echo "======================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# 1. Vérifier Docker
echo ""
echo "1️⃣ DOCKER"
echo "----------"

if command -v docker &> /dev/null; then
    log_success "Docker installé : $(docker --version)"
    
    if docker ps &> /dev/null; then
        log_success "Docker accessible"
    else
        log_error "Docker non accessible (permissions?)"
    fi
else
    log_error "Docker non installé"
fi

# 2. Vérifier les conteneurs
echo ""
echo "2️⃣ CONTENEURS"
echo "-------------"

echo "Conteneurs en cours d'exécution :"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

echo ""
echo "Conteneurs Listmonk spécifiques :"
for container in "listmonk_mairies_app" "listmonk_mairies_db" "listmonk_mairies_redis"; do
    if docker ps | grep -q "$container"; then
        status=$(docker ps --filter "name=$container" --format "{{.Status}}")
        log_success "$container : $status"
    else
        log_error "$container : Non trouvé ou arrêté"
    fi
done

# 3. Vérifier la santé des conteneurs
echo ""
echo "3️⃣ SANTÉ DES CONTENEURS"
echo "-----------------------"

for container in "listmonk_mairies_app" "listmonk_mairies_db" "listmonk_mairies_redis"; do
    if docker ps | grep -q "$container"; then
        health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
        case $health in
            "healthy")
                log_success "$container : Healthy"
                ;;
            "unhealthy")
                log_error "$container : Unhealthy"
                echo "   Derniers logs :"
                docker logs --tail 5 "$container" | sed 's/^/   /'
                ;;
            "starting")
                log_warning "$container : Starting"
                ;;
            "no-healthcheck")
                log_info "$container : Pas de healthcheck configuré"
                ;;
        esac
    fi
done

# 4. Vérifier la connectivité réseau
echo ""
echo "4️⃣ CONNECTIVITÉ"
echo "---------------"

# Test de l'interface web
if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
    log_success "Interface web accessible (port 9000)"
else
    log_error "Interface web non accessible (port 9000)"
fi

if curl -s http://localhost:12000/api/health > /dev/null 2>&1; then
    log_success "Interface backup accessible (port 12000)"
else
    log_warning "Interface backup non accessible (port 12000)"
fi

# 5. Vérifier les volumes et fichiers
echo ""
echo "5️⃣ VOLUMES ET FICHIERS"
echo "----------------------"

echo "Fichiers locaux :"
for file in "mairielist.csv" "mairielist-converted.csv" "docker-compose.yml"; do
    if [ -f "$file" ]; then
        size=$(du -h "$file" | cut -f1)
        log_success "$file : $size"
    else
        log_warning "$file : Non trouvé"
    fi
done

echo ""
echo "Scripts disponibles :"
for script in "docker-integration-mairies.sh" "scripts/fix-and-convert-csv.py"; do
    if [ -f "$script" ]; then
        log_success "$script : Disponible"
    else
        log_error "$script : Manquant"
    fi
done

# 6. Vérifier la base de données
echo ""
echo "6️⃣ BASE DE DONNÉES"
echo "------------------"

if docker ps | grep -q "listmonk_mairies_db"; then
    # Test de connexion à la DB
    if docker exec listmonk_mairies_db pg_isready -U listmonk > /dev/null 2>&1; then
        log_success "PostgreSQL accessible"
        
        # Compter les abonnés
        subscriber_count=$(docker exec listmonk_mairies_db psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
        if [ "$subscriber_count" ]; then
            log_success "Abonnés dans la DB : $subscriber_count"
        else
            log_warning "Impossible de compter les abonnés"
        fi
        
        # Vérifier les tables géographiques
        geo_tables=$(docker exec listmonk_mairies_db psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'french_%';" 2>/dev/null | tr -d ' ')
        if [ "$geo_tables" ] && [ "$geo_tables" -gt 0 ]; then
            log_success "Tables géographiques : $geo_tables trouvées"
        else
            log_warning "Tables géographiques non trouvées"
        fi
        
    else
        log_error "PostgreSQL non accessible"
    fi
else
    log_error "Conteneur de base de données non trouvé"
fi

# 7. Vérifier les logs récents
echo ""
echo "7️⃣ LOGS RÉCENTS"
echo "---------------"

if docker ps | grep -q "listmonk_mairies_app"; then
    echo "Derniers logs de l'application :"
    docker logs --tail 10 listmonk_mairies_app | sed 's/^/   /'
else
    log_error "Conteneur application non trouvé"
fi

# 8. Informations système
echo ""
echo "8️⃣ SYSTÈME"
echo "----------"

echo "Utilisation disque :"
df -h . | sed 's/^/   /'

echo ""
echo "Mémoire disponible :"
free -h | sed 's/^/   /'

echo ""
echo "Charge système :"
uptime | sed 's/^/   /'

# 9. Recommandations
echo ""
echo "9️⃣ RECOMMANDATIONS"
echo "------------------"

# Vérifier si l'intégration est nécessaire
if docker ps | grep -q "listmonk_mairies_app"; then
    if curl -s http://localhost:9000/api/health > /dev/null 2>&1; then
        subscriber_count=$(docker exec listmonk_mairies_db psql -U listmonk -d listmonk -t -c "SELECT COUNT(*) FROM subscribers;" 2>/dev/null | tr -d ' ')
        if [ "$subscriber_count" ] && [ "$subscriber_count" -gt 1000 ]; then
            log_success "Système opérationnel avec $subscriber_count abonnés"
            echo "   → Accédez à http://localhost:9000 pour utiliser Listmonk"
        else
            log_info "Système prêt pour l'intégration des mairies"
            echo "   → Exécutez : ./docker-integration-mairies.sh"
        fi
    else
        log_warning "Listmonk ne répond pas"
        echo "   → Vérifiez les logs : docker logs listmonk_mairies_app"
        echo "   → Redémarrez si nécessaire : docker restart listmonk_mairies_app"
    fi
else
    log_error "Conteneur Listmonk non trouvé"
    echo "   → Démarrez vos conteneurs : docker-compose up -d"
fi

echo ""
echo "🔧 COMMANDES UTILES"
echo "-------------------"
echo "Redémarrer Listmonk    : docker restart listmonk_mairies_app"
echo "Voir les logs          : docker logs -f listmonk_mairies_app"
echo "Accéder au conteneur   : docker exec -it listmonk_mairies_app /bin/sh"
echo "Sauvegarder la DB      : docker exec listmonk_mairies_db pg_dump -U listmonk listmonk > backup.sql"
echo "Intégrer les mairies   : ./docker-integration-mairies.sh"

echo ""
echo "✅ Diagnostic terminé"