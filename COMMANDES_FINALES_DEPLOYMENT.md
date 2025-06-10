# Commandes Finales pour Déploiement et Tests

## 🎯 Statut du Projet

✅ **INTÉGRATION COMPLÈTE TERMINÉE**
- Données mairielist.csv intégrées (36,446 communes valides)
- Système de ciblage géographique fonctionnel
- Gestion des contacts mairie par département/population
- Mailings ciblés par critères géographiques
- Toutes les erreurs de compilation corrigées
- Build Go réussi ✅

## 📋 Récupération de la Dernière Version

```bash
# 1. Récupérer la dernière version du dépôt
git fetch origin
git checkout feature/french-municipalities-targeting
git pull origin feature/french-municipalities-targeting

# 2. Vérifier que vous êtes sur la bonne branche
git branch
git log --oneline -5
```

## 🐳 Mise à Jour et Démarrage des Conteneurs

```bash
# 1. Arrêter les conteneurs existants
docker-compose -f docker-compose.mairies.yml down

# 2. Reconstruire les images avec les dernières modifications
docker-compose -f docker-compose.mairies.yml build --no-cache

# 3. Démarrer les services
docker-compose -f docker-compose.mairies.yml up -d

# 4. Vérifier que les services sont démarrés
docker-compose -f docker-compose.mairies.yml ps
docker-compose -f docker-compose.mairies.yml logs -f listmonk
```

## 🗄️ Initialisation de la Base de Données

```bash
# 1. Attendre que PostgreSQL soit prêt
docker-compose -f docker-compose.mairies.yml exec postgres pg_isready

# 2. Exécuter les migrations
docker-compose -f docker-compose.mairies.yml exec listmonk ./listmonk --install

# 3. Appliquer la migration géographique
docker-compose -f docker-compose.mairies.yml exec postgres psql -U listmonk -d listmonk -f /docker-entrypoint-initdb.d/v5.1.0_geo_tables.sql

# 4. Importer les données des mairies
docker-compose -f docker-compose.mairies.yml exec listmonk ./scripts/import-mairies.sh
```

## 🧪 Tests de Validation

```bash
# 1. Tester la compilation Go
docker-compose -f docker-compose.mairies.yml exec listmonk go build -o /tmp/test ./cmd

# 2. Exécuter les tests de validation
docker-compose -f docker-compose.mairies.yml exec listmonk ./scripts/validate-integration.sh

# 3. Vérifier les données importées
docker-compose -f docker-compose.mairies.yml exec postgres psql -U listmonk -d listmonk -c "
SELECT 
    (SELECT COUNT(*) FROM french_departments) as departments,
    (SELECT COUNT(*) FROM french_communes) as communes,
    (SELECT COUNT(*) FROM french_communes WHERE population > 0) as communes_with_population;
"
```

## 🌐 Accès à l'Application

```bash
# L'application sera accessible sur :
echo "Application disponible sur :"
echo "- Interface Admin: http://localhost:9000"
echo "- API: http://localhost:9000/api"
echo "- Endpoints géographiques: http://localhost:9000/api/geo/*"
```

## 🎯 Nouvelles Fonctionnalités Disponibles

### 1. Ciblage Géographique
```bash
# Tester l'API de ciblage
curl -X POST http://localhost:9000/api/geo/targeting/preview \
  -H "Content-Type: application/json" \
  -d '{
    "departments": ["75", "92"],
    "population_min": 10000,
    "population_max": 100000
  }'
```

### 2. Statistiques Géographiques
```bash
# Obtenir les statistiques par département
curl http://localhost:9000/api/geo/targeting/departments

# Obtenir les statistiques par tranche de population
curl http://localhost:9000/api/geo/targeting/population-ranges
```

### 3. Recherche de Communes
```bash
# Rechercher des communes
curl "http://localhost:9000/api/geo/communes/search?q=Paris&limit=10"
```

## 🔧 Dépannage

### Si les conteneurs ne démarrent pas :
```bash
# Vérifier les logs
docker-compose -f docker-compose.mairies.yml logs

# Nettoyer et redémarrer
docker-compose -f docker-compose.mairies.yml down -v
docker system prune -f
docker-compose -f docker-compose.mairies.yml up -d
```

### Si la base de données n'est pas initialisée :
```bash
# Réinitialiser la base de données
docker-compose -f docker-compose.mairies.yml exec postgres psql -U listmonk -c "DROP DATABASE IF EXISTS listmonk;"
docker-compose -f docker-compose.mairies.yml exec postgres psql -U listmonk -c "CREATE DATABASE listmonk;"
docker-compose -f docker-compose.mairies.yml restart listmonk
```

### Si l'import des données échoue :
```bash
# Vérifier le fichier CSV
docker-compose -f docker-compose.mairies.yml exec listmonk ls -la /app/mairielist_processed.csv

# Réexécuter l'import
docker-compose -f docker-compose.mairies.yml exec listmonk ./scripts/import-mairies.sh
```

## 📊 Validation Finale

```bash
# Script de validation complète
docker-compose -f docker-compose.mairies.yml exec listmonk bash -c "
echo '=== VALIDATION FINALE ==='
echo '1. Test de compilation...'
go build -o /tmp/test ./cmd && echo '✅ Compilation OK' || echo '❌ Erreur compilation'

echo '2. Test base de données...'
./scripts/validate-integration.sh

echo '3. Test API géographique...'
curl -s http://localhost:9000/api/geo/stats | jq . && echo '✅ API OK' || echo '❌ API erreur'

echo '4. Résumé des données:'
psql -U listmonk -d listmonk -c \"
SELECT 
    'Départements' as type, COUNT(*) as count FROM french_departments
UNION ALL
SELECT 
    'Communes' as type, COUNT(*) as count FROM french_communes
UNION ALL
SELECT 
    'Communes avec population' as type, COUNT(*) as count FROM french_communes WHERE population > 0;
\"
"
```

## 🚀 Prêt pour les Tests !

Votre environnement est maintenant configuré avec :

✅ **Données intégrées** : 36,446 communes françaises avec données démographiques
✅ **API de ciblage** : Endpoints pour ciblage par département/population  
✅ **Gestion des contacts** : Système de gestion des contacts mairie
✅ **Mailings ciblés** : Création de campagnes avec ciblage géographique
✅ **Interface complète** : Toutes les fonctionnalités accessibles via API
✅ **Build fonctionnel** : Code Go compilé sans erreurs

**Commencez vos tests avec les commandes ci-dessus !** 🎉