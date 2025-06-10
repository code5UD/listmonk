#!/bin/bash

# Script de déploiement complet pour les fonctionnalités mairies
# Usage: ./deploy-mairies.sh [environment]

set -e

ENVIRONMENT="${1:-development}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Déploiement des fonctionnalités mairies ==="
echo "Environnement: $ENVIRONMENT"
echo "Répertoire du projet: $PROJECT_DIR"
echo

# Configuration selon l'environnement
case $ENVIRONMENT in
    "development")
        DB_CONN="postgres://listmonk_mairies:secure_password@localhost:5432/listmonk_mairies?sslmode=disable"
        COMPOSE_FILE="docker-compose.mairies.yml"
        ;;
    "production")
        DB_CONN="${DATABASE_URL:-postgres://listmonk_mairies:secure_password@db:5432/listmonk_mairies?sslmode=disable}"
        COMPOSE_FILE="docker-compose.mairies.yml"
        ;;
    *)
        echo "Environnement non supporté: $ENVIRONMENT"
        echo "Environnements supportés: development, production"
        exit 1
        ;;
esac

echo "1. Arrêt des services existants..."
cd "$PROJECT_DIR"
docker-compose -f "$COMPOSE_FILE" down || true

echo
echo "2. Construction des images Docker..."
docker-compose -f "$COMPOSE_FILE" build

echo
echo "3. Démarrage des services de base de données..."
docker-compose -f "$COMPOSE_FILE" up -d db redis

echo
echo "4. Attente de la disponibilité de la base de données..."
sleep 10

echo
echo "5. Application des migrations..."
docker-compose -f "$COMPOSE_FILE" run --rm app ./listmonk --install --yes || true

echo
echo "6. Application des corrections de ciblage..."
docker-compose -f "$COMPOSE_FILE" exec -T db psql -U listmonk_mairies -d listmonk_mairies < "$SCRIPT_DIR/fix-targeting.sql"

echo
echo "7. Conversion du fichier CSV des mairies..."
if [ -f "$PROJECT_DIR/mairielist.csv" ]; then
    python3 "$SCRIPT_DIR/convert-mairielist-csv.py" "$PROJECT_DIR/mairielist.csv" "$PROJECT_DIR/mairielist-converted.csv"
    echo "Fichier CSV converti avec succès"
else
    echo "Attention: fichier mairielist.csv non trouvé, l'import sera ignoré"
fi

echo
echo "8. Démarrage de l'application..."
docker-compose -f "$COMPOSE_FILE" up -d app

echo
echo "9. Attente du démarrage de l'application..."
sleep 15

echo
echo "10. Import des données de mairies..."
if [ -f "$PROJECT_DIR/mairielist-converted.csv" ]; then
    cd "$SCRIPT_DIR"
    go mod tidy
    go run import-mairies.go "$PROJECT_DIR/mairielist-converted.csv" "$DB_CONN" || echo "Erreur lors de l'import, mais on continue..."
else
    echo "Fichier CSV converti non trouvé, import ignoré"
fi

echo
echo "11. Rafraîchissement des statistiques..."
docker-compose -f "$COMPOSE_FILE" exec -T db psql -U listmonk_mairies -d listmonk_mairies -c "SELECT refresh_targeting_stats();" || true

echo
echo "12. Vérification du déploiement..."
docker-compose -f "$COMPOSE_FILE" ps

echo
echo "=== Déploiement terminé ==="
echo
echo "Services disponibles:"
echo "- Application: http://localhost:9000"
if [ "$ENVIRONMENT" = "development" ]; then
    echo "- Adminer: http://localhost:8080"
    echo "- Redis Commander: http://localhost:8081"
fi
echo
echo "API Endpoints géographiques:"
echo "- GET /api/geo/departments - Liste des départements"
echo "- GET /api/geo/communes - Liste des communes avec filtres"
echo "- POST /api/geo/targeting/preview - Prévisualisation de ciblage"
echo "- POST /api/geo/targeting/count - Comptage de destinataires"
echo "- GET /api/geo/targeting/stats - Statistiques de ciblage"
echo
echo "Pour voir les logs:"
echo "docker-compose -f $COMPOSE_FILE logs -f"
echo
echo "Pour arrêter les services:"
echo "docker-compose -f $COMPOSE_FILE down"