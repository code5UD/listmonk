#!/bin/bash

# Script pour corriger l'extraction des données géographiques

echo "🔧 Correction de l'extraction des données géographiques"
echo "======================================================="

# Configuration
DB_CONTAINER="listmonk_mairies_db"
DB_USER="listmonk_mairies"
DB_NAME="listmonk_mairies"

echo "1. Vérification des attributs des abonnés..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
    COUNT(*) as total_subscribers,
    COUNT(CASE WHEN attribs IS NOT NULL THEN 1 END) as with_attribs,
    COUNT(CASE WHEN attribs->>'code_departement' IS NOT NULL THEN 1 END) as with_dept_in_attribs
FROM subscribers;
"

echo ""
echo "2. Exemple d'attributs d'un abonné..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT email, attribs FROM subscribers WHERE attribs IS NOT NULL LIMIT 3;
"

echo ""
echo "3. Vérification des clés dans les attributs..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT DISTINCT jsonb_object_keys(attribs) as attribute_keys 
FROM subscribers 
WHERE attribs IS NOT NULL 
LIMIT 10;
"

echo ""
echo "4. Correction de l'extraction des données géographiques..."

# Script SQL corrigé pour l'extraction
cat > /tmp/fix_geo_extraction.sql << 'EOF'
-- Vérifier d'abord la structure des attributs
SELECT 'Vérification des attributs' as step;

-- Afficher quelques exemples d'attributs
SELECT email, attribs FROM subscribers WHERE attribs IS NOT NULL LIMIT 3;

-- Lister toutes les clés disponibles dans les attributs
SELECT DISTINCT jsonb_object_keys(attribs) as keys 
FROM subscribers 
WHERE attribs IS NOT NULL;

-- Mise à jour corrigée des données géographiques
UPDATE subscribers 
SET 
    -- Essayer différentes variantes de noms de clés
    department_code = CASE 
        WHEN attribs->>'code_departement' IS NOT NULL THEN LPAD(attribs->>'code_departement', 2, '0')
        WHEN attribs->>'departement_numero' IS NOT NULL THEN LPAD(attribs->>'departement_numero', 2, '0')
        WHEN attribs->>'departement' IS NOT NULL THEN LPAD(attribs->>'departement', 2, '0')
        WHEN attribs->>'dept' IS NOT NULL THEN LPAD(attribs->>'dept', 2, '0')
        ELSE NULL
    END,
    
    population = CASE 
        WHEN attribs->>'population' IS NOT NULL THEN (attribs->>'population')::INTEGER
        WHEN attribs->>'population_commune' IS NOT NULL THEN (attribs->>'population_commune')::INTEGER
        WHEN attribs->>'pop' IS NOT NULL THEN (attribs->>'pop')::INTEGER
        ELSE 0
    END,
    
    commune_code = CASE
        WHEN attribs->>'code_insee' IS NOT NULL THEN attribs->>'code_insee'
        WHEN attribs->>'insee' IS NOT NULL THEN attribs->>'insee'
        ELSE NULL
    END
WHERE attribs IS NOT NULL;

-- Afficher les résultats de la mise à jour
SELECT 
    COUNT(*) as total_subscribers,
    COUNT(department_code) as with_department,
    COUNT(CASE WHEN population > 0 THEN 1 END) as with_population,
    COUNT(commune_code) as with_commune_code
FROM subscribers;

-- Afficher quelques exemples de données mises à jour
SELECT email, department_code, population, commune_code, attribs->>'nom_commune' as commune_name
FROM subscribers 
WHERE department_code IS NOT NULL 
LIMIT 5;
EOF

docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" < /tmp/fix_geo_extraction.sql

echo ""
echo "5. Vérification finale..."
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
    'Statistiques finales' as info,
    COUNT(*) as total,
    COUNT(department_code) as with_dept,
    COUNT(CASE WHEN population > 0 THEN 1 END) as with_pop
FROM subscribers;
"

rm -f /tmp/fix_geo_extraction.sql

echo ""
echo "✅ Correction terminée !"