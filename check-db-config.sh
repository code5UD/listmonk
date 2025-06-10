#!/bin/bash

echo "🔍 Vérification de la configuration de la base de données"
echo "========================================================"

echo "1. Vérification des conteneurs..."
docker ps | grep -E "(listmonk|postgres|db)"

echo ""
echo "2. Variables d'environnement du conteneur DB..."
docker exec listmonk_mairies_db env | grep -E "(POSTGRES|DB)"

echo ""
echo "3. Vérification des utilisateurs PostgreSQL..."
docker exec listmonk_mairies_db psql -U postgres -c "\du" 2>/dev/null || \
docker exec listmonk_mairies_db psql -c "\du" 2>/dev/null || \
echo "Impossible de se connecter avec postgres"

echo ""
echo "4. Test de connexion avec différents utilisateurs..."
echo "Test avec postgres:"
docker exec listmonk_mairies_db psql -U postgres -c "SELECT version();" 2>/dev/null || echo "Échec"

echo "Test sans utilisateur spécifique:"
docker exec listmonk_mairies_db psql -c "SELECT version();" 2>/dev/null || echo "Échec"

echo "Test avec listmonk:"
docker exec listmonk_mairies_db psql -U listmonk -c "SELECT version();" 2>/dev/null || echo "Échec"

echo ""
echo "5. Vérification des bases de données..."
docker exec listmonk_mairies_db psql -c "\l" 2>/dev/null || \
docker exec listmonk_mairies_db psql -U postgres -c "\l" 2>/dev/null || \
echo "Impossible de lister les bases de données"

echo ""
echo "6. Configuration Listmonk..."
docker exec listmonk_mairies_app cat /listmonk/config.toml | grep -A10 -B5 "\[db\]" || echo "Config non accessible"