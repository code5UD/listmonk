#!/bin/bash

# Script pour récupérer la dernière version du dépôt et mettre à jour les conteneurs
# Usage: ./update-and-test.sh [branch]

set -e

BRANCH="${1:-main}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Mise à jour et test du projet Listmonk Mairies ==="
echo "Branche: $BRANCH"
echo "Répertoire du projet: $PROJECT_DIR"
echo

cd "$PROJECT_DIR"

echo "1. Sauvegarde des fichiers locaux importants..."
if [ -f "mairielist.csv" ]; then
    cp mairielist.csv mairielist.csv.backup
    echo "Fichier mairielist.csv sauvegardé"
fi

if [ -f "mairielist-converted.csv" ]; then
    cp mairielist-converted.csv mairielist-converted.csv.backup
    echo "Fichier mairielist-converted.csv sauvegardé"
fi

echo
echo "2. Récupération de la dernière version du dépôt..."
git fetch origin
git checkout "$BRANCH"
git pull origin "$BRANCH"

echo
echo "3. Restauration des fichiers locaux..."
if [ -f "mairielist.csv.backup" ]; then
    mv mairielist.csv.backup mairielist.csv
    echo "Fichier mairielist.csv restauré"
fi

if [ -f "mairielist-converted.csv.backup" ]; then
    mv mairielist-converted.csv.backup mairielist-converted.csv
    echo "Fichier mairielist-converted.csv restauré"
fi

echo
echo "4. Arrêt des conteneurs existants..."
docker-compose -f docker-compose.mairies.yml down || true

echo
echo "5. Suppression des images obsolètes..."
docker-compose -f docker-compose.mairies.yml down --rmi local || true

echo
echo "6. Construction des nouvelles images..."
docker-compose -f docker-compose.mairies.yml build --no-cache

echo
echo "7. Démarrage des services..."
docker-compose -f docker-compose.mairies.yml up -d

echo
echo "8. Attente du démarrage complet..."
sleep 30

echo
echo "9. Vérification de l'état des services..."
docker-compose -f docker-compose.mairies.yml ps

echo
echo "10. Test de connectivité de l'API..."
echo "Test de l'endpoint de santé..."
curl -f http://localhost:9000/api/health || echo "Endpoint de santé non disponible"

echo
echo "Test des endpoints géographiques..."
curl -f http://localhost:9000/api/geo/departments || echo "Endpoint départements non disponible"

echo
echo "11. Affichage des logs récents..."
echo "=== Logs de l'application ==="
docker-compose -f docker-compose.mairies.yml logs --tail=20 app

echo
echo "=== Logs de la base de données ==="
docker-compose -f docker-compose.mairies.yml logs --tail=10 db

echo
echo "=== Mise à jour terminée ==="
echo
echo "Services disponibles:"
echo "- Application: http://localhost:9000"
echo "- Adminer: http://localhost:8080"
echo "- Redis Commander: http://localhost:8081"
echo
echo "Commandes utiles:"
echo "- Voir tous les logs: docker-compose -f docker-compose.mairies.yml logs -f"
echo "- Redémarrer l'app: docker-compose -f docker-compose.mairies.yml restart app"
echo "- Arrêter tous les services: docker-compose -f docker-compose.mairies.yml down"
echo "- Voir l'état des services: docker-compose -f docker-compose.mairies.yml ps"
echo
echo "Tests manuels recommandés:"
echo "1. Connexion à l'interface web: http://localhost:9000"
echo "2. Test de l'import CSV via l'interface"
echo "3. Test du ciblage géographique"
echo "4. Vérification des statistiques par département"
echo
echo "API Endpoints à tester:"
echo "- GET http://localhost:9000/api/geo/departments"
echo "- GET http://localhost:9000/api/geo/communes?department_codes=75"
echo "- POST http://localhost:9000/api/geo/targeting/preview"
echo "- GET http://localhost:9000/api/geo/targeting/stats"